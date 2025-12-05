import 'package:agora_calling_app/src/controllers/user_controller.dart';
import 'package:agora_calling_app/src/helpers/texts.dart';
import 'package:agora_calling_app/src/helpers/validator.dart';
import 'package:agora_calling_app/src/widget/colors.dart';
import 'package:agora_calling_app/src/widget/custom_alert.dart';
import 'package:agora_calling_app/src/widget/custom_button.dart';
import 'package:agora_calling_app/src/widget/custom_input.dart';
import 'package:agora_calling_app/src/widget/custom_text_field.dart';
import 'package:agora_calling_app/src/widget/dimensions.dart';
import 'package:agora_calling_app/src/widget/style.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/auth_service.dart';

class Login extends StatefulWidget{
  @override
  const Login({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => LoginState();
}

class LoginState extends StateMVC<Login>{
  UserController userCon = UserController();
  Connectivity connectivity = Connectivity();
  String? logoPath;

  LoginState() : super(UserController()) {
    userCon = controller as UserController;
  }

  @override
  void initState() {
    // TODO: implement initState
    checkInternetConnectivity();
    _loadLogo();
    super.initState();
  }

  Future<void> _loadLogo() async {
    String logo = await getClientLogoPath(); // 🔹 fetch value first
    setState(() {
      logoPath = logo; // 🔹 then update state
    });
  }

  Future<ConnectivityResult> checkInternetConnectivity() async {
    ConnectivityResult connectivityStatus = await connectivity.checkConnectivity();
    if(connectivityStatus == ConnectivityResult.none) {
      showContentAlert(
        context: context,
        width: MediaQuery.of(context).size.width,
        height: 170.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              alertTxt,
              textAlign: TextAlign.center,
              style: montserratSemiBold.copyWith(
                color: blackColor,
                fontSize: Dimensions.fontSizeLarge,
              ),
            ),
            const SizedBox(height: 23.0),
            Text(
              connectToInternetConnectionTxt,
              textAlign: TextAlign.center,
              style: montserratRegular.copyWith(
                color: blackColor,
                fontSize: Dimensions.fontSizeDefault,
              ),
            ),
            const SizedBox(height: 30.0),
            CustomButtonWidget(
              width: 89.0,
              height: 36.0,
              title: okTxt,
              border: null,
              titleColor: whiteColor,
              fontSize: Dimensions.fontSizeLarge,
              borderRadius: BorderRadius.circular(5.0),
              backgroundColor: HexColor(greenColor),
              onClick: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      );
    }

    return connectivityStatus;
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: whiteColor,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        onPopInvoked: (canPop) {
          showContentAlert(
            context: context,
            width: MediaQuery.of(context).size.width,
            height: 170.0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  alertTxt,
                  textAlign: TextAlign.center,
                  style: montserratSemiBold.copyWith(
                    color: blackColor,
                    fontSize: Dimensions.fontSizeLarge,
                  ),
                ),
                const SizedBox(height: 23.0),
                Text(
                  sureWantToCloseAppTxt,
                  textAlign: TextAlign.center,
                  style: montserratRegular.copyWith(
                    color: blackColor,
                    fontSize: Dimensions.fontSizeDefault,
                  ),
                ),
                const SizedBox(height: 30.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomButtonWidget(
                      width: 89.0,
                      height: 36.0,
                      title: yesTxt,
                      border: null,
                      titleColor: whiteColor,
                      fontSize: Dimensions.fontSizeLarge,
                      borderRadius: BorderRadius.circular(5.0),
                      backgroundColor: HexColor(greenColor),
                      onClick: () {
                        SystemNavigator.pop();
                      },
                    ),
                    const SizedBox(width: 30.0),
                    CustomButtonWidget(
                      width: 89.0,
                      height: 36.0,
                      title: noTxt,
                      border: null,
                      titleColor: whiteColor,
                      fontSize: Dimensions.fontSizeLarge,
                      borderRadius: BorderRadius.circular(5.0),
                      backgroundColor: HexColor(greenColor),
                      onClick: () {
                        Navigator.pop(context, false);
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        child: Scaffold(
          key: userCon.scaffoldKey,
          backgroundColor: whiteColor,
          body: GestureDetector(
            onTap: () {
              FocusScope.of(context).requestFocus(FocusNode());
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 50.0, left: 25.0, right: 25.0, bottom: 10),
              scrollDirection: Axis.vertical,
              primary: true,
              child: Form(
                key: userCon.formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    //Image.asset('assets/icons/blue.png'),//comment by neha thakur
                    logoPath != null && logoPath!.isNotEmpty
                        ? Image.network(
                      logoPath!,
                      height: 300,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return SizedBox(height: 300);
                      },
                    )
                        : SizedBox(height: 300),
                    const SizedBox(height: 20.0),
                    Text(
                      loginTxt,
                      textAlign: TextAlign.center,
                      style: montserratSemiBold.copyWith(
                        color: HexColor(blueColor),
                        fontSize: Dimensions.fontSizeOverLarge,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Text(
                      loginAccountTxt,
                      textAlign: TextAlign.center,
                      style: montserratRegular.copyWith(
                        color: HexColor(primaryColor),
                        fontSize: Dimensions.fontSizeDefault,
                      ),
                    ),
                    const SizedBox(height: 47.0),
                    Text(
                      userNameTxt.toCapitalized(),
                      textAlign: TextAlign.center,
                      style: montserratSemiBold.copyWith(
                        color: HexColor(lightBlackColor),
                        fontSize: Dimensions.fontSizeLarge,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Container(
                      width: kIsWeb ? 500 : null,
                      child: CustomTextField(
                        textType: TextInputType.text,
                        focusNode: userCon.userNameFocusNode,
                        controller: userCon.userNameController,
                        obscureText: false,
                        decoration: textFieldDecoration(
                          context,
                          labelText: userNameTxt,
                        ),
                        onFieldSubmitted: (value) {
                          userCon.userNameFocusNode.unfocus();
                        },
                        onSaved: (String? name) {
                          userCon.userNameController.text = name!;
                        },
                        onTapValue: () {},
                        validator: (value) {
                          String? errorString = FormValidator().validateName(value!);
                          return errorString;
                        },
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    Text(
                      passwordTxt.toCapitalized(),
                      textAlign: TextAlign.center,
                      style: montserratSemiBold.copyWith(
                        color: HexColor(lightBlackColor),
                        fontSize: Dimensions.fontSizeLarge,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    Container(
                      width: kIsWeb ? 500 : null,
                      child: CustomTextField(
                        textType: TextInputType.visiblePassword,
                        focusNode: userCon.passwordFocusNode,
                        controller: userCon.passwordController,
                        obscureText: userCon.passwordVisible,
                        maxLines: 1,
                        decoration: textFieldDecoration(
                          context,
                          labelText: passwordTxt,
                          suffixIcon: IconButton(
                            icon: Icon(
                              userCon.passwordVisible ? Icons.visibility : Icons.visibility_off,
                              color: HexColor(lightBlackColor),
                            ),
                            onPressed: () {
                              setState(() {
                                userCon.passwordVisible = !userCon.passwordVisible;
                              });
                            },
                          ),
                        ),
                        onFieldSubmitted: (value) {
                          userCon.passwordFocusNode.unfocus();
                        },
                        onSaved: (String? insertPhone) {
                          userCon.passwordController.text = insertPhone!;
                        },
                        onTapValue: () {},

                        validator: (value) {
                          String? errorString = FormValidator().validatePassword(value!);
                          return errorString;
                        },
                      ),
                    ),
                    const SizedBox(height: 173.0),
                    CustomButtonWidget(
                      width: kIsWeb ? 500 : MediaQuery.of(context).size.width,
                      height: 48.0,
                      title: loginTxt,
                      border: null,
                      titleColor: whiteColor,
                      fontSize: Dimensions.fontSizeLarge,
                      borderRadius: BorderRadius.circular(6.0),
                      backgroundColor: HexColor(mediumLightColor),
                      onClick: () async {
                        ConnectivityResult connectivityStatus = await checkInternetConnectivity();

                        if(connectivityStatus != ConnectivityResult.none) {
                          FocusScope.of(context).unfocus();
                          if (userCon.formKey.currentState!.validate()) {
                            userCon.formKey.currentState!.save();
                            userCon.login(context);
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 30.0),
                    Center(
                      child: Text(
                        loginWithFingerTxt,
                        textAlign: TextAlign.center,
                        style: montserratRegular.copyWith(
                          color: HexColor(errorColor),
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5.0),
                    Center(
                      child: Text(
                        firstLoginTxt,
                        textAlign: TextAlign.center,
                        style: montserratRegular.copyWith(
                          color: HexColor(secondaryColor),
                          fontSize: Dimensions.fontSizeSmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}