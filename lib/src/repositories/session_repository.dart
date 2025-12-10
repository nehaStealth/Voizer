import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:agora_calling_app/src/helpers/global.dart';
import 'package:agora_calling_app/src/services/auth_service.dart';

Future<String> generateRoomToken() async {
  String accessToken = await getToken();
  Response response = await http.get(
    Uri.parse('$GenerateRoomTokenURL?app_version=1'),
    headers: {
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer $accessToken',
    },
  );

  print('SESSION 1--------------------------------------------------------------------------------');
  print(response.statusCode);
  print(response.body);
  print('SESSION 2--------------------------------------------------------------------------------');
  if (response.statusCode == 200) {
    Map<String, dynamic> mapResponse = json.decode(response.body);
    int hostId = mapResponse['data']['host']['id'];
    String channelName = mapResponse['data']['host']['channel'];
    String appId = mapResponse['data']['host']['agora_app_id'];
    String userName = '${mapResponse['data']['name']}';

    print("✅ hostId : $hostId");
    print("✅ Channel ID : $channelName");
    print("✅ appId : $appId");
    print("✅ userName : $userName");

    await saveHostId(hostId);
    await saveUserName(userName);
    await saveChannelName(channelName);
    await saveAppId(appId);
    return mapResponse['token'];
  }
  return '';
}


Future<bool> getHostJoinedInfo() async {
  String accessToken = await getToken();

  Response response = await http.get(
    Uri.parse(GetHostJoinedURL),
    headers: {
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer $accessToken',
    },
  );

  print('--------------------------------------------------------------------------------');
  print(response.statusCode);
  print(response.body);
  print('--------------------------------------------------------------------------------');

  if (response.statusCode >= 400) {
    return false;
  }

  Map<String, dynamic> mapResponse = json.decode(response.body);

  // Save user name
  String userName = '${mapResponse['data']['name']}';
  await saveUserName(userName);

  // ✅ SAVE USER_HOST DETAILS (not host)
  if (mapResponse['data']['user_host'] != null) {
    var userHost = mapResponse['data']['user_host'];
    var hostLoginId = mapResponse['data']['user_host']['login_id'];
    await saveHostId(userHost['id']);          // host ID
    await saveHostName(userHost['name']);      // host name
    await saveHostLoginId(hostLoginId);      // host user name

  }

  // ✅ GET is_host_joined FROM user_host
  var hostJoined;

  if (mapResponse['data']['user_host'] != null) {
    hostJoined = mapResponse['data']['user_host']['is_host_joined'];
  } else {
    hostJoined = 0; // default if user_host is missing
  }

  // Convert 0 / 1 / "0" / "1" to bool
  if (hostJoined is int) {
    return hostJoined == 1;
  } else if (hostJoined is String) {
    return hostJoined == "1";
  } else if (hostJoined is bool) {
    return hostJoined;
  }

  return false;
}


// Future<bool> getHostJoinedInfo() async {
//   String accessToken = await getToken();
//   Response response = await http.get(
//     Uri.parse(GetHostJoinedURL),
//     headers: {
//       HttpHeaders.acceptHeader: 'application/json',
//       HttpHeaders.contentTypeHeader: 'application/json',
//       HttpHeaders.authorizationHeader: 'Bearer $accessToken',
//     },
//   );
//
//   print('--------------------------------------------------------------------------------');
//   print(response.statusCode);
//   print(response.body);
//   print('--------------------------------------------------------------------------------');
//   if (response.statusCode >= 400) {
//     return false;
//   }
//
//   Map<String, dynamic> mapResponse = json.decode(response.body);
//   String userName = '${mapResponse['data']['name']}';
//
//   if(mapResponse['data']['host'] != null) {
//     await saveHostId(mapResponse['data']['host']['id']);
//     await saveHostName(mapResponse['data']['host']['name']);
//   }
//   await saveUserName(userName);
//   return mapResponse['success'];
// }

Future<String> getUserName(int userId) async {
  String accessToken = await getToken();
  Response response = await http.get(
    Uri.parse('$GetUserDataURL/$userId'),
    headers: {
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer $accessToken',
    },
  );

  print('--------------------------------------------------------------------------------');
  print(response.statusCode);
  print(response.body);
  print('--------------------------------------------------------------------------------');
  if (response.statusCode == 200) {
    Map<String, dynamic> mapResponse = json.decode(response.body);
    String userName = '${mapResponse['data']['name']}';
    return userName;
  }
  return '';
}

Future<http.Response> uploadUserRecording(String recordingFilePath, String recordingFileName) async {
  print('Recording FilePATH: ${recordingFilePath}');
  print('Recording FileNAME: ${recordingFileName}');
  String accessToken = await getToken();
  int userId = await getUserId();
  print('userid: ${userId}');

  Map<String, String> map = {};
  map['recording_name'] = recordingFileName;

  final request = http.MultipartRequest("POST", Uri.parse('$UploadUserRecordingURL/$userId'));
  request.files.add(await http.MultipartFile.fromPath('recording', File(recordingFilePath).path));
  request.headers.addAll({
    HttpHeaders.acceptHeader: 'application/json',
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.authorizationHeader: 'Bearer $accessToken', 
  });

  request.fields.addAll(map);
  var response = await request.send();
  final res = await http.Response.fromStream(response);
  // Print response for debugging
  print('----------------------------------------------');
  print('Status code: ${res.statusCode}');
  print('Response body: ${res.body}');
  print('----------------------------------------------');
  print('````````````````````````````````````````````````````````````````````````````````````````````````````````````````````');
  print(res.statusCode);
  print(res.body);
  print('````````````````````````````````````````````````````````````````````````````````````````````````````````````````````');
  Directory(recordingFilePath).deleteSync(recursive: true);
  return res;
}