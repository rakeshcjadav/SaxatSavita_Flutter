import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:saxatsavita_flutter/auth/pages/google_sign_in_page.dart';
import 'package:saxatsavita_flutter/pages/main_navigation.dart';
import 'package:saxatsavita_flutter/pages/profile_page.dart';
import 'package:saxatsavita_flutter/pages/welcome_screen.dart';
import 'package:saxatsavita_flutter/services/first_time_user_service.dart';
import 'package:saxatsavita_flutter/services/startup_sync_service.dart';
import 'package:saxatsavita_flutter/services/utils.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Remove native splash only after Flutter has a rendered, focusable window.
      FlutterNativeSplash.remove();
      _checkAuthAndNavigate();
    });
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      if (!mounted) return;

      if (kIsWeb) {
        if (!mounted) return;

        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigation()),
        );
        return;
      }

      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint('User is signed in: ${user.email}');

        if (!mounted) return;

        final shouldGoToProfile = await Utils.shouldNavigateToProfileLocally();
        final isFirstTime = await FirstTimeUserService.isFirstTimeUser();

        if (!mounted) return;

        StartupSyncService.syncSignedInUserDataInBackground();

        if (shouldGoToProfile) {
          debugPrint('Routing to Profile Page');
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => const ProfilePage(continueAfterProfile: true),
            ),
          );
        } else if (isFirstTime) {
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          );
        } else {
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const MainNavigation()),
          );
        }
      } else {
        if (!mounted) return;

        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GoogleSignInPage()),
        );
      }
    } catch (e) {
      debugPrint('Error during authentication check: $e');
      if (!mounted) return;

      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to initialize: ${e.toString()}'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _checkAuthAndNavigate();
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Image(
            image: AssetImage('assets/res/z_jogi_swami_tallest.jpg'),
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
          const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
