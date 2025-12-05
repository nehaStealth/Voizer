import 'package:agora_calling_app/src/repositories/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<bool> saveLogin(bool isLogin) async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return await preferences.setBool("login", isLogin);
}

Future<bool> getLogin() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return preferences.getBool("login") ?? false;
}

Future<bool> saveToken(String token) async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return await preferences.setString("token", token);
}

Future<String> getToken() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return preferences.getString("token") ?? "";
}

Future<bool> saveUserName(String name) async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return await preferences.setString("name", name);
}

Future<String> getUserName() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return preferences.getString("name") ?? "";
}

Future<bool> saveUserLoginIdName(String name) async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return await preferences.setString("userloginidname", name);
}

Future<String> getUserLoginIdName() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return preferences.getString("userloginidname") ?? "";
}

Future<bool> saveUserId(int userId) async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return await preferences.setInt("userid", userId);
}

Future<int> getUserId() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return preferences.getInt("userid") ?? 0;
}

Future<bool> saveHostId(int hostId) async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return await preferences.setInt("hostId", hostId);
}

Future<int> getHostId() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return preferences.getInt("hostId") ?? 0;
}

Future<bool> saveChannelName(String channelName) async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return await preferences.setString("channelName", channelName);
}

Future<String> getChannelName() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return preferences.getString("channelName") ?? '';
}

Future<bool> saveAppId(String appId) async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return await preferences.setString("appId", appId);
}

Future<String> getAppId() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return preferences.getString("appId") ?? '';
}

Future<bool> saveHostName(String hostName) async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return await preferences.setString("hostName", hostName);
}

Future<String> getHostName() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return preferences.getString("hostName") ?? '';
}


Future<bool> saveHostLoginId(String hostName) async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return await preferences.setString("hostLoginId", hostName);
}

Future<String> getHostLoginId() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return preferences.getString("hostLoginId") ?? '';
}


Future<bool> saveLiveKitRoomId(String name) async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return await preferences.setString("livekitRoomId", name);
}

Future<String> getSavedService() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return preferences.getString("service") ?? '';
}

Future<String> saveLiveKitURL(String url) async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  await preferences.setString("livekitURL", url);
  return url;
}

Future<String> getLiveKitURL() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return preferences.getString("livekitURL") ?? '';
}


Future<String> getLiveKitRoomId() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return preferences.getString("livekitRoomId") ?? '';
}

Future<bool> saveHostIdentity(String name) async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return await preferences.setString("hostIdentity", name);
}

Future<String> getHostIdentity() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return preferences.getString("hostIdentity") ?? '';
}

Future<void> saveAppStatus(String value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString("app_status", value);
}

Future<void> saveStatusText(String value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString("status_text", value);
}

Future<void> saveHostLogoPath(String value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString("hostlogopath", value);
}

Future<void> saveHostSplashPath(String value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString("hostsplashscreenpath", value);
}

Future<void> saveClientLogoPath(String value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString("clientlogopath", value);
}

Future<void> saveClientSplashPath(String value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString("clientsplashscreenpath", value);
}

Future<void> saveService(String value) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString("service", value);
}

Future<String> getAppStatus() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString("app_status") ?? '';
}

Future<String> getStatusText() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString("status_text") ?? '';
}

Future<String> getHostLogoPath() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString("hostlogopath") ?? '';
}

Future<String> getHostSplashPath() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString("hostsplashscreenpath") ?? '';
}

Future<String> getClientLogoPath() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString("clientlogopath") ?? '';
}

Future<String> getClientSplashPath() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString("clientsplashscreenpath") ?? '';
}

Future<String> getService() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString("service") ?? '';
}


Future<bool> logOut() async {
  await updateLogOut();

  SharedPreferences preferences = await SharedPreferences.getInstance();

  await preferences.clear(); // wipe everything

  // If you want to ensure some keys are forced removed
  await preferences.remove("token");
  await preferences.remove("name");
  await preferences.remove("userid");
  await preferences.remove("livekitRoomId");
  await preferences.remove("service");
  await preferences.remove("livekitURL");
  await preferences.remove("hostName");


  return true;
}