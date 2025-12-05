import 'dart:async';
import 'dart:io';
import 'package:agora_calling_app/src/models/session_user_model.dart';
import 'package:agora_calling_app/src/repositories/session_repository.dart' as repository;
import 'package:agora_calling_app/src/services/auth_service.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class SessionManagementController extends ControllerMVC{
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController muteCon = TextEditingController();
  FocusNode muteFocus = FocusNode();
  bool isJoined = false;
  bool isMuted = true;
  bool isOnSpeaker = true;
  bool isOnBluetooth = true;
  bool isRecording = true;
  bool isUserHoldButton = false;
  String appId = "";
  String channelName = "";
  String token = "";
  String recordingFilePath = '';
  String recordingFileName = '';
  String userName = '';
  // int uid = 1; // uid of the local user
  int uid = 0; // uid of the local user
  int hostUserId = 0; // uid of the local user
  List<SessionUserDetails> remoteUsers = [];
  late RtcEngine agoraEngine; // Agora engine instance
  bool isBluetoothCheckingOn = false;
  // late Timer? userMuteDelayTimer;
  DatabaseReference reference = FirebaseDatabase.instance.ref().child('Active Users');

  getUserInfo() async {
    userName = await getUserName();
    setState(() {});
  }

  joinSession(context) async {
    uid = await getUserId();
    token = await repository.generateRoomToken();
    appId = await getAppId();
    hostUserId = await getHostId();
    channelName = await getChannelName();
    setState(() {});
    await initEngine(context);

    ChannelMediaOptions options = const ChannelMediaOptions(
      clientRoleType: ClientRoleType.clientRoleBroadcaster,
      channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
    );

    await agoraEngine.joinChannel(
      token: token,
      channelId: channelName,
      options: options,
      uid: uid,
    );

    if(await Permission.microphone.request().isGranted) {
      setState(() {
        isMuted = true;
      });
      await agoraEngine.muteLocalAudioStream(true);
      await agoraEngine.enableLocalAudio(false);
    }

    await agoraEngine.setAudioProfile(profile: AudioProfileType.audioProfileMusicHighQualityStereo, scenario: AudioScenarioType.audioScenarioChatroom);
  }

  Future changeVolumeBroadcasting() async {
    isOnSpeaker = !await agoraEngine.isSpeakerphoneEnabled();
    await agoraEngine.setEnableSpeakerphone(isOnSpeaker);
    setState(() {});
  }

  Future changeVolumeBroadcastingToBluetooth() async {
    if(await Permission.bluetooth.request().isGranted) {
      isOnBluetooth = !await agoraEngine.isSpeakerphoneEnabled();
      await agoraEngine.setEnableSpeakerphone(isOnBluetooth);
    }
    setState(() {});
  }

  Future changeAudioState(isMutedMic) async {
    setState(() {
      isMuted = !isMutedMic;
    });
    if(isMutedMic) {
      // if(userMuteDelayTimer != null) {
      //   userMuteDelayTimer!.cancel();
      // }
      await agoraEngine.muteLocalAudioStream(false);
      await agoraEngine.enableLocalAudio(true);
      final event = await reference.orderByChild('id').equalTo(uid).once();

      if(event.snapshot.value != null) {
        Map<dynamic, dynamic> values = event.snapshot.value as Map;
        values.forEach((key, values) async {
          Map<String, dynamic> user = {
            'id': uid,
            'name': await getUserName(),
            'host_name': await getHostName(),
            'host_id': await getHostId(),
            'isMuted': false,
            'Event':'Trigger',
          };
          await reference.child(key).update(user);
        });
      }
      if(isRecording) {
        if(recordingFilePath != '') {
          await agoraEngine.stopAudioRecording();
          repository.uploadUserRecording(recordingFilePath, recordingFileName);
          setState(() {
            recordingFilePath = '';
            recordingFileName = '';
          });
        }
      }
      if(kIsWeb || await Permission.storage.request().isGranted) {
        Future.delayed(Duration(milliseconds: 500)).then((value) async {
          DateTime dateTime = DateTime.now();
          final directory = await getApplicationDocumentsDirectory();
          await Directory("${directory.path}/recordings").create(recursive: true);
          String recordingName = DateFormat('yyyy-MM-dd hh:mm:ss a').format(dateTime);
          File recordingStaticFile = File('${directory.path}/recordings/$recordingName.aac');
          recordingStaticFile.writeAsString('');
          setState(() {
            recordingFilePath = '${directory.path}/recordings/$recordingName.aac';
            recordingFileName = recordingName;
          });

          await agoraEngine.startAudioRecording(
            AudioRecordingConfiguration(
              filePath: '${directory.path}/recordings/$recordingName.aac',
              encode: true,
              fileRecordingType: AudioFileRecordingType.audioFileRecordingMixed,
              quality: AudioRecordingQualityType.audioRecordingQualityHigh,
              sampleRate: 44100,
            ),
          );
        });
        setState(() {
          isRecording = true;
        });
      }
    } else {
      await agoraEngine.muteLocalAudioStream(true);
      await agoraEngine.enableLocalAudio(false);

      // userMuteDelayTimer = Timer(Duration(seconds: 3), () async {
      //   if(!isRecording) {
          final event = await reference.orderByChild('id').equalTo(uid).once();

          if(event.snapshot.value != null) {
            Map<dynamic, dynamic> values = event.snapshot.value as Map;
            values.forEach((key, values) async {
              Map<String, dynamic> user = {
                'id': uid,
                'name': await getUserName(),
                'host_name': await getHostName(),
                'host_id': await getHostId(),
                'isMuted': true,
                'Event2': 'trigger2',
              };
              await reference.child(key).update(user);
            });
          }
      //   }
      // });

      setState(() {});

      if(isRecording) {
        await agoraEngine.stopAudioRecording();
        repository.uploadUserRecording(recordingFilePath, recordingFileName);
        setState(() {
          isRecording = false;
        });
      }
    }
  }

  Future leaveSession() async {
    if(isRecording) {
      await agoraEngine.stopAudioRecording();
      repository.uploadUserRecording(recordingFilePath, recordingFileName);
      setState(() {
        isRecording = false;
      });
    }
    await agoraEngine.leaveChannel();
    await agoraEngine.release();
  }

  initEngine(context) async {

    //create an instance of the Agora engine
    agoraEngine = createAgoraRtcEngine();
    setState(() {});
    await agoraEngine.initialize(RtcEngineContext(
      appId: appId,
    ));

    // await agoraEngine.enableAudioVolumeIndication(interval: 100, smooth: 1, reportVad: true);

    // Register the event handler
    agoraEngine.registerEventHandler(
      RtcEngineEventHandler(

        onJoinChannelSuccess: (RtcConnection connection, int elapsed) async {
          print("Local user uid:${connection.localUid} joined the channel");
          setState(() {
            isJoined = true;
          });
          String name = await getUserName();

          SessionUserDetails? ifHaveAdded = remoteUsers.where((element) => element.id == uid).firstOrNull;
          if(ifHaveAdded == null) {
            //11-02-2023
            setState(() {
              remoteUsers.add(SessionUserDetails(
                id: uid,
                name: name,
                volume: 0,
                isMuted: isMuted,
              ));
            });
          }
           var hostName = await getHostName();
           var hostId = await getHostId();
           var uniqueUserId = '${uid}_${hostId}_${hostName}';

          final event = await reference.orderByChild('uniqueUserId').equalTo(uniqueUserId).once();
          // print('USEHASJOINEDTHECHANNEL');
          //  print(event);
          //  print(event.snapshot);
          //  print(event.snapshot.value);
          // print(event.snapshot.key);
          // print('**********************************************************************************************');

          if(event.snapshot.value == null) {
            Map<String, dynamic> user = {
              'id': uid,
              'name': name,
              'host_name': hostName,
              'host_id': hostId,
              'isMuted': isMuted,
              'uniqueUserId': uniqueUserId,
              'App Version':'5-Latest-Customer',
            };
            await reference.push().set(user);
          }
        },
        onLocalAudioStateChanged: (connection, state, error) {
          if(state == LocalAudioStreamState.localAudioStreamStateRecording) {
            changeAudioState(true);
          } else if(state == LocalAudioStreamState.localAudioStreamStateStopped) {
            changeAudioState(false);
          } else if(state == LocalAudioStreamState.localAudioStreamStateFailed) {
            changeAudioState(false);
          }
        },
        onLeaveChannel: (RtcConnection connection, RtcStats rtcStats) async {
          var hostName = await getHostName();
          var hostId = await getHostId();
          var uniqueUserId = '${uid}_${hostId}_${hostName}';

          final event = await reference.orderByChild('uniqueUserId').equalTo(uniqueUserId).once();
          //  print('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');
          //  print(event);
          //  print(event.snapshot);
          // print(event.snapshot.value);
          // print(event.snapshot.key);
          // print('%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%');

          if(event.snapshot.value != null) {
            Map<dynamic, dynamic> values = event.snapshot.value as Map;
            values.forEach((key, values) async {
              await reference.child(key).remove();
            });
          }
        },
        onAudioRoutingChanged: (int audioRoute) {
          if(audioRoute == 1) {
            setState(() {
              isOnSpeaker = false;
              isOnBluetooth = false;
            });
          } else if(audioRoute == 3) {
            setState(() {
              isOnSpeaker = true;
              isOnBluetooth = false;
            });
          } else if(audioRoute == 5) {
            setState(() {
              isOnSpeaker = false;
              isOnBluetooth = true;
            });
          } else {
            setState(() {
              isOnSpeaker = false;
              isOnBluetooth = false;
            });
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) async {
          print("Remote user uid:$remoteUid joined the channel");

          SessionUserDetails? ifHaveAdded = remoteUsers.where((element) => element.id == remoteUid).firstOrNull;
          if(ifHaveAdded == null){
            String name = await repository.getUserName(remoteUid);
            setState(() {
              remoteUsers.add(SessionUserDetails(
                id: remoteUid,
                name: name,
                volume: 0,
                isMuted: true,
              ));
            });
          }


          //11-02-2023
         // final event = await reference.orderByChild('id').equalTo(remoteUid).once();
          //TILL HERE FROM ABOVE DATE

          //  print('ONUSERJOINED----');
          //   print(event);
          //  print(event.snapshot);
          //  print(event.snapshot.value);
          // print(event.snapshot.key);
          // print('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~');

          //NEW COMMENT // if(event.snapshot.value == null) {
          //   Map<String, dynamic> user = {
          //     'id': remoteUid,
          //     'name': name,
          //     'isMuted': true,
          //   };
          //   await reference.push().set(user);
          // }

          if(remoteUid != hostUserId) {
            await agoraEngine.muteRemoteAudioStream(uid: remoteUid, mute: true);
          }
        },

        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) async {
          print("Remote user uid:$remoteUid left the channel");
          final event = await reference.orderByChild('id').equalTo(remoteUid).once();
          //   print('----------------------------------------------------------------------------------------------------');
          //  print(event);
          //  print(event.snapshot);
          //  print(event.snapshot.value);
          //  print(event.snapshot.key);
          // print('----------------------------------------------------------------------------------------------------');

          if(event.snapshot.value != null) {
            Map<dynamic, dynamic> values = event.snapshot.value as Map;
            values.forEach((key, values) async {
              // await reference.child(key).remove();

            });
          }
          if(remoteUid == hostUserId) {
            await leaveSession();
            Navigator.pushNamed(context, '/Home');
          } else {
            setState(() {
              int userIndex = remoteUsers.indexWhere((user) => user.id == remoteUid);
              if(userIndex != -1) {
                //  remoteUsers.removeAt(userIndex);
              }
            });
          }
        },

        onRemoteAudioStateChanged: (RtcConnection connection, int remoteUid, RemoteAudioState audioState, RemoteAudioStateReason reason, int? elapsed) async {
         // print("Remote user uid:$remoteUid audio state changed with reason $reason");
         //  int userIndex = remoteUsers.indexWhere((user) => user.id == remoteUid);

         // print('////////////////////////////////////////////////////////////////////////////////////////////////////');
         // print(reason);
         // print('////////////////////////////////////////////////////////////////////////////////////////////////////');

          //11-02-2023
          /*if(reason == RemoteAudioStateReason.remoteAudioReasonRemoteOffline) {
            if(userIndex != -1) {
              // remoteUsers.removeAt(userIndex);
              final event = await reference.orderByChild('id').equalTo(remoteUid).once();

              if(event.snapshot.value != null) {
                Map<dynamic, dynamic> values = event.snapshot.value as Map;
                values.forEach((key, values) async {
                  //await reference.child(key).remove();
                  await reference.child(key).update;
                });
              }
            }
          }*/
          //TILL HERE FROM ABOVE DATE

          if(remoteUid != hostUserId && remoteUid != uid) {
            await agoraEngine.muteRemoteAudioStream(uid: remoteUid, mute: true);
          }
          setState(() {});
        },

        /* onConnectionLost:(RtcConnection connection) async{ await leaveSession();
        Navigator.pushNamed(context, '/Home');
        },

        onConnectionInterrupted: (RtcConnection connection) async{ await leaveSession();
        Navigator.pushNamed(context, '/Home');
        },*/

        /*onAudioVolumeIndication: (RtcConnection connection, List<AudioVolumeInfo> speakers, int speakerNumber, int totalVolumed) { //int totalVolume
          // debugPrint('onAudioVolumeIndication $uid');
          _handleOnAudioVolumeIndication(connection, speakers, speakerNumber, totalVolumed);
          //core logic will be here
        },*/
      ),
    );
  }

