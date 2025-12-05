import 'dart:convert';
import 'dart:developer';
import 'dart:io';


import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:agora_calling_app/src/repositories/session_repository.dart' as repository;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../helpers/global.dart';
import '../services/auth_service.dart';
import 'home_controller.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';


class CustomerLiveKitController extends HomeController {
  GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  Room? room;
  final Map<String, RemoteParticipant> remoteParticipants = {};
  bool _hasJoinPermission = false;
  bool isMicOn = false;
  bool isMutedVisual = false;
  DatabaseReference reference = FirebaseDatabase.instance.ref().child('Active Users');
  VoidCallback? onParticipantsUpdated;

  String? _hostIdentityResolved;
  String? hostUserId;
  String? hostId;
  bool isSpeaking = false;

  bool isOnSpeaker = true;
  bool isOnBluetooth = false;   // true -> bluetooth headset

  FlutterSoundRecorder? _recorder;
  bool isRecording = false;
  String recordingFilePath = '';
  String recordingFileName = '';

  // 👇 Add a callback for messages
  Function(String, String)? onMessageReceived;


  Future<void> publishAudioForHostOnly(Room room, String hostIdentity) async {

    print('print&hos: $hostIdentity');
    final local = room.localParticipant;
    if (local == null) return;

    // Restrict permissions
    local.setTrackSubscriptionPermissions(
      allParticipantsAllowed: false,
      trackPermissions: [
        ParticipantTrackPermission(
          hostIdentity, // ✔ only the host
          true,         // ✔ host CAN subscribe to client's audio
          null,         // ✔ allow all client tracks
        )
      ],
    );

    print("🎤 Client audio -> Host only");

  }



  LocalParticipant? get localParticipant => room?.localParticipant;
  List<RemoteParticipant> get remoteParticipantsList =>
      remoteParticipants.values.toList();

  Future<void> toggleMicrophone() async {
    final p = room?.localParticipant;
    if (p != null) {
      final newState = !(p.isMicrophoneEnabled == true);
      await p.setMicrophoneEnabled(newState);
    }
  }

  Future<void> disconnect() async {
    await room?.disconnect();
    room = null;
    remoteParticipants.clear();
    _hasJoinPermission = false;
    onParticipantsUpdated?.call();
  }


    Future<void> leaveRoom(String identity) async {
      try {
        // ✅ Notify your backend or Firebase that the user has left
        await leaveSession(identity);
      } catch (e) {
        debugPrint('⚠️ Failed to notify backend: $e');
      }

      try {
        // ✅ Disconnect gracefully from LiveKit
        await room?.disconnect();
      } catch (e) {
        debugPrint('⚠️ LiveKit disconnect error: $e');
      }

      try {
        // ✅ Dispose the old room to remove event listeners
        await room?.dispose();
      } catch (e) {
        debugPrint('⚠️ Room dispose error: $e');
      }

      // ✅ Clear everything locally
      room = null;
      remoteParticipants.clear();
      _hasJoinPermission = false;

      // ✅ Trigger UI update if needed
      onParticipantsUpdated?.call();

      debugPrint('🧹 Room and participants fully cleared after leaving.');
    }


    Future<bool> leaveSession(String identity) async {
      String accessToken = await getToken();
      String roomId = await getLiveKitRoomId();

      print("leaveSession -> accessToken: $accessToken");
      print("leaveSession -> roomId: $roomId");
      print("leaveSession -> identity: $identity");

      try {
        if (accessToken.isEmpty) return false;

        final url = Uri.parse("$baseUrl/rooms/$roomId/livekit-kick-out-user");

        // ✅ Request body
        Map<String, dynamic> body = {
          'identity': identity,
        };

        final response = await http.post(
          url,
          headers: {
            HttpHeaders.acceptHeader: 'application/json',
            HttpHeaders.contentTypeHeader: 'application/json',
            HttpHeaders.authorizationHeader: 'Bearer $accessToken',
          },
          // ✅ Send the body properly
          body: jsonEncode(body),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          print("leaveSession success: $data");
          return data['success'] == true;
        } else {
          print("HTTP error leaveSession: ${response.statusCode}, body: ${response.body}");
          return false;
        }
      } catch (e) {
        print("Exception in leaveSession: $e");
        return false;
      }
    }


