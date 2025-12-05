import 'dart:convert';
import 'dart:developer';
import 'package:agora_calling_app/src/services/auth_service.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart' hide ConnectionState;
import 'package:flutter_sound/public/flutter_sound_recorder.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:http/http.dart' as http;
import 'package:livekit_client/livekit_client.dart';

import '../controllers/livekitcustomer_controller.dart';

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

// file: lib/pages/customer_livekit_page.dart

import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

import '../helpers/global.dart';
import '../helpers/texts.dart';
import '../widget/chat_listview.dart';
import '../widget/colors.dart';
import '../widget/custom_alert.dart';
import '../widget/custom_app_bar.dart';
import '../widget/custom_bottom_bar.dart';
import '../widget/custom_button.dart';
import '../widget/dimensions.dart';
import '../widget/style.dart';


class CustomerLiveKitPage extends StatefulWidget {
  final String url; // livekit ws url, e.g. wss://...
  final String token; // per-device token
  final String? roomId;
  final String? hostIdentity; // optional; if null, will call backend
  final String? authToken; // optional, for backend API calls

  const CustomerLiveKitPage({
    Key? key,
    required this.url,
    required this.token,
    required this.roomId,
    this.hostIdentity,
    this.authToken,
  }) : super(key: key);

  @override
  State<CustomerLiveKitPage> createState() => _CustomerLiveKitPageState();
}

class _CustomerLiveKitPageState extends State<CustomerLiveKitPage> {
  final CustomerLiveKitController controller = CustomerLiveKitController();

  Room? _room;
  bool _isConnected = true;
  bool isMicOn = false;
  bool _isUserHolding = false;
  bool _isMutedVisual = false;
  String _userMessage = '';

  int notificationCount = 0; // Badge count
  final Map<String, RemoteParticipant> _remoteParticipants = {};
  final List<Map<String, String>> _messages = [];
  final TextEditingController _msgController = TextEditingController();
  String? _hostIdentityResolved;
  int _currentSessionId = 0;