/*void _handleOnAudioVolumeIndication(RtcConnection connection, List<AudioVolumeInfo> speakers, int speakerNumber, int totalVolumed) async {
    speakers.forEach((speaker) async {
      //detecting speaking person whose volume more than 5
      if (speaker.volume! > 2) {
        try {
          //  Highlighting local user
          //  In this callback, the local user is represented by an uid of 0.

          print('------------------------------------------------------------------------------------------------');
          print(speaker.uid);
          print(speaker.volume);
          int speakerIndex = remoteUsers.indexWhere((element) => element.id == (speaker.uid == 0 ? uid : speaker.uid));
          if(speakerIndex != -1) {

            final event = await reference.orderByChild('id').equalTo(speaker.uid == 0 ? uid : speaker.uid).once();

            if(event.snapshot.value != null) {
              Map<dynamic, dynamic> values = event.snapshot.value as Map;
              values.forEach((key, values) async {
                Map<String, dynamic> user = {
                  'id': remoteUsers[speakerIndex].id,
                  'name': remoteUsers[speakerIndex].name,
                  'host_name': await getHostName(),
                  'volume': speaker.volume,
                  'isMuted': false,
                };
                await reference.child(key).update(user);
                print(key);
              });
            }
          }
        } catch (error) {
          print('===============================================================================');
          print(error.toString());
          print('===============================================================================');
        }
      }
    });

    Future.delayed(Duration(seconds: 3)).then((value) {
      remoteUsers.map((e) async {
        final event = await reference.orderByChild('id').equalTo(e.id).once();

        if(event.snapshot.value != null) {
          Map<dynamic, dynamic> values = event.snapshot.value as Map;
          values.forEach((key, values) async {
            Map<String, dynamic> user = {
              'id': e.id,
              'name': e.name,
              'host_name': await getHostName(),
              'volume': 0,
              'isMuted': false,
            };
            await reference.child(key).update(user);
          });
        }
      });
    });
    notifyListeners();
  }*/
}