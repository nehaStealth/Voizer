import 'package:agora_calling_app/src/controllers/session_management_controller.dart';
import 'package:agora_calling_app/src/helpers/texts.dart';
import 'package:agora_calling_app/src/services/auth_service.dart';
import 'package:agora_calling_app/src/widget/colors.dart';
import 'package:agora_calling_app/src/widget/custom_alert.dart';
import 'package:agora_calling_app/src/widget/custom_app_bar.dart';
import 'package:agora_calling_app/src/widget/custom_bottom_bar.dart';
import 'package:agora_calling_app/src/widget/custom_button.dart';
import 'package:agora_calling_app/src/widget/dimensions.dart';
import 'package:agora_calling_app/src/widget/style.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class UserSession extends StatefulWidget {
  @override
  const UserSession({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => UserSessionState();
}

class UserSessionState extends StateMVC<UserSession> {
  SessionManagementController sessionController = SessionManagementController();
  String userMessage = '';

  UserSessionState() : super(SessionManagementController()) {
    sessionController = controller as SessionManagementController;
  }

  @override
  void initState() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.data['type'] == 'message') {
        setState(() {
          userMessage = message.data['message'] ?? '';
        });
        print("clicked messgage!");
      } else if (message.data['type'] == 'user_removed') {
        print("kick-out-user!");

        await sessionController.leaveSession();
        Navigator.pushNamed(context, '/Home');
      } else {
        print("disable-user!");

        await sessionController.leaveSession();
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
    // TODO: implement initState
    sessionController.getUserInfo();
    sessionController.joinSession(context);
    setState(() {
      WakelockPlus.enable();
    });
    super.initState();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    sessionController.leaveSession();
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    int hostIndex = sessionController.remoteUsers
        .indexWhere((user) => user.id == sessionController.hostUserId);
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
                  sureWantToLeaveCallTxt,
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
                        await _leaveWithLoader(context);
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
            key: sessionController.scaffoldKey,
            backgroundColor: whiteColor,
            resizeToAvoidBottomInset: false,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Material(
                color: HexColor(darkBlueColor),
                elevation: 0,
                child: CustomSmallAppBar(
                  context,
                  leading: true,
                  bgColor: HexColor(darkBlueColor),
                  iconColor: whiteColor,
                  titleColor: whiteColor,
                  title: "",
                  actions: true,
                  // user: true,
                  onBack: () {
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
                            sureWantToLeaveCallTxt,
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
                                  print(';;;;;;;;;;');
                                  await _leaveWithLoader(context);
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
                ),
              ),
            ),
            bottomNavigationBar:
                CustomBottomBar(bgColor: HexColor(darkBlueColor)),
            body: Container(
              height: MediaQuery.sizeOf(context).height,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bg.png'),
                  fit: BoxFit.fill,
                ),
              ),
              child: SingleChildScrollView(
                clipBehavior: Clip.hardEdge,
                child: sessionController.isJoined
                    ? Column(
                        children: [
                          Container(
                            height: 50,
                            width: MediaQuery.sizeOf(context).width,
                            margin: EdgeInsets.only(top: 5, bottom: 10),
                            padding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 15),
                            child: Text(
                              '$helloTxt, ${sessionController.userName},',
                              style: montserratMedium.copyWith(
                                color: whiteColor,
                                fontSize: Dimensions.fontSizeExtraDefault,
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(
                                top: 20.0, left: 15, right: 15, bottom: 25),
                            padding: const EdgeInsets.only(
                                top: 50, left: 20, right: 20, bottom: 25),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              image: DecorationImage(
                                image: AssetImage('assets/images/bg-3.png'),
                                fit: BoxFit.fill,
                              ),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceAround,
                                  children: [
                                    InkWell(
                                      onTap: () async {
                                        await sessionController
                                            .changeVolumeBroadcasting();
                                      },
                                      child: SizedBox(
                                        width:
                                            MediaQuery.sizeOf(context).width /
                                                4,
                                        child: Column(
                                          children: [
                                            Image.asset(
                                              sessionController.isOnSpeaker
                                                  ? 'assets/images/speaker.png'
                                                  : 'assets/images/mute-speaker.png',
                                              height: 60,
                                              width: 60,
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              speakerTxt,
                                              style: montserratMedium.copyWith(
                                                color: whiteColor,
                                                fontSize:
                                                    Dimensions.fontSizeSmall,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () async {
                                        await sessionController
                                            .changeVolumeBroadcastingToBluetooth();
                                      },
                                      child: SizedBox(
                                        width:
                                            MediaQuery.sizeOf(context).width /
                                                4,
                                        child: Column(
                                          children: [
                                            Image.asset(
                                              sessionController.isOnBluetooth
                                                  ? 'assets/images/active-bluetooth.png'
                                                  : 'assets/images/bluetooth.png',
                                              height: 60,
                                              width: 60,
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              bluetoothTxt,
                                              style: montserratMedium.copyWith(
                                                color: whiteColor,
                                                fontSize:
                                                    Dimensions.fontSizeSmall,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        showBGContentAlert(
                                          context: context,
                                          width:
                                              MediaQuery.of(context).size.width,
                                          height: 170.0,
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Text(
                                                alertTxt,
                                                textAlign: TextAlign.center,
                                                style:
                                                    montserratSemiBold.copyWith(
                                                  color: whiteColor,
                                                  fontSize:
                                                      Dimensions.fontSizeLarge,
                                                ),
                                              ),
                                              const SizedBox(height: 23.0),
                                              Text(
                                                sureWantToLeaveCallTxt,
                                                textAlign: TextAlign.center,
                                                style:
                                                    montserratRegular.copyWith(
                                                  color: whiteColor,
                                                  fontSize: Dimensions
                                                      .fontSizeDefault,
                                                ),
                                              ),
                                              const SizedBox(height: 30.0),
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  CustomButtonWidget(
                                                    width: 89.0,
                                                    height: 36.0,
                                                    title: yesTxt,
                                                    border: null,
                                                    titleColor: whiteColor,
                                                    fontSize: Dimensions
                                                        .fontSizeLarge,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5.0),
                                                    backgroundColor:
                                                        HexColor(greenColor),
                                                    onClick: () async {
                                                      await _leaveWithLoader(
                                                          context);
                                                    },
                                                  ),
                                                  const SizedBox(width: 30.0),
                                                  CustomButtonWidget(
                                                    width: 89.0,
                                                    height: 36.0,
                                                    title: noTxt,
                                                    border: null,
                                                    titleColor: whiteColor,
                                                    fontSize: Dimensions
                                                        .fontSizeLarge,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5.0),
                                                    backgroundColor:
                                                        HexColor(greenColor),
                                                    onClick: () {
                                                      Navigator.pop(
                                                          context, false);
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: SizedBox(
                                        width:
                                            MediaQuery.sizeOf(context).width /
                                                4,
                                        child: Column(
                                          children: [
                                            Image.asset(
                                              'assets/images/exit.png',
                                              height: 60,
                                              width: 60,
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              exitRoomTxt,
                                              style: montserratMedium.copyWith(
                                                color: whiteColor,
                                                fontSize:
                                                    Dimensions.fontSizeSmall,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 70),
                                hostIndex != -1
                                    ? Column(
                                        children: [
                                          Listener(
                                            behavior:
                                                HitTestBehavior.translucent,

                                            // Finger touches screen → UNMUTE
                                            onPointerDown: (_) {
                                              setState(() {
                                                sessionController
                                                    .isUserHoldButton = true;
                                              });
                                              sessionController
                                                  .changeAudioState(
                                                      true); // UNMUTE
                                            },

                                            // Finger lifts → MUTE
                                            onPointerUp: (_) {
                                              setState(() {
                                                sessionController
                                                    .isUserHoldButton = false;
                                              });
                                              sessionController
                                                  .changeAudioState(
                                                      false); // MUTE
                                            },

                                            // Safety: finger leaves widget area
                                            onPointerCancel: (_) {
                                              setState(() {
                                                sessionController
                                                    .isUserHoldButton = false;
                                              });
                                              sessionController
                                                  .changeAudioState(
                                                      false); // MUTE
                                            },

                                            child: Image.asset(
                                              sessionController.isMuted
                                                  ? 'assets/images/mute.png'
                                                  : 'assets/images/unmute.png',
                                              height: 261,
                                              width: 261,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Center(
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                                color: whiteColor),
                                            const SizedBox(height: 10),
                                            Text(
                                              'Waiting Host To Join The Session...',
                                              textAlign: TextAlign.center,
                                              style:
                                                  montserratSemiBold.copyWith(
                                                color: whiteColor,
                                                fontSize:
                                                    Dimensions.fontSizeLarge,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                hostIndex != -1
                                    ? Container(
                                        padding: EdgeInsets.only(top: 30),
                                        child: Text(
                                          tapAndHoldToSpeakTxt,
                                          style: montserratRegular.copyWith(
                                            color: whiteColor,
                                            fontSize:
                                                Dimensions.fontSizeDefault,
                                          ),
                                        ),
                                      )
                                    : Container(),
                                const SizedBox(height: 20),
                                userMessage != ''
                                    ? Container(
                                        width: MediaQuery.sizeOf(context).width,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: HexColor(greenColor),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          userMessage,
                                          style: montserratRegular.copyWith(
                                            color: whiteColor,
                                            fontSize:
                                                Dimensions.fontSizeDefault,
                                          ),
                                        ),
                                      )
                                    : Container(),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: whiteColor),
                            const SizedBox(height: 10),
                            Text(
                              'Please Wait While We\'re Joining You To Session...',
                              textAlign: TextAlign.center,
                              style: montserratSemiBold.copyWith(
                                color: whiteColor,
                                fontSize: Dimensions.fontSizeLarge,
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

  Future<void> _leaveWithLoader(BuildContext context) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    await sessionController.leaveSession();

    Navigator.pop(context); // close loader
    Navigator.pushNamed(context, '/Home');
  }
}
