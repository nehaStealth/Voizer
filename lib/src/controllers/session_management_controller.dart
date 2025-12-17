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

  // Debounce timer for Firebase writes
  Timer? _micUpdateTimer;

  Future<void> changeAudioState(bool isMutedMic) async {
    final userId = uid;
    final name = await getUserName();
    final hostName = await getHostName();
    final hostId = await getHostId();
    final uniqueUserId = '${userId}_${hostId}_${hostName}';

    // -----------------------------
    // 🔹 UNMUTE (User starts speaking)
    // -----------------------------
    if (isMutedMic) {
      if (isRecording) return; // Guard against multiple calls

      setState(() => isMuted = false);

      await agoraEngine.muteLocalAudioStream(false);
      await agoraEngine.enableLocalAudio(true);

      try {
        await agoraEngine.setAudioProfile(
          profile: AudioProfileType.audioProfileSpeechStandard,
          scenario: AudioScenarioType.audioScenarioChatroom,
        );

        await agoraEngine.setParameters(
            '{"rtc.audio.aec.enable":true,"rtc.audio.ans.enable":true,"rtc.audio.agc.enable":true}');

        await agoraEngine.setParameters(
            '{"che.audio.ai_noise_suppression":{"enable":true,"mode":2}}');
      } catch (_) {}

      // 🔥 Update Firebase with debounce (300ms)
      _micUpdateTimer?.cancel();
      _micUpdateTimer = Timer(const Duration(milliseconds: 300), () async {
        await _updateUserMuteStatus(
          userId: userId,
          name: name,
          hostId: hostId,
          hostName: hostName,
          uniqueUserId: uniqueUserId,
          isMuted: false,
        );
      });

      // -----------------------------
      // 🎙 START Recording
      // -----------------------------
      if (!await _requestRecordingPermissions()) {
        debugPrint("Recording permission denied");
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      await Directory("${directory.path}/recordings").create(recursive: true);

      DateTime dt = DateTime.now();
      recordingFileName = DateFormat('yyyy-MM-dd hh:mm:ss a').format(dt);
      recordingFilePath = '${directory.path}/recordings/$recordingFileName.aac';

      await agoraEngine.startAudioRecording(
        AudioRecordingConfiguration(
          filePath: recordingFilePath,
          encode: true,
          fileRecordingType: AudioFileRecordingType.audioFileRecordingMixed,
          quality: AudioRecordingQualityType.audioRecordingQualityHigh,
          sampleRate: 44100,
        ),
      );

      setState(() => isRecording = true);
      return;
    }

    // -----------------------------
    // 🔹 MUTE (User stops speaking)
    // -----------------------------
    if (!isRecording) {
      // User muted without recording → basic mute
      setState(() => isMuted = true);
      await agoraEngine.muteLocalAudioStream(true);
      await agoraEngine.enableLocalAudio(false);

      // Update Firebase debounce
      _micUpdateTimer?.cancel();
      _micUpdateTimer = Timer(const Duration(milliseconds: 300), () async {
        await _updateUserMuteStatus(
          userId: userId,
          name: name,
          hostId: hostId,
          hostName: hostName,
          uniqueUserId: uniqueUserId,
          isMuted: true,
        );
      });
      return;
    }

    // Full mute + stop recording
    setState(() => isMuted = true);

    await agoraEngine.muteLocalAudioStream(true);
    await agoraEngine.enableLocalAudio(false);

    // Firebase update
    _micUpdateTimer?.cancel();
    _micUpdateTimer = Timer(const Duration(milliseconds: 300), () async {
      await _updateUserMuteStatus(
        userId: userId,
        name: name,
        hostId: hostId,
        hostName: hostName,
        uniqueUserId: uniqueUserId,
        isMuted: true,
      );
    });

    // Stop recording & upload
    await _stopRecordingAndUpload();
  }

  Future<bool> _requestRecordingPermissions() async {
    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      final mic = await Permission.microphone.request();
      final audio = await Permission.audio.request();

      // Android 13+
      if (await Permission.manageExternalStorage.isDenied) {
        await Permission.manageExternalStorage.request();
      }

      return mic.isGranted && audio.isGranted;
    }

    // iOS
    final mic = await Permission.microphone.request();
    return mic.isGranted;
  }