  Future<String?> fetchHostIdentityApi() async {
    String accessToken = await getToken();

    try {
      final url = Uri.parse(fetchHostIdentityURL);
      final response = await http.get(
        url,
        headers: {
          HttpHeaders.acceptHeader: 'application/json',
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader: 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == true && data['hosts'] != null && data['hosts'].isNotEmpty) {
          final loginId = data['hosts'][0]['login_id'];
          await saveHostIdentity(loginId);
          print("Saved host login_id: $loginId");
          return loginId;
        } else {
          print("API failed: ${data['message']}");
          return null;
        }
      } else {
        print("HTTP error: ${response.statusCode}, body: ${response.body}");
        return null;
      }
    } catch (e) {
      print("Exception while fetching host identity: $e");
      return null;
    }
  }



  Future<void> initRecorder() async {
    print("🎙️ initRecorder called");
    try {
      _recorder = FlutterSoundRecorder();

      if (!kIsWeb) {
        var status = await Permission.microphone.status;
        print("🎧 Microphone permission status: $status");
        if (!status.isGranted) {
          status = await Permission.microphone.request();
          print("🎧 Microphone permission request result: $status");
          if (!status.isGranted) {
            print("❌ Microphone permission denied, cannot open recorder");
            return;
          }
        }
      }

      print("⏳ Opening recorder...");
      await _recorder!.openRecorder();
      print("✅ Recorder opened successfully");

      await _recorder!.setSubscriptionDuration(const Duration(milliseconds: 100));
      print("🎙️ Recorder initialized and ready");
    } catch (e, st) {
      print("❌ initRecorder ERROR: $e");
      print(st);
    }
  }

  Future<void> startRecording(String filePath, Codec codec, String fileName) async {
    try {
      print("⏳ Starting recording: $filePath, codec: $codec");
      await _recorder!.startRecorder(toFile: filePath, codec: codec);
      print("📝 Recording started successfully");
      isRecording = true;
      recordingFilePath = filePath;
      recordingFileName = fileName; // ✅ Store name too
    } catch (e, st) {
      print("❌ startRecording ERROR: $e");
      print(st);
    }
  }

  Future<void> stopRecording() async {
    try {
      print("⏳ Stopping recorder...");
      await _recorder?.stopRecorder();
      isRecording = false;
      print("🛑 Recording stopped successfully: $recordingFilePath");

      if (recordingFilePath.isNotEmpty && recordingFileName.isNotEmpty) {
        await repository.uploadUserRecording(recordingFilePath, recordingFileName);

        print("✅ Upload completed!");
      }

      // ✅ Reset file tracking
      recordingFilePath = '';
      recordingFileName = '';
    } catch (e, st) {
      print("❌ stopRecording ERROR: $e");
      print(st);
    }
  }

  Future<void> disposeRecorder() async {
    await _recorder?.closeRecorder();
    _recorder = null;
  }