  @override
  void initState() {
    super.initState();
    // Initialize LiveKit controller recorder
    // Delay init to ensure context & permissions ready
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await controller.initRecorder();
    });

    _connectToRoom();

    // Subscribe to host messages topic
    FirebaseMessaging.instance.subscribeToTopic("livekit_clients");


    // Foreground messages (in-app)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final body = message.notification?.body ?? '';
      final title = message.notification?.title ?? 'Host Message';

      if (!mounted) return;

      // Optionally show snack and add to messages
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$title: $body"),
          duration: const Duration(seconds: 3),
        ),
      );

      setState(() {
        _messages.add({'sender': 'Host', 'msg': body});
      });
    });

    // Background / notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (!mounted || _room == null) return;

      _onNotificationTap();
    });


    // 🔹 Listen to Firebase Realtime Database for currentCount
    final messagesRef =
    FirebaseDatabase.instance.ref().child('livekit_messages');

    messagesRef.onValue.listen((event) {
      if (!mounted || !event.snapshot.exists) return;

      final messages = event.snapshot.children.toList();
      if (messages.isEmpty) return;

      final latestMessage = messages.last;

      final currentCount = int.tryParse(
          latestMessage.child('currentCount').value?.toString() ?? '0') ??
          0;
      final lastCount = int.tryParse(
          latestMessage.child('lastCount').value?.toString() ?? '0') ??
          0;

      final unread = currentCount - lastCount;

      if (mounted) {
        setState(() {
          notificationCount += unread; // show real unread count
        });
      }
    });

  }

  Future<void> _connectToRoom() async {
    try {
      // 🔹 Step 0: increment session ID (used to ignore stale events)
      _currentSessionId++;
      final sessionId = _currentSessionId;
      print("🆕 Starting new LiveKit session ID: $sessionId");

      // 🔹 Step 1: FULL CLEANUP before reconnecting
      _remoteParticipants.clear();
      controller.remoteParticipantsList.clear();

      await controller.room?.disconnect();
      await controller.room?.dispose();

      controller.room = null;
      _room = null;
      print("🧹 Cleaned up previous LiveKit session before reconnecting");

      // 🔹 Step 2: show connecting UI
      if (mounted) setState(() => _isConnected = false);

      // 🔹 Step 3: Load saved host id
      final savedHostId = await getHostIdentity();
      if (savedHostId.isNotEmpty) {
        controller.hostUserId = savedHostId;
        globalHostId = savedHostId;
        print("✅ Loaded host ID from SharedPreferences: ${controller.hostUserId}");
        if (mounted) setState(() {});
      } else {
        _hostIdentityResolved = (widget.hostIdentity != null && widget.hostIdentity!.isNotEmpty)
            ? widget.hostIdentity
            : await controller.fetchHostIdentityApi();

        controller.hostUserId = _hostIdentityResolved ?? '';
        globalHostId = _hostIdentityResolved;
        print("🆕 Host ID fetched and stored globally: $globalHostId");

        if (globalHostId != null && globalHostId!.isNotEmpty) {
          await saveHostIdentity(globalHostId!);
        }
      }

      // 🔹 Step 4: Create a fresh room
      controller.room = Room();
      _room = controller.room;

      // 🔹 Step 5: Fresh event listener (with session check)
      _room!.events.listen((event) {
        // 👇 Ignore stale events from old rooms
        if (sessionId != _currentSessionId) {
          print("⚠️ Ignored stale event from old session: $event");
          return;
        }
        // ✅ Forward
        // only current session events
        _handleRoomEvent(event);
      });

      //🔹 Step 6: Connect to LiveKit room
      await _room!.connect(
        widget.url,
        widget.token,
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
          defaultAudioCaptureOptions: AudioCaptureOptions(
            echoCancellation: true,
            noiseSuppression: true,
            autoGainControl: true,
          ),
        ),
      );


      // 🔹 Step 7: Populate participant list cleanly
      _remoteParticipants.clear();
      _remoteParticipants.addAll(_room!.remoteParticipants);
      controller.remoteParticipantsList
        ..clear()
        ..addAll(_remoteParticipants.values);
      controller.onParticipantsUpdated?.call();

      // Disable mic initially
      await _room!.localParticipant?.setMicrophoneEnabled(false);
      isMicOn = false;
      _isMutedVisual = true;

      if (mounted) setState(() => _isConnected = true);

      print("✅ Connected to LiveKit room: ${widget.roomId}");
      controller.remoteParticipantsList.forEach((p) => print("Participant: ${p.identity}"));
      print("HostUserId: ${controller.hostUserId}");

      // 🔹 Step 8: Check if host already joined
      final hostAlreadyJoined = _room!.remoteParticipants.values
          .any((p) => (p.identity ?? '').trim() == (controller.hostUserId ?? '').trim());
      if (hostAlreadyJoined) {
        print("🎉 Host is already in the room!");
        if (mounted) setState(() {});
      }

    } catch (e, st) {
      print('❌ Failed to connect: $e\n$st');

      if (mounted) setState(() => _isConnected = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to join call')),
        );
        if (Navigator.canPop(context)) Navigator.pop(context);
      }
    }
  }

  void _handleRoomEvent(RoomEvent event) async {
    if (event is ParticipantConnectedEvent) {
      setState(() => _remoteParticipants[event.participant.sid] = event.participant);
    } else if (event is ParticipantDisconnectedEvent) {
      setState(() => _remoteParticipants.remove(event.participant.sid));
    }else if (event is RoomDisconnectedEvent) {
      print('Room disconnected: ${event.reason}');

      final identity = _room?.localParticipant?.identity ?? await getHostIdentity();

      //final identity = await getUserName();
      print('DiscconnectIdentityname: ${identity}');

      // Prevent unnecessary API call when host ended the room
      if (event.reason != DisconnectReason.roomDeleted) {
        await controller.leaveRoom(identity);
      }

      await Future.delayed(const Duration(milliseconds: 300));

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/Home',
              (route) => false,
        );
      }
    }  else if (event is DataReceivedEvent) {
      final txt = utf8.decode(event.data);
      final sender = event.participant?.identity ?? 'Server';
      setState(() => _messages.add({'sender': sender, 'msg': txt}));

      if (event.topic == 'kick') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(txt)));

        final identity = await getUserName();
        await controller.leaveRoom(identity);

        await Future.delayed(const Duration(milliseconds: 800));

        if (mounted) {
          Navigator.pushNamedAndRemoveUntil(context, '/Home', (route) => false);
        }
      }
    }
  }


  void _onNotificationTap() async {
    if (_room == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Room is not connected yet')),
      );
      return;
    }

    setState(() {
      notificationCount = 0; // reset badge immediately
    });

    // Update lastCount = currentCount in Firebase
    final messagesRef =
    FirebaseDatabase.instance.ref().child('livekit_messages');
    try {
      final snapshot = await messagesRef.limitToLast(1).get();
      if (snapshot.exists) {
        for (var child in snapshot.children) {
          final currentCount = int.tryParse(
              child.child('currentCount').value?.toString() ?? '0') ??
              0;
          await child.ref.update({'lastCount': currentCount});
        }
      }
    } catch (e) {
      print("⚠️ Failed to update lastCount: $e");
    }

    // Navigate to chat screen
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ClientChatScreen(room: _room!),
        ),
      );
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    _room?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: HexColor(darkBlueColor),
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
      child: WillPopScope(
        onWillPop: () async {
          final res = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Leave call?'),
              content: const Text('Are you sure you want to leave the call?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
                TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
              ],
            ),
          );
          if (res == true) {
            final identity = await getUserName();
            await controller.leaveRoom(identity);
            Navigator.pushNamed(context, '/Home');
            return false;
          }
          return false;
        },
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/bg.png'),
            ),
          ),
          child: Scaffold(
            key: controller.scaffoldKey,
            backgroundColor: Colors.transparent,
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
                  showNotification: true,
                  notificationCount: notificationCount, // ✅ pass the live value
                  onNotificationTap: _onNotificationTap,
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
                                  final identity = await getUserName();
                                  await controller.leaveRoom(identity);
                                  Navigator.pushNamed(context, '/Home');
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
            bottomNavigationBar: CustomBottomBar(bgColor: HexColor(darkBlueColor)),
            body: Container(
              height: MediaQuery.of(context).size.height,
              decoration: const BoxDecoration(
                image: DecorationImage(image: AssetImage('assets/images/bg.png'), fit: BoxFit.fill),
              ),
              child: SafeArea(
                child: _isConnected
                    ? _buildConnectedUI()
                    : _buildConnectingUI(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectedUI() {
    return FutureBuilder<String>(
      future: getHostIdentity(), // fetch saved host ID
      builder: (context, snapshot) {
        final localHostId = snapshot.data ?? controller.hostUserId ?? '';

        // host present check
        final hostPresent = _remoteParticipants.values
            .any((p) => (p.identity ?? '').trim() == (globalHostId ?? '').trim());

        // 🧠 Debugging info
        print('HostPresesnt:$hostPresent');
        print('Resolved Host ID: $localHostId');
        print('Remote Participants (${_remoteParticipants.length}):');
        _remoteParticipants.values.forEach((p) {
          print('Participant Identity: ${p.identity}');
        });
        print('✅ hostPresent = $hostPresent');

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        // ✅ Once snapshot ready, load main UI
        return SingleChildScrollView(
          physics: _isUserHolding
              ? const NeverScrollableScrollPhysics()
              : const BouncingScrollPhysics(),
          child: Column(
            children: [
              Container(
                height: 50,
                width: double.infinity,
                margin: const EdgeInsets.only(top: 5, bottom: 10),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                child: Text(
                  'Hello, ${_room?.localParticipant?.identity ?? 'User'}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
              ),

              Container(
                margin: const EdgeInsets.all(15),
                padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 25),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/bg-3.png'),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Column(
                  children: [
                    // 🔘 Top icon buttons row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        InkWell(
                          onTap: () async {
                            await controller.changeVolumeBroadcasting();
                            setState(() {}); // Update UI
                          },
                          child: Column(
                            children: [
                              Image.asset(
                                controller.isOnSpeaker
                                    ? 'assets/images/speaker.png'
                                    : 'assets/images/mute-speaker.png',
                                height: 60,
                                width: 60,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Speaker',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 15),

                        InkWell(
                          onTap: () async {
                            await controller.changeVolumeBroadcastingToBluetooth();
                            setState(() {}); // Update UI
                          },
                          child: Column(
                            children: [
                              Image.asset(
                                controller.isOnBluetooth
                                    ? 'assets/images/active-bluetooth.png'
                                    : 'assets/images/bluetooth.png',
                                height: 60,
                                width: 60,
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Bluetooth',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 15),

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
                                          final identity = await getUserName();
                                          await controller.leaveRoom(identity);
                                          Navigator.pushNamed(context, '/Home');
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
                          child: SizedBox(
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
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ), // ✅ close the Row properly here

                    const SizedBox(height: 70),


                    Column(
                      children: [
                        Listener(
                          onPointerDown: (_) {
                            // Instant button press effect (visual only)
                            setState(() {
                              _isUserHolding = true;
                              _isMutedVisual = false;
                              isMicOn = true;
                            });
                          },
                          onPointerUp: (_) async {
                            // Instant release effect (visual only)
                            setState(() {
                              _isUserHolding = false;
                              _isMutedVisual = true;
                              isMicOn = false;
                            });
                          },
                          child: GestureDetector(
                            onLongPressStart: (_) async {
                              // Actual mic ON
                              await controller.changeAudioStateLiveKit(true);
                            },
                            onLongPressEnd: (_) async {
                              // Actual mic OFF
                              await controller.changeAudioStateLiveKit(false);
                            },
                            child: Image.asset(
                              _isMutedVisual
                                  ? 'assets/images/mute.png'
                                  : 'assets/images/unmute.png',
                              height: 261,
                              width: 261,
                            ),
                          ),
                        ),

                        const SizedBox(height: 30),
                        const Text(
                          'Tap and hold to speak',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ],
                    ),

                    //old old code
                    // Column(
                    //   children: [
                    //     IgnorePointer(
                    //       ignoring: false,
                    //       //ignoring: !_isConnected,
                    //       child: Listener(
                    //         onPointerDown: (_) async {
                    //           setState(() {
                    //             _isUserHolding = true;
                    //             isMicOn = true;
                    //             _isMutedVisual = false;
                    //           });
                    //           await controller.changeAudioStateLiveKit(true);
                    //         },
                    //         onPointerUp: (_) async {
                    //           setState(() {
                    //             _isUserHolding = false;
                    //             isMicOn = false;
                    //             _isMutedVisual = true;
                    //           });
                    //           await controller.changeAudioStateLiveKit(false);
                    //         },
                    //         child: Image.asset(
                    //           _isMutedVisual
                    //               ? 'assets/images/mute.png'
                    //               : 'assets/images/unmute.png',
                    //           height: 261,
                    //           width: 261,
                    //         ),
                    //       ),
                    //     ),
                    //     const SizedBox(height: 30),
                    //     const Text(
                    //       'Tap and hold to speak',
                    //       style: TextStyle(color: Colors.white, fontSize: 14),
                    //     ),
                    //   ],
                    // ),


                    //old code
                    // 🎤 Voice control section
                    // hostPresent
                    //     ? Column(
                    //   children: [
                    //     IgnorePointer(
                    //       ignoring: !_isConnected,
                    //       child: Listener(
                    //         onPointerDown: (_) async {
                    //           setState(() {
                    //             _isUserHolding = true;
                    //             isMicOn = true;
                    //             _isMutedVisual = false;
                    //           });
                    //           await controller.changeAudioStateLiveKit(true);
                    //         },
                    //         onPointerUp: (_) async {
                    //           setState(() {
                    //             _isUserHolding = false;
                    //             isMicOn = false;
                    //             _isMutedVisual = true;
                    //           });
                    //           await controller.changeAudioStateLiveKit(false);
                    //         },
                    //         child: Image.asset(
                    //           _isMutedVisual
                    //               ? 'assets/images/mute.png'
                    //               : 'assets/images/unmute.png',
                    //           height: 261,
                    //           width: 261,
                    //         ),
                    //       ),
                    //     ),
                    //     const SizedBox(height: 30),
                    //     const Text(
                    //       'Tap and hold to speak',
                    //       style: TextStyle(color: Colors.white, fontSize: 14),
                    //     ),
                    //   ],
                    // )
                    //     : Center(
                    //   child: Column(
                    //     mainAxisAlignment: MainAxisAlignment.center,
                    //     children: const [
                    //       CircularProgressIndicator(color: Colors.white),
                    //       SizedBox(height: 10),
                    //       Text(
                    //         'Waiting Host To Join The Session...',
                    //         textAlign: TextAlign.center,
                    //         style: TextStyle(
                    //           color: Colors.white,
                    //           fontSize: 16,
                    //           fontWeight: FontWeight.w700,
                    //         ),
                    //       ),
                    //     ],
                    //   ),
                    // ),
                  ],
                ),
              ),

            ],
          ),
        );
      },
    );
  }


  Widget _buildConnectingUI() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 10),
          Text(
            "Please Wait While We're Joining You To Session...",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

}



