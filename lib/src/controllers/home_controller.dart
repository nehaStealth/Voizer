import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:agora_calling_app/src/repositories/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:agora_calling_app/src/services/auth_service.dart';
import 'package:agora_calling_app/src/repositories/session_repository.dart' as repository;
import 'package:package_info_plus/package_info_plus.dart';

import '../helpers/global.dart';

class HomeController extends ControllerMVC{
  bool isOnHomePage = false;
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  String userName = '';
  String hostName = '';
  bool isHostJoined = false;
  bool isUserActive = true;
  Timer? checkHostJoinedInfoTimer;

  // Future<bool> getHostJoinedData() async {
  //   isHostJoined = await repository.getHostJoinedInfo();
  //   getUserInfo();
  //   setState(() {});
  //
  //   return isHostJoined;
  // }


  // Future<bool> getHostJoinedData() async {
  //   //isHostJoined = await repository.getHostJoinedInfo();
  //   isHostJoined = true;
  //   print("getHostJoinedData → $isHostJoined"); // Debug log
  //   getUserInfo();
  //   setState(() {});
  //   return isHostJoined;
  // }


  Future<bool> getHostJoinedData() async {
    //var response = await repository.getHostJoinedInfo();
    bool joined = await repository.getHostJoinedInfo();
    print("Host joined: $joined");

    // API can return 0/1 or true/false
    isHostJoined = joined;
    print("getHostJoinedDataaaaa → $isHostJoined");

    getUserInfo();
    setState(() {});

    return isHostJoined;
  }

  Future<bool> checkUserStatus() async {
    isUserActive = await checkStatus();
    if(!isUserActive) {
      logOut();
    }
    setState(() {});

    return isUserActive;
  }

  getUserInfo() async {
    userName = await getUserName();
    hostName = await getHostName();
    setState(() {});
  }

  String appVersion = '';
  String appURL = '';

  Future getAppInfo() async {
    Response response = await getAppVersionInfo();

    Map<String, dynamic> mapResponse = json.decode(response.body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      if(mapResponse['success'] ?? false) {
        setState(() {
          appVersion = mapResponse['data']['version'];
          appURL = mapResponse['data']['apk'];


          print("Latest App Version from API: $appVersion");
          print("Download URL: $appURL");
        });
      }
    }
  }

  Future<bool> checkAppVersion(context) async {
    await getAppInfo();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String version = packageInfo.version;

    print("Installed App Version: $version");
    print("Latest App Version from API: $appVersion");

    return version == appVersion;
  }


  Future<Map<String, dynamic>?> fetchLiveKitToken(String roomId) async {
    try {
      String accessToken = await getToken();
      final url = Uri.parse(fetchLivekitTokenURL);
      // Build the request body

      Map<String, dynamic> body = {
        'room_id': roomId, // convert to string if required by API
      };

      final response = await http.post(
        url,
        headers: {
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.contentTypeHeader: 'application/json',
          // Include authorization if your API requires it:
          HttpHeaders.authorizationHeader: 'Bearer $accessToken',
        },
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['token'] != null) {
          print("LiveKit token fetched: ${data['token']}");
          return data; // full response including token, room_id, user
        } else {
          print("Failed to fetch token: ${data['message']}");
          return null;
        }
      } else {
        print("HTTP error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("Exception while fetching token: $e");
      return null;
    }
  }



  //fetch livekit roomId api implementation
  Future<String?> fetchUserDataAndSaveRoomId(int userId) async {
    String accessToken = await getToken();
    print("Save token : $accessToken");

    try {
      final url = Uri.parse("$getRoomIdURL$userId");

      final response = await http.get(
        url,
        headers: {
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final livekitRoomId = data['data']['livekit_room_id']?.toString();
          final service = data['data']['service']?.toString();
          final loginId = data['data']['login_id']?.toString();
          final livekitURL = data['data']['livekit_host']?.toString();

          if (livekitRoomId != null && livekitRoomId.isNotEmpty) {
            await saveLiveKitRoomId(livekitRoomId);
            await saveLiveKitURL(livekitURL!);
            if (service != null && service.isNotEmpty) {
              await saveService(service);
            }

            if (loginId != null && loginId.isNotEmpty) {
              await saveUserName(loginId);
            }

            // ✅ Now read back from SharedPreferences to confirm
            final savedRoomId = await getLiveKitRoomId();

            print("Saved livekit_room_id: $savedRoomId");
            print("Saved service: $service");

            return savedRoomId;
          } else {
            print("livekit_room_id not found in response");
            return null;
          }
        } else {
          print("API failed: ${data['message']}");
          return null;
        }
      } else {
        print("HTTP error: ${response.statusCode}, body: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception while fetching user data: $e");
      return null;
    }
  }



  //Fetch App Setting api
  Future<bool> fetchAppSettings() async {
    try {
      final response = await http.get(
        Uri.parse(settingsUrl),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json",
        },
      );

      // 🔹 Print API logs
      print('--------------------------------------------------------------------------------');
      print("Status Code: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print('--------------------------------------------------------------------------------');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          await saveAppStatus(data["app_status"] ?? "");
          await saveStatusText(data["status_text"] ?? "");
          await saveHostLogoPath(data["hostlogopath"] ?? "");
          await saveHostSplashPath(data["hostsplashscreenpath"] ?? "");
          await saveClientLogoPath(data["clientlogopath"] ?? "");
          await saveClientSplashPath(data["clientsplashscreenpath"] ?? "");
          await saveService(data["service"] ?? "");

          return true; // ✅ Success
        }
      }
      return false; // ❌ API failed
    } catch (e) {
      debugPrint("Error fetching app settings: $e");
      return false;
    }
  }

}