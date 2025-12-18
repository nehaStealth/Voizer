import 'dart:convert';
import 'package:agora_calling_app/src/helpers/texts.dart';
import 'package:agora_calling_app/src/views/home.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:agora_calling_app/src/widget/custom_alert.dart';
import 'package:agora_calling_app/src/services/auth_service.dart';
import 'package:agora_calling_app/src/repositories/user_repository.dart'
    as repository;
import 'package:url_launcher/url_launcher.dart';

class UserController extends ControllerMVC {
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  TextEditingController userNameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController oldPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmNewPasswordController = TextEditingController();

  bool passwordVisible = true;
  FocusNode userNameFocusNode = FocusNode();
  FocusNode passwordFocusNode = FocusNode();
  FocusNode oldPasswordFocusNode = FocusNode();
  FocusNode newPasswordFocusNode = FocusNode();
  FocusNode confirmNewPasswordFocusNode = FocusNode();

  void login(context) async {
    showLoadingAlert(context: context);
    final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
    String? deviceToken = await firebaseMessaging.getToken(
      vapidKey:
          "BKWmbErqbFv4zzskGF4VMCxNvPKkv6i7BbpIBhRNpcg-7WmV-l3czyWHgVp72MTt9YB-qALjG838SJn0ra14FaQ",
    );
    repository
        .login(userNameController.text, passwordController.text, deviceToken)
        .then((value) async {
      Navigator.of(context, rootNavigator: true).pop();
      Map<String, dynamic> mapResponse = json.decode(value.body);
      if (value.statusCode == 200 || value.statusCode == 201) {
        String accessToken = '${mapResponse['token']}';
        int userId = mapResponse['data']['id'];
        String userName = '${mapResponse['data']['name']}';
        String userLoginIdName = '${mapResponse['data']['login_id']}';
        if (mapResponse['data']['host'] != null) {
          await saveHostId(mapResponse['data']['host']['id']);
          await saveHostName(mapResponse['data']['host']['name']);
          await saveHostLoginId(mapResponse['data']['host']['login_id']);
        }
        String livekitRoomId = '${mapResponse['data']['livekit_room_id']}';
        String livekitURL = '${mapResponse['data']['livekit_host']}';

        await saveLogin(true);
        await saveToken(accessToken);
        await saveUserId(userId);
        await saveUserName(userName);
        await saveUserLoginIdName(userLoginIdName);
        await saveLiveKitRoomId(livekitRoomId); // ✅ save it here
        await saveLiveKitURL(livekitURL);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      } else {
        showMessageAlert(
          context: context,
          message: '${mapResponse['message']}',
          onClick: () async {
            if (mapResponse['data'] != null) {
              if (!await launchUrl(Uri.parse(mapResponse['data']))) {
                showMessageAlert(
                  context: context,
                  message: appURLNotLaunchingContactAdminTxt,
                  onClick: () async {
                    Navigator.pop(context);
                  },
                );
              }
            } else {
              Navigator.pop(context);
            }
          },
        );
      }
    }).catchError((e) {});
  }

  void changePassword(context) async {
    showLoadingAlert(context: context);
    repository
        .changePassword(oldPasswordController.text, newPasswordController.text)
        .then((value) async {
      Navigator.of(context, rootNavigator: true).pop();
      Map<String, dynamic> mapResponse = json.decode(value.body);
      if (value.statusCode == 200 || value.statusCode == 201) {
        showMessageAlert(
          context: context,
          message: '${mapResponse['message']}',
          onClick: () {
            Navigator.pop(context);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomePage()),
            );
          },
        );
      } else {
        showMessageAlert(
          context: context,
          message: '${mapResponse['message']}',
          onClick: () {
            Navigator.pop(context);
          },
        );
      }
    }).catchError((e) {});
  }
}
