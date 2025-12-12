import 'dart:async';
import 'package:agora_calling_app/src/controllers/home_controller.dart';
import 'package:agora_calling_app/src/helpers/texts.dart';
import 'package:agora_calling_app/src/services/auth_service.dart';
import 'package:agora_calling_app/src/widget/colors.dart';
import 'package:agora_calling_app/src/widget/custom_alert.dart';
import 'package:agora_calling_app/src/widget/custom_bottom_bar.dart';
import 'package:agora_calling_app/src/widget/custom_button.dart';
import 'package:agora_calling_app/src/widget/dimensions.dart';
import 'package:agora_calling_app/src/widget/style.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../helpers/global.dart';
import 'livekit_page.dart';

class HomePage extends StatefulWidget {
  @override
  const HomePage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => HomeState();
}

class HomeState extends StateMVC<HomePage> {
  HomeController homeCon = HomeController();
  Connectivity connectivity = Connectivity();
  String? roomId;
  String? service;
  Timer? _appStatusTimer;
  bool _isMaintenancePopupShown = false; // track if popup is active

  HomeState() : super(HomeController()) {
    homeCon = controller as HomeController;
  }

  @override
  void initState() {
    // TODO: implement initState
    homeCon.isOnHomePage = true;
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.data['type'] == 'disabled_user') {
        print('disabled ');

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
    initData();
    checkRoomId();
    startAppStatusPolling();
    checkInternetConnectivity();

    super.initState();
  }

  void startAppStatusPolling() {
    // Poll every 10 seconds to check app Maintenance
    _appStatusTimer = Timer.periodic(Duration(seconds: 10), (_) async {
      await checkMaintenanceMode();
    });
  }

