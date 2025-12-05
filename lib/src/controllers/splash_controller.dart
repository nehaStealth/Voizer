import 'dart:convert';
import 'package:agora_calling_app/src/helpers/texts.dart';
import 'package:agora_calling_app/src/repositories/user_repository.dart';
import 'package:agora_calling_app/src/services/auth_service.dart';
import 'package:agora_calling_app/src/widget/custom_alert.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../helpers/global.dart';

class SplashController extends ControllerMVC{
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController animationController;
  late Animation<double> animation;

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

  init(context) async {
    bool loginStatus = await getLogin();
    await getAppInfo();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    // String version = packageInfo.version;
    String version = '1.0.5';
    print("splash App Version: $version");
    print("splash App Version from API: $appVersion");
    if(version == appVersion) {
      Future.delayed(const Duration(seconds: 3), () {
        if(loginStatus) {
          Navigator.pushNamed(context, '/Home');
        } else {
          Navigator.pushNamed(context, '/Login');
        }
      });
    } else {
      showMessageAlert(
        context: context,
        isDismissable: false,
        message: youUsingOldAppPleaseUpdateTxt,
        onClick: () async {
          if (!await launchUrl(Uri.parse(appURL))) {
            showMessageAlert(
              context: context,
              message: appURLNotLaunchingContactAdminTxt,
              onClick: () async {
                Navigator.pop(context);
              }
            );
          }
        },
      );
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