import 'package:agora_calling_app/src/views/auth/login.dart';
import 'package:agora_calling_app/src/views/home.dart';
import 'package:agora_calling_app/src/views/livekit_page.dart';
import 'package:agora_calling_app/src/views/recording_list.dart';
import 'package:agora_calling_app/src/views/setting.dart';
import 'package:agora_calling_app/src/views/splash.dart';
import 'package:agora_calling_app/src/views/user_session.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class RouteGenerator {
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    final dynamic args = settings.arguments;
    switch (settings.name) {
      case '/Splash':
        return PageTransition(
          child: const Splash(),
          type: PageTransitionType.fade,
          settings: settings,
        );
      case '/Login':
        return PageTransition(
          child: const Login(),
          type: PageTransitionType.fade,
          settings: settings,
        );
      case '/Home':
        return PageTransition(
          child: const HomePage(),
          type: PageTransitionType.fade,
          settings: settings,
        );
      case '/UserSession':
        return PageTransition(
          child: const UserSession(),
          type: PageTransitionType.fade,
          settings: settings,
        );
      case '/Setting':
        return PageTransition(
          child: const Setting(),
          type: PageTransitionType.fade,
          settings: settings,
        );
      case '/Recording':
        return PageTransition(
          child: const RecordingPage(),
          type: PageTransitionType.fade,
          settings: settings,
        );
      case '/CustomerLiveKitPage':
        if (args is Map<String, dynamic> &&
            args.containsKey('url') &&
            args.containsKey('token') &&
            args.containsKey('roomId')) {
          return PageTransition(
            child: CustomerLiveKitPage(
              url: args['url'],
              token: args['token'],
              roomId: args['roomId'],
              hostIdentity: args['hostIdentity'],
            ),
            type: PageTransitionType.fade,
            settings: settings,
          );
        }
    }
    return PageTransition(
      child:  Container(),
      type: PageTransitionType.fade,
      settings: settings,
    );
  }
}
