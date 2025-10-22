import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saxatsavita_flutter/auth/pages/google_sign_in_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:saxatsavita_flutter/pages/welcome_screen.dart';
import 'package:saxatsavita_flutter/services/cache_service.dart';
import 'package:saxatsavita_flutter/services/utils.dart';

enum DrawerItem {
  aashirvachan,
  information,
  notes,
  search,
  readingPlans,
  readingHistory,
  quotesImageGenerator,
  settings,
  welcomeTour,
  migration,
  logout,
}

class MyDrawer extends StatefulWidget {
  final List<DrawerItem>? _drawerItems;

  const MyDrawer({super.key, List<DrawerItem>? items}) : _drawerItems = items;

  @override
  State<MyDrawer> createState() => _DrawerState();
}

class _DrawerState extends State<MyDrawer> {
  Map<String, String> _userInfoSummary = {};
  @override
  void initState() {
    super.initState();

    getUserInfoSummary();
  }

  Future<void> getUserInfoSummary() async {
    _userInfoSummary = await Utils.getUserInfoSummary();
    setState(() {});
  }

  Widget getAvatar() {
    if (_userInfoSummary['platform'] == 'apple') {
      return CircleAvatar(
        backgroundImage: AssetImage('assets/res/z_jogi_swami_avatar.png'),
      );
    } else if (FirebaseAuth.instance.currentUser?.photoURL == null ||
        FirebaseAuth.instance.currentUser!.photoURL!.isEmpty) {
      return CircleAvatar(
        backgroundImage: AssetImage('assets/res/z_jogi_swami_avatar.png'),
      );
    } else {
      return CircleAvatar(
        backgroundImage: NetworkImage(
          FirebaseAuth.instance.currentUser?.photoURL ?? '',
        ),
      );
    }
  }

  Widget getAccountName() {
    if (Platform.isIOS) {
      return Text(
        _userInfoSummary['displayName'] ?? '',
        style: Theme.of(context).textTheme.titleSmall!.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      );
    }
    return Text(
      FirebaseAuth.instance.currentUser?.displayName ??
          AppLocalizations.of(context)!.sakshatSavita,
      style: Theme.of(context).textTheme.titleSmall!.copyWith(
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  Widget getAccountEmail() {
    if (Platform.isIOS) {
      return Text(
        _userInfoSummary['email'] ?? '',
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      );
    }
    return Text(
      FirebaseAuth.instance.currentUser?.email ??
          AppLocalizations.of(context)!.sakshatSavita,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (FirebaseAuth.instance.currentUser != null) ...[
            UserAccountsDrawerHeader(
              currentAccountPicture: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    width: 2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                child: getAvatar(),
              ),
              accountName: getAccountName(),
              accountEmail: getAccountEmail(),
            ),
          ] else ...[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        width: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                    child: getAvatar(),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: Text(
                      AppLocalizations.of(context)!.sakshatSavita,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall!.copyWith(
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          ...?widget._drawerItems?.map((item) {
            return _buildDrawerItem(item);
          }).toList(),
          const Divider(),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return SizedBox();
              final version = snapshot.data!.version;
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  'Version: $version + ${snapshot.data!.buildNumber}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  _buildDrawerItem(DrawerItem item) {
    return switch (item) {
      DrawerItem.aashirvachan => ListTile(
        leading: const Icon(Icons.description),
        title: Text(AppLocalizations.of(context)!.aashirvachan),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/aashirvachan');
        },
      ),
      DrawerItem.information => ListTile(
        leading: const Icon(Icons.info),
        title: Text(AppLocalizations.of(context)!.information),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/info');
        },
      ),
      DrawerItem.notes => ListTile(
        leading: const Icon(Icons.note),
        title: Text(AppLocalizations.of(context)!.notes),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/notes');
        },
      ),
      DrawerItem.search => ListTile(
        leading: const Icon(Icons.search),
        title: Text(AppLocalizations.of(context)!.search),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/search');
        },
      ),
      DrawerItem.readingPlans => ListTile(
        leading: const Icon(Icons.schedule),
        title: Text(AppLocalizations.of(context)!.reading_plans),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/reading_plans');
        },
      ),
      DrawerItem.readingHistory => ListTile(
        leading: const Icon(Icons.history),
        title: Text(AppLocalizations.of(context)!.reading_history),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/readinghistory');
        },
      ),
      DrawerItem.quotesImageGenerator => ListTile(
        leading: const Icon(Icons.format_quote),
        title: Text(AppLocalizations.of(context)!.quotes_image_generator),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/quotes_generator', arguments: {null});
        },
      ),
      DrawerItem.settings => ListTile(
        leading: const Icon(Icons.settings),
        title: Text(AppLocalizations.of(context)!.settings),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/settings');
        },
      ),
      DrawerItem.welcomeTour => ListTile(
        leading: const Icon(Icons.celebration),
        title: Text(AppLocalizations.of(context)!.welcome_tour),
        onTap: () {
          // Show welcome screen for first-time users
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          );
        },
      ),
      DrawerItem.migration =>
        kDebugMode
            ? ListTile(
              leading: const Icon(Icons.transfer_within_a_station),
              title: Text("Migration (Debug)"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/migration');
              },
            )
            : const SizedBox.shrink(),
      DrawerItem.logout => ListTile(
        leading: const Icon(Icons.logout),
        title: Text(AppLocalizations.of(context)!.logout),
        onTap: () async {
          // Store context-dependent values before async operations
          final navigator = Navigator.of(context);
          final scaffoldMessenger = ScaffoldMessenger.of(context);

          try {
            // Show loading indicator
            showDialog(
              context: context,
              barrierDismissible: false,
              builder:
                  (context) => const Center(child: CircularProgressIndicator()),
            );

            // Clear all local cache before signing out
            await CacheService().clearAllLocalCache();

            // Sign out from Google
            await GoogleSignIn.instance.signOut();
            // Sign out from Firebase
            await FirebaseAuth.instance.signOut();

            if (mounted) {
              // Pop the loading indicator
              navigator.pop();
              // Navigate to sign in page
              navigator.pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const GoogleSignInPage(),
                ),
              );
            }
          } catch (e) {
            // Pop the loading indicator
            if (mounted) {
              navigator.pop();
              // Show error
              scaffoldMessenger.showSnackBar(
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
    };
  }
}
