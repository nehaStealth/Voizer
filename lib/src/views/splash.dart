import 'package:agora_calling_app/src/controllers/splash_controller.dart';
import 'package:agora_calling_app/src/widget/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mvc_pattern/mvc_pattern.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_service.dart';

class Splash extends StatefulWidget {
  @override
  const Splash({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => SplashState();
}

class SplashState extends StateMVC<Splash>with SingleTickerProviderStateMixin{
  SplashController splashCon = SplashController();
  String? splashImageUrl;
  bool isLoading = true; // to show loader until API response

  SplashState() : super(SplashController()) {
    splashCon = controller as SplashController;
  }

  @override
  void dispose() {
    splashCon.animationController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    // 🔹 Fetch API splash image
    splashCon.fetchAppSettings().then((_) async {
      final url = await getClientSplashPath();



      if (url != null && url.isNotEmpty) {
        setState(() {
          splashImageUrl = url;
          isLoading = false;
        });

        // Start animation after splash image is loaded
        splashCon.animationController = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 3),
        );

        splashCon.animation = Tween<double>(begin: 225, end: 275)
            .animate(splashCon.animationController)
          ..addListener(() {
            setState(() {}); // rebuild on every animation tick
          });

        splashCon.animationController.repeat(reverse: true);
      } else {
        setState(() {
          isLoading = false;
        });
      }

      // After showing splash, move forward
      splashCon.init(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: whiteColor,
        statusBarBrightness: Brightness.light,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        key: splashCon.scaffoldKey,
        backgroundColor: whiteColor,
        body: Center(
          child: isLoading
              ? const CircularProgressIndicator()
              : splashImageUrl != null
              ? Image.network(
            splashImageUrl!,
            fit: BoxFit.contain,
            width: splashCon.animation.value,
            height: splashCon.animation.value,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const CircularProgressIndicator();
            },
            errorBuilder: (context, error, stackTrace) {
              return const Text("Failed to load image");
            },
          )
              : const Text("No splash image found"),
        ),
      ),
    );
  }
}
