import 'package:agora_calling_app/src/controllers/recording_controller.dart';
import 'package:agora_calling_app/src/services/auth_service.dart';
import 'package:agora_calling_app/src/widget/colors.dart';
import 'package:agora_calling_app/src/widget/custom_alert.dart';
import 'package:agora_calling_app/src/widget/custom_app_bar.dart';
import 'package:agora_calling_app/src/widget/custom_bottom_bar.dart';
import 'package:agora_calling_app/src/widget/custom_listview.dart';
import 'package:agora_calling_app/src/widget/dimensions.dart';
import 'package:agora_calling_app/src/widget/style.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:lazy_load_scrollview/lazy_load_scrollview.dart';
import 'package:mvc_pattern/mvc_pattern.dart';

class RecordingPage extends StatefulWidget{
  @override
  @override
  const RecordingPage({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => RecordingPageState();
}

class RecordingPageState extends StateMVC<RecordingPage>{
  RecordingController recordingCon = RecordingController();

  RecordingPageState() : super(RecordingController()) {
    recordingCon = controller as RecordingController;
  }

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
    recordingCon.getRecordingsList();
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
      child: Scaffold(
        key: recordingCon.scaffoldKey,
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
              title: "Recordings List",
              actions: false,
              // user: true,
              onBack: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        bottomNavigationBar: CustomBottomBar(),
        body: recordingCon.isLoadingData ? Center(
          child: CircularProgressIndicator(),
        ) : recordingCon.recordingsList.isEmpty ? Center(
          child: Text(
            'No Recordings Found!',
            style: montserratRegular.copyWith(
              color: blackColor,
              fontSize: Dimensions.fontSizeExtraLarge,
            ),
          ),
        ) : Container(
          padding: const EdgeInsets.only(top: 20, bottom: 20),
          child: LazyLoadScrollView(
            scrollOffset: 100,
            onEndOfPage: () => recordingCon.getRecordingsList(),
            child: CustomListViewWidget(
              itemCount: recordingCon.recordingsList.length,
              direction: Axis.vertical,
              itemBuilder: (context, index){
                return Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  child: Transform.scale(
                    scale: 1.0,
                    child: ListTile(
                      dense: true,
                      visualDensity: VisualDensity(horizontal: 0, vertical: -4),
                      leading: Image.asset('assets/images/mic.png', height: 59, width: 59),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            recordingCon.recordingsList[index].recordingName,
                            style: montserratRegular.copyWith(
                              color: blackColor,
                              fontSize: Dimensions.fontSizeLarge,
                            ),
                          ),
                          InkWell(
                            onTap: () {
                              recordingCon.playPauseRecording(recordingCon.recordingsList[index].fileName);
                            },
                            child: Icon(recordingCon.isPlaying && recordingCon.recordingsList[index].fileName == recordingCon.currentPlayingURL ? Icons.pause : Icons.play_arrow, color: blackColor, size: 25),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

}