  Future<void> changeAudioStateLiveKit(bool unmute) async {
    print("🔥 changeAudioStateLiveKit called with unmute=$unmute");

    if (room == null) {
      print("⚠️ room is null, returning early");
      return;
    }
    final local = room!.localParticipant;
    if (local == null) {
      print("⚠️ localParticipant is null, returning early");
      return;
    }
    print("✅ localParticipant found: ${local.identity}");


    final uid = await getUserId(); // always app user ID like 315
    final userName = await getUserLoginIdName();

    // ✅ fetch the actual HOST ID and HOST NAME from your saved session (not from local.sid)
    final hostId = await getHostId(); // store this when host starts session// store this when host starts session
    final hostName = await getHostLoginId();

    print("print new uid : $uid");
    print("print new userName : $userName");
    print("print new hostName : $hostName");
    print("print new hostId : $hostId");

    if (uid.toString().startsWith('PA_')) {
      debugPrint('🚫 Skipping invalid LiveKit ID ($uid) — not updating Firebase');
      return;
    }

    // 🔹 Fire-and-forget Firebase update
    updateFirebaseAudioState(
      unmute,
      name: userName,
      hostId: hostId,
      hostName: hostName,
    ).then((_) {
      print("✅ updateFirebaseAudioState completed!");
    }).catchError((e) {
      print("❌ Firebase error: $e");
    });


    // -------------------------------------------------------------------------------------
    // 🔥 2) MICROPHONE CONTROL + HOST-ONLY MICROPHONE PUBLISHING
    // -------------------------------------------------------------------------------------

    try {
      if (unmute) {
        //await local.setMicrophoneEnabled(true);

        await local.setMicrophoneEnabled(
          true,
          audioCaptureOptions: AudioCaptureOptions(
            echoCancellation: true,
            noiseSuppression: true,
            autoGainControl: true,
          ),
        );

        // 🔥 Only CLIENTS restrict audio
        if (uid.toString() != hostId.toString()) {
          await publishAudioForHostOnly(room!, hostName);
        }

        print("🎤 Microphone ENABLED for $uid");
      } else {
        await local.setMicrophoneEnabled(false);
        print("🔇 Mic DISABLED");
      }
    } catch (e) {
      print("❌ LiveKit mic error: $e");
    }


    // -------------------------------------------------------------------------------------
    // 🔥 3) RECORDING LOGIC (unchanged)
    // -------------------------------------------------------------------------------------

    try {
      // Enable/disable mic immediately
      await local.setMicrophoneEnabled(unmute);
      print(unmute ? "🎤 Mic ENABLED" : "🎤 Mic DISABLED");

      if (unmute) {
        print("🎙️ Preparing to start recording...");

        if (_recorder == null) {
          print("❌ Recorder not initialized! Call initRecorder() first.");
          return;
        }

        if (isRecording) {
          print("⏹️ Stopping previous recording...");
          await stopRecording();
        }

        final directory = await getApplicationDocumentsDirectory();
        await Directory("${directory.path}/recordings").create(recursive: true);

        final now = DateTime.now();
        final name = DateFormat('yyyy-MM-dd hh:mm:ss a').format(now);
        final filePath = '${directory.path}/recordings/$name.aac';

        final codec = kIsWeb ? Codec.opusWebM : Codec.aacADTS;

        print("🎬 Starting recording at: $filePath");
        await startRecording(filePath, codec , name);
        print("✅ Recording started!");
      } else {
        print("⏹️ Stopping recording...");
        if (_recorder != null && isRecording) {
          await stopRecording();
          print("✅ Recording stopped!");
        }
      }
    } catch (e, st) {
      print("❌ Error in changeAudioStateLiveKit: $e");
      print(st);
    }
  }


  Future<void> updateFirebaseAudioState(
      bool unmute, {
        String? name,
        int? hostId,
        String? hostName,
      }) async {
    final safeName = (name ?? await getUserName() ?? 'unknown').toString();
    final safeHostId = hostId ?? 'host';
    final safeHostName = hostName ?? 'host';

    final bool newIsMuted = !unmute;
    final bool isSpeaking = unmute;

    final userPath = "Active Users/client_$name";
    final userRef = FirebaseDatabase.instance.ref(userPath);

    try {
      final snapshot = await userRef.get();

      if (snapshot.exists) {
        final existing = snapshot.value as Map;
        final oldIsSpeaking = existing['isSpeaking'] ?? false;

        // ✅ Only update if speaking state changed
        if (oldIsSpeaking != isSpeaking) {
          await userRef.update({
            'isMuted': newIsMuted,
            'isSpeaking': isSpeaking,
            'lastTouched': ServerValue.timestamp,
          });
          debugPrint('🔄 Updated speaking state for $name: $isSpeaking');
        } else {
          debugPrint('⏸ No speaking change for $name');
        }
      } else {
        // If node doesn't exist, create it
        await userRef.set({
          'name': safeName,
          'hostId': safeHostId,
          'hostName': safeHostName,
          'isMuted': newIsMuted,
          'isSpeaking': isSpeaking,
          'joinedAt': DateTime.now().millisecondsSinceEpoch,
          'lastTouched': ServerValue.timestamp,
          'App Version': '1.0.5',
        });
        debugPrint('Created new user node for $name');
      }
    } catch (e, st) {
      debugPrint('❌ Firebase update error: $e\n$st');
    }
  }


  /// Toggle between speakerphone and earpiece
  Future<void> changeVolumeBroadcasting() async {
    isOnSpeaker = !isOnSpeaker;

    if (isOnSpeaker) {
      isOnBluetooth = false; // speaker overrides Bluetooth
      await Helper.setSpeakerphoneOn(true);
    } else {
      // route back to earpiece; Bluetooth may take over if connected
      await Helper.setSpeakerphoneOn(false);
    }
  }


  /// Toggle Bluetooth routing
  Future<void> changeVolumeBroadcastingToBluetooth() async {
    isOnBluetooth = !isOnBluetooth;

    if (isOnBluetooth) {
      // Turn off speaker so Bluetooth is used automatically
      isOnSpeaker = false;
      await Helper.setSpeakerphoneOn(false);
    } else {
      // If turning off Bluetooth, go back to speaker
      isOnSpeaker = true;
      await Helper.setSpeakerphoneOn(true);
    }
  }

}