// -------------------------------------------------------------
// 🔥 New helper: Safe Firebase update with fallback + no forEach
// -------------------------------------------------------------
  Future<void> _updateUserMuteStatus({
    required int userId,
    required String name,
    required int hostId,
    required String hostName,
    required String uniqueUserId,
    required bool isMuted,
  }) async {
    final snap = await reference
        .orderByChild('uniqueUserId')
        .equalTo(uniqueUserId)
        .once();

    // CREATE record if missing
    if (snap.snapshot.value == null) {
      await reference.push().set({
        'id': userId,
        'name': name,
        'host_name': hostName,
        'host_id': hostId,
        'isMuted': isMuted,
        'uniqueUserId': uniqueUserId,
      });
      return;
    }

    // UPDATE existing record
    final Map data = snap.snapshot.value as Map;
    for (final key in data.keys) {
      await reference.child(key).update({
        'isMuted': isMuted,
      });
    }
  }

  // Future<void> changeAudioState(bool isMutedMic) async {
  //   ///  UNMUTE (User starts speaking)
  //   if (isMutedMic) {
  //     // Already unmuted & recording → do nothing
  //     if (isRecording) return;

  //     setState(() {
  //       isMuted = false;
  //     });

  //     await agoraEngine.muteLocalAudioStream(false);

  //     await agoraEngine.enableLocalAudio(true);

  //      try {
  //     // 1) Set audio profile & scenario (these are named parameters)
  //     await agoraEngine.setAudioProfile(
  //       profile: AudioProfileType.audioProfileSpeechStandard,
  //       scenario: AudioScenarioType.audioScenarioChatroom,
  //     );
  //     await agoraEngine.setParameters(
  //       '{"rtc.audio.aec.enable":true,'
  //       '"rtc.audio.ans.enable":true,'
  //       '"rtc.audio.agc.enable":true}'
  //     );
  //     await agoraEngine.setParameters(
  //       '{"che.audio.ai_noise_suppression": {"enable":true, "mode":2}}'
  //     );

  //     debugPrint("Audio profile and noise suppression set");
  //   } catch (e) {
  //     // safe fallback: log but continue — your original flow will still work
  //     debugPrint("Could not fully configure noise suppression: $e");
  //   }

  //     // Update Firebase
  //     final event = await reference.orderByChild('id').equalTo(uid).once();
  //     if (event.snapshot.value != null) {
  //       final Map<dynamic, dynamic> values =
  //           event.snapshot.value as Map<dynamic, dynamic>;

  //       for (final key in values.keys) {
  //        await reference.child(key).update({
  //           'id': uid,
  //           'name': await getUserName(),
  //           'host_name': await getHostName(),
  //           'host_id': await getHostId(),
  //           'isMuted': false,
  //           'Event': 'Trigger',
  //         });

  //       }

  //     }

  //     // Permission check
  //     if (!(kIsWeb || await Permission.storage.request().isGranted)) return;

  //     DateTime dateTime = DateTime.now();
  //     final directory = await getApplicationDocumentsDirectory();
  //     await Directory("${directory.path}/recordings").create(recursive: true);
  //     recordingFileName = DateFormat('yyyy-MM-dd hh:mm:ss a').format(dateTime);
  //     recordingFilePath = '${directory.path}/recordings/$recordingFileName.aac';
  //     setState(() {
  //       recordingFilePath =
  //           '${directory.path}/recordings/$recordingFileName.aac';
  //       recordingFileName = recordingFileName;
  //     });

  //     debugPrint('Recording started → $recordingFileName');

  //     await agoraEngine.startAudioRecording(
  //       AudioRecordingConfiguration(
  //         filePath: recordingFilePath,
  //         encode: true,
  //         fileRecordingType: AudioFileRecordingType.audioFileRecordingMixed,
  //         quality: AudioRecordingQualityType.audioRecordingQualityHigh,
  //         sampleRate: 44100,
  //       ),
  //     );

  //     setState(() {
  //       isRecording = true;
  //     });
  //   }

  //   // MUTE (User stops speaking)
  //   else {
  //     if (!isRecording) {
  //       // User muted without recording
  //       setState(() => isMuted = true);
  //       await agoraEngine.muteLocalAudioStream(true);
  //       await agoraEngine.enableLocalAudio(false);
  //       return;
  //     }

  //     setState(() {
  //       isMuted = true;
  //     });

  //     await agoraEngine.muteLocalAudioStream(true);
  //     await agoraEngine.enableLocalAudio(false);

  //     // Update Firebase
  //     final event = await reference.orderByChild('id').equalTo(uid).once();

  //     if (event.snapshot.value != null) {
  //       final Map<dynamic, dynamic> values =
  //           event.snapshot.value as Map<dynamic, dynamic>;

  //       for (final key in values.keys) {
  //         await reference.child(key).update({
  //           'id': uid,
  //           'name': await getUserName(),
  //           'host_name': await getHostName(),
  //           'host_id': await getHostId(),
  //           'isMuted': true,
  //           'Event2': 'trigger2',
  //         });
  //       }
  //     }
  //     // Stop & upload current recording
  //     await _stopRecordingAndUpload();
  //   }
  // }

  // Helper function moved to class level
  Future<void> _stopRecordingAndUpload() async {
    if (!_isRecordingInProgress && !isRecording) {
      debugPrint('Upload skipped (guard) - No active recording');
      return;
    }
    _isRecordingInProgress = true;
    try {
      debugPrint('Recording stopped');
      await agoraEngine.stopAudioRecording();

      if (recordingFilePath.isEmpty) return;

      final file = File(recordingFilePath);

// ⏳ wait until Agora flushes file
      await Future.delayed(const Duration(milliseconds: 500));

      if (!file.existsSync()) {
        debugPrint('Recording file not found');
        return;
      }

      if (file.lengthSync() < 1024) {
        debugPrint('Recording file too small, skipping upload');
        return;
      }

      await repository.uploadUserRecording(
          recordingFilePath, recordingFileName);
      debugPrint('Upload succeeded - $recordingFileName');

      // if (recordingFilePath.isNotEmpty &&
      //     File(recordingFilePath).existsSync()) {
      //   debugPrint('Upload started - $recordingFileName');
      //   await repository.uploadUserRecording(
      //       recordingFilePath, recordingFileName);
      //   debugPrint('Upload succeeded - $recordingFileName');
      // }

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
            // if (isRecording) {
            //   debugPrint('Agora audio stopped unexpectedly');
            //   _stopRecordingAndUpload();
            //   setState(() => isRecording = false);
            // }
            if (state == LocalAudioStreamState.localAudioStreamStateStopped &&
                isRecording &&
                !isMuted) {
              debugPrint('Audio stopped unexpectedly, forcing cleanup');
              _stopRecordingAndUpload();
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
