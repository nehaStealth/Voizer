import 'dart:convert';
import 'dart:io';
import 'package:agora_calling_app/src/Models/recording_details_model.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:agora_calling_app/src/helpers/global.dart';
import 'package:agora_calling_app/src/services/auth_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

Future<http.Response> login(name, password, deviceToken) async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();

  Map<String, dynamic> map = {};
  map['name'] = name;
  map['password'] = password;
  map['device_token'] = deviceToken;
  map['app_version'] = '1.0.5';
  // map['app_version'] = packageInfo.version;
  map['role'] = 2;

  Response response = await http.post(
    Uri.parse(LoginURL),
    headers: {
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.contentTypeHeader: 'application/json',
    },
    body: json.encode(map),
  );

  print('--------------------------------------------------------------------------------');
  print(response.statusCode);
  print(response.body);
  print("Login API Response:");
  print("Status Code: ${response.statusCode}");
  print("Response Body: ${response.body}");
  print('--------------------------------------------------------------------------------');
  return response;
}

Future<bool> updateLogOut() async {
  String accessToken = await getToken();
  Response response = await http.get(
    Uri.parse(LogOutURL),
    headers: {
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer $accessToken',
    },
  );

  print('--------------------------------------------------------------------------------');
  print(response.statusCode);
  print('Logout api : $response.body');
  print('--------------------------------------------------------------------------------');
  if (response.statusCode >= 400) {
    return false;
  }
  Map<String, dynamic> mapResponse = json.decode(response.body);
  return mapResponse['success'];
}

Future<bool> checkStatus() async {
  String accessToken = await getToken();
  Response response = await http.get(
    Uri.parse(CheckUserStatusURL),
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
  return mapResponse['success'];
}

Future<Response> getAppVersionInfo() async {
  Map<String, dynamic> map = {};
  map['type'] = 'user';

  Response response = await http.post(
    Uri.parse(GetAppVersionURL),
    headers: {
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.contentTypeHeader: 'application/json',
    },
    body: json.encode(map),
  );

  print('--------------------------------------------------------------------------------');
  print(response.statusCode);
  print(response.body);
  print('--------------------------------------------------------------------------------');
  return response;
}

Future<http.Response> changePassword(oldPassword, newPassword) async {
  String accessToken = await getToken();
  Map<String, dynamic> map = {};
  map['old_password'] = oldPassword;
  map['new_password'] = newPassword;

  Response response = await http.post(
    Uri.parse(ChangePasswordURL),
    headers: {
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer $accessToken',
    },
    body: json.encode(map),
  );

  print('--------------------------------------------------------------------------------');
  print(response.statusCode);
  print(response.body);
  print('--------------------------------------------------------------------------------');
  return response;
}

Future<http.Response> updateDeviceToken(deviceToken) async {

  String accessToken = await getToken();
  Map<String, dynamic> map = {};
  map['device_token'] = deviceToken;

  Response response = await http.post(
    Uri.parse(UpdateDeviceTokenURL),
    headers: {
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer $accessToken',
    },
    body: json.encode(map),
  );

  print('Update device token --------------------------------------------------------------------------------');
  print(response.statusCode);
  print(response.body);
  print('--------------------------------------------------------------------------------');
  return response;
}

Future<List<RecordingDetails>> getRecordings(int page) async {
  String accessToken = await getToken();
  Response response = await http.get(
    Uri.parse('$GetUserRecordingsURL?page=$page'),
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
    return json.decode(response.body)['data'].map<RecordingDetails>((json) => RecordingDetails.fromJson(json)).toList();
  }
  return [];
}