  //check app maintainenance mode api status
  Future<void> checkMaintenanceMode() async {
    try {
      bool success = await homeCon.fetchAppSettings();

      if (success) {
        String? appStatus = await getAppStatus();

        if (appStatus == "1") {
          // Show popup only if not already shown
          if (!_isMaintenancePopupShown) {
            _isMaintenancePopupShown = true;
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                title: Text("Maintenance"),
                content: Text("The app is currently under maintenance."),
              ),
            );
          }
        } else {
          // Close popup if status changed to 0
          if (_isMaintenancePopupShown) {
            _isMaintenancePopupShown = false;
            Navigator.pop(context); // closes the dialog
          }
        }
      }
    } catch (e) {
      print("Error checking maintenance mode: $e");
    }
  }

  Future<ConnectivityResult> checkInternetConnectivity() async {
    ConnectivityResult connectivityStatus =
        await connectivity.checkConnectivity();
    if (connectivityStatus == ConnectivityResult.none) {
      showBGContentAlert(
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
                color: whiteColor,
                fontSize: Dimensions.fontSizeLarge,
              ),
            ),
            const SizedBox(height: 23.0),
            Text(
              connectToInternetConnectionTxt,
              textAlign: TextAlign.center,
              style: montserratRegular.copyWith(
                color: whiteColor,
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

  Future<void> checkRoomId() async {
    try {
      int userId = await getUserId();
      roomId = await homeCon.fetchUserDataAndSaveRoomId(userId);

      if (roomId != null && roomId!.isNotEmpty) {
        service = await getSavedService();
        print("User's LiveKit Room ID: $roomId");
        print("Service: $service");
      } else {
        print("❌ Room ID not found for user $userId");
      }
    } catch (e) {
      print("Exception while fetching room ID: $e");
    }
  }

  initData() {
    Future.delayed(Duration(seconds: 1)).then((value) async {
      try {
        await homeCon.checkUserStatus();
        if (homeCon.isUserActive) {
          homeCon.getUserInfo();
          if (homeCon.isOnHomePage == true) {
            homeCon.getHostJoinedData();
            //homeCon.checkHostJoinedInfoTimer =
            //             Timer.periodic(Duration(seconds: 3), (timer) async {
            //           if (homeCon.isOnHomePage == true) {
            //             homeCon.getHostJoinedData();
            //           }
            //         });
          }
        } else {
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
      } catch (e) {
        print(e.toString());
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _appStatusTimer?.cancel();
    homeCon.checkHostJoinedInfoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: HexColor(darkBlueColor),
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: false,
        onPopInvoked: (canPop) {
          showBGContentAlert(
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
                    color: whiteColor,
                    fontSize: Dimensions.fontSizeLarge,
                  ),
                ),
                const SizedBox(height: 23.0),
                Text(
                  sureWantToCloseAppTxt,
                  textAlign: TextAlign.center,
                  style: montserratRegular.copyWith(
                    color: whiteColor,
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
                      onClick: () async {
                        homeCon.checkHostJoinedInfoTimer?.cancel();
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
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bg.png'),
            ),
          ),
          child: Scaffold(
            key: homeCon.scaffoldKey,
            backgroundColor: Colors.transparent,
            resizeToAvoidBottomInset: false,
            bottomNavigationBar:
                CustomBottomBar(bgColor: HexColor(darkBlueColor)),
            body: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: AssetImage('assets/images/border.png'),
                  fit: BoxFit.fill,
                ),
              ),
              width: kIsWeb ? 600 : MediaQuery.of(context).size.width,
              margin: const EdgeInsets.only(
                  top: 80.0, left: 25.0, right: 25.0, bottom: 80),
              padding: const EdgeInsets.only(
                  right: 19, top: 19, left: 19, bottom: 30),
              child: Align(
                alignment: Alignment.center,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () {
                          showBGContentAlert(
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
                                    color: whiteColor,
                                    fontSize: Dimensions.fontSizeLarge,
                                  ),
                                ),
                                const SizedBox(height: 23.0),
                                Text(
                                  logoutAppTxt,
                                  textAlign: TextAlign.center,
                                  style: montserratRegular.copyWith(
                                    color: whiteColor,
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
                                        setState(() {
                                          print('logout clicked');
                                          logOut();

                                          homeCon.checkHostJoinedInfoTimer
                                              ?.cancel();
                                          Navigator.pushNamed(
                                              context, '/Login');
                                        });
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
                        child: Container(
                          alignment: Alignment.topRight,
                          child: Image.asset('assets/icons/logout-2.png',
                              height: 50, width: 50),
                        ),
                      ),
                      const SizedBox(height: 41),
                      Container(
                        padding: const EdgeInsets.only(
                            top: 35, left: 20, right: 20, bottom: 25),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: DecorationImage(
                            image: AssetImage('assets/images/bg-2.png'),
                            fit: BoxFit.fill,
                          ),
                        ),
                        child: Column(
                          children: [
                            RichText(
                              text: TextSpan(
                                text: 'Welcome ',
                                style: montserratBold.copyWith(
                                    color: whiteColor,
                                    fontSize: Dimensions.fontSizeOverLarge),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: '${homeCon.userName}!',
                                    style: montserratBold.copyWith(
                                      color: HexColor(mediumLightColor),
                                      fontSize: Dimensions.fontSizeOverLarge,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 19),
                            Text(
                              'You’re now logged in and ready to join the call with your Host.',
                              textAlign: TextAlign.center,
                              style: montserratRegular.copyWith(
                                color: whiteColor,
                                fontSize: Dimensions.fontSizeDefault,
                              ),
                            ),
                            const SizedBox(height: 19),
                            RichText(
                              text: TextSpan(
                                text: 'Your Host Name is : ',
                                style: montserratBold.copyWith(
                                  color: whiteColor,
                                  fontSize: Dimensions.fontSizeRate,
                                ),
                                children: <TextSpan>[
                                  TextSpan(
                                    text: '${homeCon.hostName}',
                                    style: montserratBold.copyWith(
                                      color: HexColor(mediumLightColor),
                                      fontSize: Dimensions.fontSizeRate,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 37.0),
                            !homeCon.isHostJoined
                                ? CustomButtonWidget(
                                    width: MediaQuery.of(context).size.width,
                                    height: 25.0,
                                    title: waitHostJoinTxt,
                                    border: null,
                                    titleColor: HexColor(mediumLightColor),
                                    fontSize: Dimensions.fontSizeLarge,
                                    borderRadius: BorderRadius.circular(6.0),
                                    backgroundColor: Colors.transparent,
                                    onClick: () {},
                                  )
                                : Container(),
                            !homeCon.isHostJoined
                                ? const SizedBox(height: 10.0)
                                : Container(),
                            homeCon.isHostJoined
                                ? CustomButtonWidget(
                                    width: MediaQuery.of(context).size.width,
                                    height: 25.0,
                                    title: hostOnlineTxt,
                                    border: null,
                                    titleColor: HexColor(greenColor),
                                    fontSize: Dimensions.fontSizeLarge,
                                    borderRadius: BorderRadius.circular(6.0),
                                    backgroundColor: Colors.transparent,
                                    onClick: () {},
                                  )
                                : Container(),
                            homeCon.isHostJoined
                                ? const SizedBox(height: 15.0)
                                : Container(),
                            homeCon.isHostJoined
                                ? CustomButtonWidget(
                                    width: MediaQuery.of(context).size.width,
                                    height: 47.0,
                                    title: joinRoomTxt,
                                    border: null,
                                    titleColor: whiteColor,
                                    fontSize: Dimensions.fontSizeLarge,
                                    borderRadius: BorderRadius.circular(6.0),
                                    backgroundColor: HexColor(mediumLightColor),
                                    onClick: () async {
                                      ConnectivityResult connectivityStatus =
                                          await checkInternetConnectivity();
                                      bool isHavePermission = true;
                                      if (connectivityStatus !=
                                          ConnectivityResult.none) {
                                        if (!await Permission.microphone
                                            .request()
                                            .isGranted) {
                                          isHavePermission = false;
                                          await openAppSettings();
                                        }

                                        // if(!await Permission.storage.request().isGranted) {
                                        //   isHavePermission = false;
                                        //   await openAppSettings();
                                        // }

                                        if (!await homeCon
                                            .checkAppVersion(context)) {
                                          print("TrueOne:");
                                          isHavePermission = false;
                                          showMessageAlert(
                                            context: context,
                                            isDismissable: false,
                                            message:
                                                youUsingOldAppPleaseUpdateTxt,
                                            onClick: () async {
                                              if (!await launchUrl(
                                                  Uri.parse(homeCon.appURL))) {
                                                showMessageAlert(
                                                  context: context,
                                                  message:
                                                      appURLNotLaunchingContactAdminTxt,
                                                  onClick: () async {
                                                    Navigator.pop(context);
                                                  },
                                                );
                                              }
                                            },
                                          );
                                        }

                                        if (isHavePermission) {
                                          homeCon.checkHostJoinedInfoTimer
                                              ?.cancel();
                                          await Navigator.pushNamed(
                                              context, '/UserSession');
                                          initData();
                                          
                                          print("Service: $service");
                                        }
                                      }
                                    },
                                  )
                                : Container(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: InkWell(
                          onTap: () async {
                            homeCon.checkHostJoinedInfoTimer?.cancel();
                            await Navigator.pushNamed(context, '/Recording');
                            initData();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Image.asset('assets/icons/recordings.png',
                                  height: 60, width: 60),
                              const SizedBox(width: 27),
                              Text(
                                yourRecordingTxt,
                                textAlign: TextAlign.center,
                                style: montserratRegular.copyWith(
                                  color: whiteColor,
                                  fontSize: Dimensions.fontSizeDefault,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Padding(
                        padding: const EdgeInsets.only(left: 20),
                        child: InkWell(
                          onTap: () async {
                            homeCon.checkHostJoinedInfoTimer?.cancel();
                            await Navigator.pushNamed(context, '/Setting');
                            initData();
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Image.asset('assets/icons/settings.png',
                                  height: 60, width: 60),
                              const SizedBox(width: 27),
                              Text(
                                settingTxt,
                                textAlign: TextAlign.center,
                                style: montserratRegular.copyWith(
                                  color: whiteColor,
                                  fontSize: Dimensions.fontSizeDefault,
                                ),
                              ),
                            ],
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
      ),
    );
  }
}
