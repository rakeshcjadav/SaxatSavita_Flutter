import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:saxatsavita_flutter/auth/pages/google_sign_in_page.dart';
import 'package:saxatsavita_flutter/pages/homepage.dart';
import 'package:saxatsavita_flutter/pages/welcome_screen.dart';
import 'package:saxatsavita_flutter/services/first_time_user_service.dart';
import 'package:saxatsavita_flutter/services/utils.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      // Wait for a minimum splash display time
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint("User is signed in:");
        debugPrint("Email: ${user.email}");
        debugPrint("Display Name: ${user.displayName}");
        debugPrint("Photo URL: ${user.photoURL}");

        if (!mounted) return;

        Utils.loadUserdatafromFirebase();

        // Check if this is the first time user
        final isFirstTime = await FirstTimeUserService.isFirstTimeUser();

        FlutterNativeSplash.remove(); // remove splash after init

        if (isFirstTime) {
          // Show welcome screen for first-time users
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          );
        } else {
          // Go directly to homepage for returning users
          await Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
      } else {
        if (!mounted) return;

        FlutterNativeSplash.remove(); // remove splash after init

        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GoogleSignInPage()),
        );
      }
    } catch (e) {
      debugPrint("Error during authentication check: $e");
      if (!mounted) return;

      // Show error dialog
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
                    _checkAuthAndNavigate(); // Retry
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
