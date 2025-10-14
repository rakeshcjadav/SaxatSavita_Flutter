import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/pages/homepage.dart';
import 'package:saxatsavita_flutter/services/utils.dart';

class GoogleSignInPage extends StatefulWidget {
  const GoogleSignInPage({super.key});

  @override
  State<GoogleSignInPage> createState() => GoogleSignInPageState();
}

class GoogleSignInPageState extends State<GoogleSignInPage> {
  GoogleSignInAccount? _currentUser;
  String _errorMessage = '';

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn.instance;

  @override
  void initState() {
    super.initState();
    if (googleSignIn.supportsAuthenticate()) {
      _initializeGoogleSignIn();
    }
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      // #docregion Setup
      unawaited(
        googleSignIn.initialize().then((_) {
          googleSignIn.authenticationEvents
              .listen(_handleAuthenticationEvent)
              .onError(_handleAuthenticationError);
          googleSignIn.attemptLightweightAuthentication();
        }),
      );
      // #enddocregion Setup
    } catch (e) {
      setState(() {
        _errorMessage = 'Initialization error: ${e.toString()}';
        debugPrint('_initializeGoogleSignIn : $_errorMessage');
      });
    }
  }

  Future<void> _handleAuthenticationEvent(
    GoogleSignInAuthenticationEvent event,
  ) async {
    debugPrint('_handleAuthenticationEvent : start');
    if (!mounted) return;
    debugPrint('_handleAuthenticationEvent : mounted');
    final GoogleSignInAccount? user = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };
    debugPrint('_handleAuthenticationEvent : $user');
    if (user == null) {
      // User signed out
      if (mounted) {
        setState(() {
          _currentUser = null;
          _errorMessage = '';
        });
      }
      await firebaseAuth.signOut();
      return;
    }
    debugPrint('_handleAuthenticationEvent : $user');

    try {
      final GoogleSignInAuthentication googleAuth = user.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      debugPrint('_handleAuthenticationEvent : $googleAuth');

      await firebaseAuth.signInWithCredential(credential);

      debugPrint('_handleAuthenticationEvent : $firebaseAuth');

      if (mounted) {
        setState(() {
          _currentUser = user;
          _errorMessage = '';
          debugPrint('_handleAuthenticationEvent : setState() $user');
        });

        debugPrint('_handleAuthenticationEvent : Rounte : HomePage()');

        Utils.loadUserdatafromFirebase();

        Utils.saveUserDetailsToFirebase();

        // Check if migration is needed and perform it
        await Utils.checkAndPerformMigration();

        // Navigate after state is updated
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );

        debugPrint('_handleAuthenticationEvent : Rounted : HomePage()');
      }

      debugPrint('_handleAuthenticationEvent : end');
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error obtaining Google credentials: $e';
        });
      }
      debugPrint('Authentication error: $e');
    }
  }

  Future<void> _handleSignOut() async {
    try {
      // Show loading indicator
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(child: CircularProgressIndicator()),
        );
      }

      // Sign out from Google
      await googleSignIn.signOut();
      // Sign out from Firebase
      await firebaseAuth.signOut();

      if (mounted) {
        // Pop loading indicator
        Navigator.pop(context);
        setState(() {
          _currentUser = null;
          _errorMessage = '';
        });

        // Navigate back to sign-in page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const GoogleSignInPage()),
        );
      }
    } catch (e) {
      if (mounted) {
        // Pop loading indicator if showing
        Navigator.pop(context);
        setState(() {
          _errorMessage = 'Error signing out: ${e.toString()}';
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Sign out error: $e');
    }
  }

  void _handleAuthenticationError(Object e) async {
    debugPrint('_handleAuthenticationError : start');
    setState(() {
      _currentUser = null;
      _errorMessage =
          e is GoogleSignInException
              ? _errorMessageFromSignInException(e)
              : 'Unknown error occurred : $e';
      debugPrint('_handleAuthenticationError : $_errorMessage');
    });
  }

  String _errorMessageFromSignInException(GoogleSignInException e) {
    // In practice, an application should likely have specific handling for most
    // or all of the, but for simplicity this just handles cancel, and reports
    // the rest as generic errors.
    return switch (e.code) {
      GoogleSignInExceptionCode.canceled => 'Sign in cancelled',
      _ => 'GoogleSignInException ${e.code}: ${e.description}',
    };
  }

  Widget _buildBody() {
    final GoogleSignInAccount? user = _currentUser;
    return Stack(
      children: <Widget>[
        if (user != null)
          ..._buildAuthenticatedWidgets(user, _errorMessage)
        else
          ..._buildUnauthenticatedWidgets(),
        SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (_errorMessage.isNotEmpty)
                Center(
                  child: Text(
                    _errorMessage,
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium!.copyWith(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ],
    );
  }

  /// Returns the list of widgets to include if the user is authenticated.
  List<Widget> _buildAuthenticatedWidgets(
    GoogleSignInAccount user,
    String errorMessage,
  ) {
    return <Widget>[
      // The user is Authenticated.
      Center(
        child: Column(
          children: [
            ListTile(
              leading: GoogleUserCircleAvatar(identity: user),
              title: Text(user.displayName ?? ''),
              subtitle: Text(user.email),
            ),
            const SizedBox(height: 10),
            const Text('Signed in successfully.'),
            Text(errorMessage),
          ],
        ),
      ),
      //ElevatedButton(onPressed: _handleSignOut, child: const Text('SIGN OUT')),
    ];
  }

  /// Returns the list of widgets to include if the user is not authenticated.
  List<Widget> _buildUnauthenticatedWidgets() {
    return <Widget>[
      Stack(
        children: [
          ClipRRect(
            child: Image(
              image: AssetImage('assets/res/z_jogi_swami_tallest_2.jpg'),
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  "પ.પૂ.પ્ર.બ્ર.સ્વ.સદ્. જોગીસ્વામી\nશ્રી ધર્મપ્રસાદદાસજી સ્વામી",
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                // #docregion ExplicitSignIn
                if (googleSignIn.supportsAuthenticate()) ...[
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black87,
                        //minimumSize: const Size(double.infinity, 50),
                      ),
                      onPressed: () async {
                        try {
                          await GoogleSignIn.instance.authenticate();
                        } catch (e) {
                          // #enddocregion ExplicitSignIn
                          _errorMessage = e.toString();
                          // #docregion ExplicitSignIn
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(top: 15, bottom: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/signin-assets/android_light_rd_na@2x.png',
                              height: 36.0,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              AppLocalizations.of(context)!.loginWithGoogle,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                ] else ...<Widget>[
                  // #enddocregion ExplicitSignIn
                  const Text(
                    'This platform does not have a known authentication method',
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomePage(),
                        ),
                      );
                    },
                    child: const Text("Enter"),
                  ),
                  // #docregion ExplicitSignIn
                ],
              ],
            ),
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.sakshatSavita)),
      body: ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: _buildBody(),
      ),
    );
  }
}
