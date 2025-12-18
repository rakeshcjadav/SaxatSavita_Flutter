import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:saxatsavita_flutter/auth/pages/google_sign_in_page.dart';
import 'package:saxatsavita_flutter/pages/homepage.dart';
import 'package:saxatsavita_flutter/pages/profile_page.dart';
import 'package:saxatsavita_flutter/pages/welcome_screen.dart';
import 'package:saxatsavita_flutter/services/first_time_user_service.dart';
import 'package:saxatsavita_flutter/services/utils.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => SplashPageState();
}

class SplashPageState extends State<SplashPage> {
  String _migrationMessage = '';
  double _migrationProgress = 0.0;
  bool _isMigrating = false;

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

      // For web, skip Firebase Auth and go directly to homepage
      if (kIsWeb) {
        FlutterNativeSplash.remove();

        if (!mounted) return;

        await Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        return;
      }

      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        debugPrint("User is signed in:");
        debugPrint("Email: ${user.email}");
        debugPrint("Display Name: ${user.displayName}");
        debugPrint("Photo URL: ${user.photoURL}");

        if (!mounted) return;

        // Check if migration is needed and perform it
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _isMigrating = true;
          _migrationMessage = l10n.migrating_data;
          _migrationProgress = 0.0;
        });

        await Utils.checkAndPerformMigration(
          onProgress: (message, progress) {
            if (mounted) {
              setState(() {
                // Map progress values to localized messages
                if (progress <= 0.25) {
                  _migrationMessage = l10n.migrating_reading_history;
                } else if (progress <= 0.75) {
                  _migrationMessage = l10n.migrating_kiran_progress;
                } else {
                  _migrationMessage = l10n.migration_complete;
                }
                _migrationProgress = progress;
              });
            }
          },
        );

        if (mounted) {
          setState(() {
            _isMigrating = false;
          });
        }

        debugPrint('_handleAuthenticationEvent : Migration done');

        await Utils.loadUserdatafromFirebase();

        // Check if user has profile data to determine navigation
        bool shouldGoToProfile = await Utils.shouldNavigateToProfile();

        // Check if this is the first time user
        final isFirstTime = await FirstTimeUserService.isFirstTimeUser();

        FlutterNativeSplash.remove(); // remove splash after init

        if (shouldGoToProfile) {
          if (mounted) {
            debugPrint('_handleAuthenticationEvent : Routing to Profile Page');
            await Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder:
                    (context) => const ProfilePage(continueAfterProfile: true),
              ),
            );
          }
        }

        if (isFirstTime) {
          if (mounted) {
            // Show welcome screen for first-time users
            await Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const WelcomeScreen()),
            );
          }
        } else {
          if (mounted) {
            // Go directly to homepage for returning users
            await Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
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
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isMigrating) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      children: [
                        LinearProgressIndicator(
                          value: _migrationProgress,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          minHeight: 4,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _migrationMessage,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
