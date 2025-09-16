import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saxatsavita_flutter/auth/pages/google_sign_in_page.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  State<MyDrawer> createState() => _DrawerState();
}

class _DrawerState extends State<MyDrawer> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            currentAccountPicture: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.inversePrimary,
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                backgroundImage: NetworkImage(
                  FirebaseAuth.instance.currentUser?.photoURL ??
                      'assets/res/sakshat_savita_logo.png',
                ),
              ),
            ),
            accountName: Text(
              FirebaseAuth.instance.currentUser?.displayName ??
                  AppLocalizations.of(context)!.sakshatSavita,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
            accountEmail: Text(
              FirebaseAuth.instance.currentUser?.email ??
                  AppLocalizations.of(context)!.sakshatSavita,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.normal,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(AppLocalizations.of(context)!.menu_one),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: Text(AppLocalizations.of(context)!.aashirvachan),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.edit_document),
            title: Text(AppLocalizations.of(context)!.menu_four),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: Text(AppLocalizations.of(context)!.menu_six),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(AppLocalizations.of(context)!.profile),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(AppLocalizations.of(context)!.settings),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(AppLocalizations.of(context)!.logout),
            onTap: () async {
              try {
                // Show loading indicator
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder:
                      (context) =>
                          const Center(child: CircularProgressIndicator()),
                );

                // Sign out from Google
                await GoogleSignIn.instance.signOut();
                // Sign out from Firebase
                await FirebaseAuth.instance.signOut();

                if (mounted) {
                  // Pop the loading indicator
                  Navigator.pop(context);
                  // Navigate to sign in page
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GoogleSignInPage(),
                    ),
                  );
                }
              } catch (e) {
                // Pop the loading indicator
                if (mounted) {
                  Navigator.pop(context);
                  // Show error
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error signing out: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                debugPrint('Sign out error: $e');
              }
            },
          ),
        ],
      ),
    );
  }
}
