import 'package:agora_calling_app/src/controllers/user_controller.dart';
import 'package:agora_calling_app/src/helpers/texts.dart';
import 'package:agora_calling_app/src/helpers/validator.dart';
import 'package:agora_calling_app/src/services/auth_service.dart';
import 'package:agora_calling_app/src/widget/colors.dart';
import 'package:agora_calling_app/src/widget/custom_alert.dart';
import 'package:agora_calling_app/src/widget/custom_app_bar.dart';
import 'package:agora_calling_app/src/widget/custom_bottom_bar.dart';
import 'package:agora_calling_app/src/widget/custom_button.dart';
import 'package:agora_calling_app/src/widget/custom_input.dart';
import 'package:agora_calling_app/src/widget/custom_text_field.dart';
import 'package:agora_calling_app/src/widget/dimensions.dart';
import 'package:agora_calling_app/src/widget/style.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_advanced_switch/flutter_advanced_switch.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:mvc_pattern/mvc_pattern.dart';

class Setting extends StatefulWidget{
  @override
  const Setting({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SettingState();
}

class SettingState extends StateMVC<Setting>{
  UserController userCon = UserController();

  SettingState() : super(UserController()) {
    userCon = controller as UserController;
  }
  final _controller = ValueNotifier<bool>(false);

  @override
  void initState() {
    // TODO: implement initState
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if(message.data['type'] == 'disabled_user') {
        print("disable-user!");

        logOut();
        showMessageAlert(
          context: context,
          message: 'You Have Been Blocked Please Kindly Contact Your Host!',
          isDismissable: false,
          onClick: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/Login');
          },
        );
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: HexColor(mediumLightColor),
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: true,
        child: Scaffold(
          key: userCon.scaffoldKey,
          backgroundColor: whiteColor,
          resizeToAvoidBottomInset: false,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(60),
            child: Material(
              color: HexColor(mediumLightColor),
              elevation: 0,
              child: CustomSmallAppBar(
                context,
                leading: true,
                iconColor: whiteColor,
                titleColor: whiteColor,
                title: "Settings",
                actions: false,
                // user: true,
                onBack: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
          bottomNavigationBar: CustomBottomBar(),
          body: Form(
            key: userCon.formKey,
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () {
                    FocusScope.of(context).requestFocus(FocusNode());
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 10.0, left: 25.0, right: 25.0),
                    scrollDirection: Axis.vertical,
                    primary: true,
                    child: Align(
                      child: Container(
                        width: kIsWeb ? 600 : MediaQuery.of(context).size.width,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 19.0),
                            Text(
                              changedPassTxt,
                              textAlign: TextAlign.center,
                              style: montserratSemiBold.copyWith(
                                color: HexColor(lightBlackColor),
                                fontSize: Dimensions.fontSizeLarge,
                              ),
                            ),
                            const SizedBox(height: 19.0),
                            CustomTextField(
                              textType: TextInputType.text,
                              focusNode: userCon.oldPasswordFocusNode,
                              controller: userCon.oldPasswordController,
                              obscureText: true,
                              maxLines: 1,
                              decoration: textFieldDecoration(
                                context,
                                labelText: oldPassTxt,
                              ),
                              onFieldSubmitted: (value) {
                                userCon.oldPasswordFocusNode.unfocus();
                              },
                              onSaved: (String? name) {
                                userCon.oldPasswordController.text = name!;
                              },
                              onTapValue: () {},
                              validator: (value) {
                                String? errorString = FormValidator().validatePassword(value!);
                                return errorString;
                              },
                            ),
                            const SizedBox(height: 12.0),
                            CustomTextField(
                              textType: TextInputType.text,
                              focusNode: userCon.newPasswordFocusNode,
                              controller: userCon.newPasswordController,
                              obscureText: true,
                              maxLines: 1,
                              decoration: textFieldDecoration(
                                context,
                                labelText: newPassTxt,
                              ),
                              onFieldSubmitted: (value) {
                                userCon.newPasswordFocusNode.unfocus();
                              },
                              onSaved: (String? insertPhone) {
                                userCon.newPasswordController.text = insertPhone!;
                              },
                              onTapValue: () {},
                              validator: (value) {
                                String? errorString = FormValidator().validateNewPassword(value!);
                                return errorString;
                              },
                            ),
                            const SizedBox(height: 12.0),
                            CustomTextField(
                              textType: TextInputType.text,
                              focusNode: userCon.confirmNewPasswordFocusNode,
                              controller: userCon.confirmNewPasswordController,
                              obscureText: true,
                              maxLines: 1,
                              decoration: textFieldDecoration(
                                context,
                                labelText: confirmPassTxt,
                              ),
                              onFieldSubmitted: (value) {
                                userCon.confirmNewPasswordFocusNode.unfocus();
                              },
                              onSaved: (String? insertPhone) {
                                userCon.confirmNewPasswordController.text = insertPhone!;
                              },
                              onTapValue: () {},
                              validator: (value) {
                                String? errorString = FormValidator().validateConfirmPassword(value!, userCon.newPasswordController.text);
                                return errorString;
                              },
                            ),
                            const SizedBox(height: 29.0),
                            Text(
                              fingerPrintTxt,
                              textAlign: TextAlign.center,
                              style: montserratRegular.copyWith(
                                color: HexColor(lightBlackColor),
                                fontSize: Dimensions.fontSizeSmall,
                              ),
                            ),
                            const SizedBox(height: 10.0),
                            AdvancedSwitch(
                              controller: _controller,
                              activeColor: Colors.green,
                              inactiveColor: Colors.grey,
                              activeChild: Text(''),
                              inactiveChild: Text(''),
                              // activeImage: AssetImage('assets/images/on.png'),
                              // inactiveImage: AssetImage('assets/images/off.png'),
                              borderRadius: BorderRadius.all(const Radius.circular(15)),
                              width: 66.67,
                              height: 30.0,
                              enabled: true,
                              disabledOpacity: 0.5,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 60),
                    child: CustomButtonWidget(
                      width: 328,
                      height: 48.0,
                      title: saveTxt,
                      border: null,
                      titleColor: whiteColor,
                      fontSize: Dimensions.fontSizeLarge,
                      borderRadius: BorderRadius.circular(6.0),
                      backgroundColor: HexColor(mediumLightColor),
                      onClick: () {
                        FocusScope.of(context).unfocus();
                        if (userCon.formKey.currentState!.validate()) {
                          userCon.formKey.currentState!.save();

                          userCon.changePassword(context);
                          // usersController.loginUser(usersController.emailMobileController.text,usersController.passwordController.text,context);
                        }
                      },
                    ),
                  ),
                  alignment: Alignment.bottomCenter,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}