import 'dart:async';
import 'dart:io';
import 'package:agora_calling_app/src/models/session_user_model.dart';
import 'package:agora_calling_app/src/repositories/session_repository.dart'
    as repository;
import 'package:agora_calling_app/src/services/auth_service.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class SessionManagementController extends ControllerMVC {
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController muteCon = TextEditingController();
  FocusNode muteFocus = FocusNode();
  bool isJoined = false;
  bool isMuted = true;
  bool isOnSpeaker = true;
  bool isOnBluetooth = true;
  bool isRecording = false;
  bool _isRecordingInProgress = false; // Prevents race condition
  bool isUserHoldButton = false;
  String appId = "";
  String channelName = "";
  String token = "";
  String recordingFilePath = '';
  String recordingFileName = '';
  String userName = '';
  int uid = 0;
  int hostUserId = 0;
  List<SessionUserDetails> remoteUsers = [];
  late RtcEngine agoraEngine;
  bool isBluetoothCheckingOn = false;

  DatabaseReference reference =
      FirebaseDatabase.instance.ref().child('Active Users');

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

    if (await Permission.microphone.request().isGranted) {
      setState(() {
        isMuted = true;
      });
      await agoraEngine.muteLocalAudioStream(true);
      await agoraEngine.enableLocalAudio(false);
    }

    await agoraEngine.setAudioProfile(
      profile: AudioProfileType.audioProfileMusicHighQualityStereo,
      scenario: AudioScenarioType.audioScenarioChatroom,
    );

    debugPrint('Session joined');
  }

  Future changeVolumeBroadcasting() async {
    isOnSpeaker = !await agoraEngine.isSpeakerphoneEnabled();
    await agoraEngine.setEnableSpeakerphone(isOnSpeaker);
    setState(() {});
  }

  Future changeVolumeBroadcastingToBluetooth() async {
    if (await Permission.bluetooth.request().isGranted) {
      isOnBluetooth = !await agoraEngine.isSpeakerphoneEnabled();
      await agoraEngine.setEnableSpeakerphone(isOnBluetooth);
    }
    setState(() {});
  }

  Future<void> changeAudioState(bool isMutedMic) async {
    ///  UNMUTE (User starts speaking) 
    if (isMutedMic) {
      // Already unmuted & recording → do nothing
      if (isRecording) return;

      setState(() {
        isMuted = false;
      });

      await agoraEngine.muteLocalAudioStream(false);
      await agoraEngine.enableLocalAudio(true);

      // Update Firebase
      final event = await reference.orderByChild('id').equalTo(uid).once();
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> values =
            event.snapshot.value as Map<dynamic, dynamic>;

        for (final key in values.keys) {
          await reference.child(key).update({
            'id': uid,
            'name': await getUserName(),
            'host_name': await getHostName(),
            'host_id': await getHostId(),
            'isMuted': false,
            'Event': 'Trigger',
          });
        }
      }

      // Permission check
      if (!(kIsWeb || await Permission.storage.request().isGranted)) return;

      DateTime dateTime = DateTime.now();
      final directory = await getApplicationDocumentsDirectory();
      await Directory("${directory.path}/recordings").create(recursive: true);
      recordingFileName = DateFormat('yyyy-MM-dd hh:mm:ss a').format(dateTime);
      recordingFilePath = '${directory.path}/recordings/$recordingFileName.aac';
      setState(() {
        recordingFilePath =
            '${directory.path}/recordings/$recordingFileName.aac';
        recordingFileName = recordingFileName;
      });

      debugPrint('Recording started → $recordingFileName');

      await agoraEngine.startAudioRecording(
        AudioRecordingConfiguration(
          filePath: recordingFilePath,
          encode: true,
          fileRecordingType: AudioFileRecordingType.audioFileRecordingMixed,
          quality: AudioRecordingQualityType.audioRecordingQualityHigh,
          sampleRate: 44100,
        ),
      );

      setState(() {
        isRecording = true;
      });
    }

    // MUTE (User stops speaking) 
    else {
      if (!isRecording) {
        // User muted without recording
        setState(() => isMuted = true);
        await agoraEngine.muteLocalAudioStream(true);
        await agoraEngine.enableLocalAudio(false);
        return;
      }

      setState(() {
        isMuted = true;
      });

      await agoraEngine.muteLocalAudioStream(true);
      await agoraEngine.enableLocalAudio(false);

      // Update Firebase
      final event = await reference.orderByChild('id').equalTo(uid).once();
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> values =
            event.snapshot.value as Map<dynamic, dynamic>;

        for (final key in values.keys) {
          await reference.child(key).update({
            'isMuted': true,
            'Event2': 'trigger2',
          });
        }
      }

      // Stop & upload current recording
      await _stopRecordingAndUpload();
    }
  }

  // Helper function moved to class level
  Future<void> _stopRecordingAndUpload() async {
    if (!_isRecordingInProgress && !isRecording) {
      debugPrint('Upload skipped (guard) - No active recording');
      return;
    }

    try {
      debugPrint('Recording stopped');
      await agoraEngine.stopAudioRecording();

      if (recordingFilePath.isNotEmpty &&
          File(recordingFilePath).existsSync()) {
        debugPrint('Upload started - $recordingFileName');
        await repository.uploadUserRecording(
            recordingFilePath, recordingFileName);
        debugPrint('Upload succeeded - $recordingFileName');
      }

      setState(() {
        isRecording = false;
        recordingFilePath = '';
        recordingFileName = '';
      });
    } catch (e) {
      debugPrint('Upload failed or skipped: $e');
    } finally {
      _isRecordingInProgress = false; // Critical: unlock
    }
  }

  Future leaveSession() async {
    debugPrint('Session left');

    if (isRecording || _isRecordingInProgress) {
      await _stopRecordingAndUpload();
    }

    await agoraEngine.leaveChannel();
    await agoraEngine.release();
  }

  initEngine(context) async {
    agoraEngine = createAgoraRtcEngine();
    setState(() {});
    await agoraEngine.initialize(RtcEngineContext(appId: appId));

    agoraEngine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) async {
          debugPrint('Session joined');
          setState(() => isJoined = true);

          String name = await getUserName();
          if (!remoteUsers.any((u) => u.id == uid)) {
            remoteUsers.add(SessionUserDetails(
              id: uid,
              name: name,
              volume: 0,
              isMuted: isMuted,
            ));
            setState(() {});
          }

          var hostName = await getHostName();
          var hostId = await getHostId();
          var uniqueUserId = '${uid}_${hostId}_${hostName}';

          final event = await reference
              .orderByChild('uniqueUserId')
              .equalTo(uniqueUserId)
              .once();

          if (event.snapshot.value == null) {
            await reference.push().set({
              'id': uid,
              'name': name,
              'host_name': hostName,
              'host_id': hostId,
              'isMuted': isMuted,
              'uniqueUserId': uniqueUserId,
              'App Version': '5-Latest-Customer',
            });
          }
        },
        onLocalAudioStateChanged: (connection, state, error) {
          if (state == LocalAudioStreamState.localAudioStreamStateStopped ||
              state == LocalAudioStreamState.localAudioStreamStateFailed) {
            if (isRecording) {
              debugPrint('Agora audio stopped unexpectedly');
              _stopRecordingAndUpload();
              setState(() => isRecording = false);
            }
          }
        },
        onLeaveChannel: (RtcConnection connection, RtcStats rtcStats) async {
          var hostName = await getHostName();
          var hostId = await getHostId();
          var uniqueUserId = '${uid}_${hostId}_${hostName}';

          final event = await reference
              .orderByChild('uniqueUserId')
              .equalTo(uniqueUserId)
              .once();

          if (event.snapshot.value != null) {
            Map<dynamic, dynamic> values = event.snapshot.value as Map;
            values.forEach((key, values) async {
              await reference.child(key).remove();
            });
          }
        },
        onAudioRoutingChanged: (int route) {
          setState(() {
            isOnSpeaker = route == 3;
            isOnBluetooth = route == 5;
          });
        },
        onUserJoined: (connection, remoteUid, elapsed) async {
          debugPrint("Remote user uid:$remoteUid joined the channel");

          if (!remoteUsers.any((u) => u.id == remoteUid)) {
            String name = await repository.getUserName(remoteUid);
            remoteUsers.add(SessionUserDetails(
                id: remoteUid, name: name, volume: 0, isMuted: true));
            setState(() {});
          }

          if (remoteUid != hostUserId) {
            await agoraEngine.muteRemoteAudioStream(uid: remoteUid, mute: true);
          }
        },
        onUserOffline: (connection, remoteUid, reason) async {
          debugPrint("Remote user uid:$remoteUid left the channel");

          if (remoteUid == hostUserId) {
            await leaveSession();
            Navigator.pushNamed(context, '/Home');
          } else {
            remoteUsers.removeWhere((u) => u.id == remoteUid);
            setState(() {});
          }
        },
        onRemoteAudioStateChanged:
            (connection, remoteUid, state, reason, elapsed) {
          if (remoteUid != hostUserId && remoteUid != uid) {
            agoraEngine.muteRemoteAudioStream(uid: remoteUid, mute: true);
          }
          setState(() {});
        },
      ),
    );
  }
}
