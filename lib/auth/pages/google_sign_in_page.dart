import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class GoogleSignInPage extends StatefulWidget {
  const GoogleSignInPage({super.key});

  @override
  State<GoogleSignInPage> createState() => GoogleSignInPageState();
}

class GoogleSignInPageState extends State<GoogleSignInPage> {
  GoogleSignInAccount? _currentUser;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Initialize any required resources here

    // #docregion google_sign_in
    final GoogleSignIn googleSignIn = GoogleSignIn.instance;
    unawaited(
      googleSignIn.initialize().then((_) {
        googleSignIn.authenticationEvents
            .listen(_handleAuthenticationEvent)
            .onError(_handleAuthenticationError);
        googleSignIn.attemptLightweightAuthentication();
      }),
    );
    // #enddocregion google_sign_in
  }

  void _handleAuthenticationEvent(GoogleSignInAuthenticationEvent event) async {
    final GoogleSignInAccount? user = switch (event) {
      GoogleSignInAuthenticationEventSignIn() => event.user,
      GoogleSignInAuthenticationEventSignOut() => null,
    };

    final GoogleSignInAuthentication? googleAuth = user?.authentication;

    try {
      GoogleAuthProvider credential = GoogleAuthProvider();

      //await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      print('Error obtaining Google credentials: $e');
      setState(() {
        _errorMessage = 'Error obtaining Google credentials: $e';
      });
      return;
    }

    setState(() {
      _currentUser = user;
      _errorMessage = '';
    });
  }

  Future<void> _handleSignOut() async {
    // Disconnect instead of just signing out, to reset the example state as
    // much as possible.
    //await FirebaseAuth.instance.signOut();
    await GoogleSignIn.instance.disconnect();
  }

  void _handleAuthenticationError(Object e) async {
    setState(() {
      _currentUser = null;
      _errorMessage =
          e is GoogleSignInException
              ? _errorMessageFromSignInException(e)
              : 'Unknown error occurred : $e';
    });
  }

  String _errorMessageFromSignInException(GoogleSignInException e) {
    // In practice, an application should likely have specific handling for most
    // or all of the, but for simplicity this just handles cancel, and reports
    // the rest as generic errors.
    return switch (e.code) {
      GoogleSignInExceptionCode.canceled => 'Sign in canceled',
      _ => 'GoogleSignInException ${e.code}: ${e.description}',
    };
  }

  Widget _buildBody() {
    final GoogleSignInAccount? user = _currentUser;
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        if (user != null)
          ..._buildAuthenticatedWidgets(user, _errorMessage)
        else
          ..._buildUnauthenticatedWidgets(),
        if (_errorMessage.isNotEmpty) Text(_errorMessage),
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
      ListTile(
        leading: GoogleUserCircleAvatar(identity: user),
        title: Text(user.displayName ?? ''),
        subtitle: Text(user.email),
      ),
      const Text('Signed in successfully.'),
      Text(errorMessage),
      ElevatedButton(onPressed: _handleSignOut, child: const Text('SIGN OUT')),
    ];
  }

  /// Returns the list of widgets to include if the user is not authenticated.
  List<Widget> _buildUnauthenticatedWidgets() {
    return <Widget>[
      const Text('You are not currently signed in.'),
      // #docregion ExplicitSignIn
      if (GoogleSignIn.instance.supportsAuthenticate())
        ElevatedButton(
          onPressed: () async {
            try {
              await GoogleSignIn.instance.authenticate();
            } catch (e) {
              // #enddocregion ExplicitSignIn
              _errorMessage = e.toString();
              // #docregion ExplicitSignIn
            }
          },
          child: const Text('SIGN IN'),
        )
      else ...<Widget>[
        // #enddocregion ExplicitSignIn
        const Text('This platform does not have a known authentication method'),
        // #docregion ExplicitSignIn
      ],
      // #enddocregion ExplicitSignIn
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Google Sign-In Page')),
      body: ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: _buildBody(),
      ),
    );
  }
}
