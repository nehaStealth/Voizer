import 'package:agora_calling_app/firebase_options.dart';
import 'package:agora_calling_app/route_generator.dart';
import 'package:agora_calling_app/src/services/auth_service.dart';
import 'package:agora_calling_app/src/repositories/user_repository.dart' as Repository;
import 'package:agora_calling_app/src/views/splash.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

void main() async {
  //WidgetsFlutterBinding.ensureInitialized();
  //await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  runApp(const MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("📩 Background message: ${message.messageId}");
}


class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;

  @override
  void initState() {
    // TODO: implement initState
    updateDeviceToken();
    super.initState();
  }

  updateDeviceToken() async {
    bool loginStatus = await getLogin();

    if(loginStatus) {
      firebaseMessaging.requestPermission(
        alert: true,
        announcement: true,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      String? deviceToken = await firebaseMessaging.getToken();
      print("📱 FCM Device Token: $deviceToken");
      Repository.updateDeviceToken(deviceToken);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Voizer',
      themeMode: ThemeMode.system,
      home: Splash(),
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
