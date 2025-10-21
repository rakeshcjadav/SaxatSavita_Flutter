import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/pages/homepage.dart';
import 'package:saxatsavita_flutter/services/utils.dart';
import 'package:saxatsavita_flutter/services/analytics_service.dart';

class GoogleSignInPage extends StatefulWidget {
  const GoogleSignInPage({super.key});

  @override
  State<GoogleSignInPage> createState() => GoogleSignInPageState();
}

class GoogleSignInPageState extends State<GoogleSignInPage> {
  GoogleSignInAccount? _currentUser;
  String _errorMessage = '';
  bool _isAppleSignInAvailable = false;

  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn googleSignIn = GoogleSignIn.instance;

  @override
  void initState() {
    super.initState();
    if (googleSignIn.supportsAuthenticate()) {
      _initializeGoogleSignIn();
    }
    _checkAppleSignInAvailability();
  }

  Future<void> _checkAppleSignInAvailability() async {
    if (Platform.isIOS || Platform.isMacOS) {
      try {
        final isAvailable = await SignInWithApple.isAvailable();
        debugPrint('Apple Sign-In isAvailable: $isAvailable');
        setState(() {
          _isAppleSignInAvailable = isAvailable;
        });
      } catch (e) {
        debugPrint('Error checking Apple Sign-In availability: $e');
        setState(() {
          _isAppleSignInAvailable = false;
        });
      }
    } else {
      debugPrint('Platform is not iOS/macOS, Apple Sign-In not available');
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

      final userCredential = await firebaseAuth.signInWithCredential(
        credential,
      );

      debugPrint('_handleAuthenticationEvent : $firebaseAuth');

      // Track successful Google Sign-In
      if (userCredential.user != null) {
        await AnalyticsService().logSignIn('google');
        await AnalyticsService().setUserProperties(
          userId: userCredential.user!.uid,
          provider: 'google',
        );
      }

      if (mounted) {
        setState(() {
          _currentUser = user;
          _errorMessage = '';
          debugPrint('_handleAuthenticationEvent : setState() $user');
        });

        await onSuccessfulSignIn();
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

  Future<void> onSuccessfulSignIn() async {
    debugPrint('_handleAuthenticationEvent : Rounte : HomePage()');

    await Utils.loadUserdatafromFirebase();

    await Utils.saveUserDetailsToFirebase();

    // Check if migration is needed and perform it
    await Utils.checkAndPerformMigration();

    debugPrint('_handleAuthenticationEvent : Migration done');

    setState(() {
      _errorMessage = 'Navigation to HomePage';
    });
    // Navigate after state is updated
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );

    debugPrint('_handleAuthenticationEvent : Rounted : HomePage()');
  }

  /*
  // Debug method to test Apple Sign-In capability
  Future<void> _testAppleSignInCapability() async {
    debugPrint('=== Testing Apple Sign-In Capability ===');
    debugPrint('Platform: ${Platform.operatingSystem}');

    if (!Platform.isIOS && !Platform.isMacOS) {
      debugPrint('Apple Sign-In only available on iOS/macOS');
      return;
    }

    try {
      final isAvailable = await SignInWithApple.isAvailable();
      debugPrint('SignInWithApple.isAvailable(): $isAvailable');

      if (!isAvailable) {
        debugPrint('Apple Sign-In is not available on this device');
        return;
      }

      // Test if we can get authorization scope
      debugPrint('Attempting test authorization...');
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      debugPrint('Test successful! Credential details:');
      debugPrint('- User ID: ${credential.userIdentifier}');
      debugPrint('- Email: ${credential.email}');
      debugPrint('- Given Name: ${credential.givenName}');
      debugPrint('- Family Name: ${credential.familyName}');
      debugPrint(
        '- Identity Token: ${credential.identityToken != null ? "Present" : "Missing"}',
      );
      debugPrint(
        '- Authorization Code: Present',
      ); // Authorization code is always present
    } catch (e) {
      debugPrint('Test failed with error: $e');
      if (e is SignInWithAppleAuthorizationException) {
        debugPrint('Error code: ${e.code}');
        debugPrint('Error message: ${e.message}');
      }
    }
  }
  */
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

  // Apple Sign-In method
  //
  // IMPORTANT APPLE SIGN-IN LIMITATIONS:
  // 1. displayName (givenName/familyName) is ONLY provided on FIRST sign-in
  // 2. photoURL is NEVER provided by Apple (privacy feature)
  // 3. Email may be hidden/proxied by Apple if user chooses "Hide My Email"
  // 4. Subsequent sign-ins will only provide userIdentifier and possibly email
  Future<void> _signInWithApple() async {
    try {
      // Check if Apple Sign-In is available
      if (!await SignInWithApple.isAvailable()) {
        setState(() {
          _errorMessage = 'Apple Sign-In is not available on this device';
        });
        return;
      }

      // Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        // Remove webAuthenticationOptions for now as it's mainly for web
        // webAuthenticationOptions: WebAuthenticationOptions(
        //   clientId: 'com.astound.SaxatSavita',
        //   redirectUri: Uri.parse(
        //     'https://saxat-savita-crashanalytics.firebaseapp.com/__/auth/handler',
        //   ),
        // ),
      );

      // Create OAuth credential for Firebase
      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      // Sign in to Firebase
      final userCredential = await firebaseAuth.signInWithCredential(
        oauthCredential,
      );

      // Handle Apple Sign-In user profile update with proper caching
      if (mounted && userCredential.user != null) {
        final user = userCredential.user!;
        final userIdentifier = appleCredential.userIdentifier;

        if (userIdentifier == null) {
          debugPrint('ERROR: Apple Sign-In userIdentifier is null');
          setState(() {
            _errorMessage = 'Apple Sign-In error: Missing user identifier';
          });
          return;
        }

        debugPrint('Apple Sign-In - User Identifier: $userIdentifier');
        debugPrint('Apple Sign-In - givenName: ${appleCredential.givenName}');
        debugPrint('Apple Sign-In - familyName: ${appleCredential.familyName}');
        debugPrint('Apple Sign-In - email: ${appleCredential.email}');

        // Check if this is first sign-in (has user info) or subsequent (no user info)
        final isFirstSignIn =
            appleCredential.givenName != null ||
            appleCredential.familyName != null ||
            appleCredential.email != null;

        if (isFirstSignIn) {
          debugPrint('FIRST Apple Sign-In detected - caching user data');

          // Cache the user data for subsequent sign-ins
          // Sync this to firebase for future use
          // This will allow us to use the cached data for subsequent sign-ins
          await _syncAppleUserDataToFirebase(
            userIdentifier: userIdentifier,
            email: appleCredential.email,
            givenName: appleCredential.givenName,
            familyName: appleCredential.familyName,
          );
          await Utils.cacheAppleUserData(
            userIdentifier: userIdentifier,
            email: appleCredential.email,
            givenName: appleCredential.givenName,
            familyName: appleCredential.familyName,
          );
        } else {
          debugPrint('SUBSEQUENT Apple Sign-In detected - using cached data');
        }

        final userInfoSummary = Utils.getUserInfoSummary();
        debugPrint('User info summary: $userInfoSummary');

        // Track successful Apple Sign-In
        await AnalyticsService().logSignIn('apple');
        await AnalyticsService().setUserProperties(
          userId: user.uid,
          provider: 'apple',
        );

        await onSuccessfulSignIn();
      }
    } catch (e) {
      String errorMessage = 'Apple Sign-In error: ';

      if (e is SignInWithAppleAuthorizationException) {
        switch (e.code) {
          case AuthorizationErrorCode.canceled:
            errorMessage += 'Sign-in was cancelled by user';
            break;
          case AuthorizationErrorCode.failed:
            errorMessage += 'Sign-in failed';
            break;
          case AuthorizationErrorCode.invalidResponse:
            errorMessage += 'Invalid response from Apple';
            break;
          case AuthorizationErrorCode.notHandled:
            errorMessage += 'Request not handled';
            break;
          case AuthorizationErrorCode.unknown:
            errorMessage +=
                'Unknown error (likely capability not configured in Xcode)';
            break;
          default:
            errorMessage += e.toString();
        }
      } else {
        errorMessage += e.toString();
      }

      setState(() {
        _errorMessage = errorMessage;
        debugPrint('_signInWithApple error: $_errorMessage');
      });

      // Track Apple Sign-In error
      await AnalyticsService().logError(
        errorType: 'apple_sign_in_error',
        errorMessage: errorMessage,
        screen: 'google_sign_in_page',
      );
    }
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
                    ).textTheme.bodySmall!.copyWith(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 0),
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
                  AppLocalizations.of(context)!.jogi_swami,
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Google Sign-In Button
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
                              'assets/signin-assets/android_neutral_rd_na@4x.png',
                              height: 36.0,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              AppLocalizations.of(context)!.loginWithGoogle,
                              style: Theme.of(context).textTheme.titleSmall!
                                  .copyWith(color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // #docregion ExplicitSignIn

                  // Apple Sign-In Button (iOS/macOS only and when available)
                  if (_isAppleSignInAvailable) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          //minimumSize: const Size(double.infinity, 50),
                        ),
                        onPressed: () async {
                          await _signInWithApple();
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(top: 15, bottom: 15),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.apple, size: 36.0),
                              const SizedBox(width: 12),
                              Text(
                                AppLocalizations.of(context)!.loginWithApple,
                                style: Theme.of(context).textTheme.titleSmall!
                                    .copyWith(color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],

                  /*
                  // Debug Buttons for Apple Sign-In testing
                  if (Platform.isIOS) ...[
                    const SizedBox(height: 16),

                    // Test Apple Sign-In Capability
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _testAppleSignInCapability,
                        child: const Text('Debug: Test Apple Sign-In'),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Show Cache Contents
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: Utils.debugAppleUserCache,
                        child: const Text('Debug: Show Cache'),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Clear Cache
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: Utils.clearAppleUserCache,
                        child: const Text('Debug: Clear Cache'),
                      ),
                    ),
                  ],
                  */
                  const SizedBox(height: 25),
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

  Future<void> _syncAppleUserDataToFirebase({
    required String userIdentifier,
    String? email,
    String? givenName,
    String? familyName,
  }) async {
    // Implement the logic to sync the Apple user data to Firebase
    // For example, you might want to save the userIdentifier, email, givenName, and familyName to Firebase
    // You can access the Firebase Authentication instance using FirebaseAuth.instance
    final user = firebaseAuth.currentUser;
    if (user == null) {
      debugPrint('No authenticated user to sync Apple data for.');
      return;
    }
    debugPrint('Syncing Apple user data to Firebase for user: ${user.uid}');

    await user.reload(); // Ensure we have the latest user data
    // Here, you would typically update the user's profile or a Firestore document
    // with the Apple user data. This is just a placeholder implementation.
    debugPrint('Apple User Data to sync:');
    debugPrint('- User Identifier: $userIdentifier');
    debugPrint('- Email: $email');
    debugPrint('- Given Name: $givenName');
    debugPrint('- Family Name: $familyName');
    await Utils.saveAppleUserDetailsToFirebase(
      '${givenName!} ${familyName!}'.trim(),
      email!,
    );
    debugPrint('Apple user data synced to Firebase successfully.');
  }
}
