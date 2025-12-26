import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:saxatsavita_flutter/auth/pages/google_sign_in_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:saxatsavita_flutter/pages/welcome_screen.dart';
import 'package:saxatsavita_flutter/services/cache_service.dart';
import 'package:saxatsavita_flutter/services/user_profile_service.dart';
import 'package:saxatsavita_flutter/models/user_profile_model.dart';

enum DrawerItem {
  aashirvachan,
  information,
  notes,
  search,
  readingPlans,
  readingHistory,
  quotesImageGenerator,
  profile,
  settings,
  welcomeTour,
  migration,
  marketingShowcase,
  adminpanel,
  logout,
}

class MyDrawer extends StatefulWidget {
  final List<DrawerItem>? _drawerItems;

  const MyDrawer({super.key, List<DrawerItem>? items}) : _drawerItems = items;

  @override
  State<MyDrawer> createState() => _DrawerState();
}

class _DrawerState extends State<MyDrawer> {
  UserProfile? _userProfile;
  final UserProfileService _profileService = UserProfileService();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    {
      try {
        final profile = await _profileService.getUserProfile();
        if (mounted) {
          setState(() {
            _userProfile = profile;
          });
        }
      } on FirebaseAuthException catch (e) {
        // Handle Firebase Auth specific errors
        debugPrint(
          'Firebase Auth error loading user profile: ${e.code} - ${e.message}',
        );
        if (mounted) {
          setState(() {
            _userProfile = null;
          });
        }
      } on FirebaseException catch (e) {
        // Handle general Firebase errors
        debugPrint(
          'Firebase error loading user profile: ${e.code} - ${e.message}',
        );
        if (mounted) {
          setState(() {
            _userProfile = null;
          });
        }
      } catch (e) {
        // Handle any other errors
        debugPrint('Error loading user profile: $e');
        if (mounted) {
          setState(() {
            _userProfile = null;
          });
        }
      }
    }
  }

  Widget getAvatar() {
    if (kIsWeb ||
        FirebaseAuth.instance.currentUser?.photoURL == null ||
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
    // Prioritize profile data if available and both names are filled
    if (_userProfile != null &&
        _userProfile!.firstName.isNotEmpty &&
        _userProfile!.lastName.isNotEmpty) {
      return Text(
        _userProfile!.fullName,
        style: Theme.of(context).textTheme.titleSmall!.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 18,
        ),
      );
    } else {
      // Fall back to Firebase Auth display name
      return Text(
        FirebaseAuth.instance.currentUser?.displayName ?? '',
        style: Theme.of(context).textTheme.titleSmall!.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 18,
        ),
      );
    }
  }

  Widget getAccountEmail() {
    // Prioritize profile data if available and both names are filled
    if (_userProfile != null && _userProfile!.email.isNotEmpty) {
      if (_userProfile!.email.contains('appleid.com')) {
        // Handle Apple ID email case
        return Text(
          'Apple ID',
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
            fontSize: 18,
          ),
        );
      }
      return Text(
        _userProfile!.email,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 18,
        ),
      );
    } else {
      // Fall back to Firebase Auth email
      return Text(
        FirebaseAuth.instance.currentUser?.email ?? '',
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
          color: Theme.of(context).colorScheme.onPrimary,
          fontSize: 18,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (!kIsWeb && FirebaseAuth.instance.currentUser != null) ...[
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
          }),
          const Divider(),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return SizedBox();
              final version = snapshot.data!.version;
              return Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 60.0),
                child: Text(
                  'Version: $version + ${snapshot.data!.buildNumber}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, color: Colors.grey),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(DrawerItem item) {
    TextStyle textStyle = const TextStyle(fontSize: 18);
    return switch (item) {
      DrawerItem.aashirvachan => ListTile(
        leading: const Icon(Icons.description),
        title: Text(
          AppLocalizations.of(context)!.aashirvachan,
          style: textStyle,
        ),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/aashirvachan');
        },
      ),
      DrawerItem.information => ListTile(
        leading: const Icon(Icons.info),
        title: Text(
          AppLocalizations.of(context)!.information,
          style: textStyle,
        ),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/info');
        },
      ),
      DrawerItem.notes => ListTile(
        leading: const Icon(Icons.note),
        title: Text(AppLocalizations.of(context)!.notes, style: textStyle),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/notes');
        },
      ),
      DrawerItem.search => ListTile(
        leading: const Icon(Icons.search),
        title: Text(AppLocalizations.of(context)!.search, style: textStyle),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/search');
        },
      ),
      DrawerItem.readingPlans => ListTile(
        leading: const Icon(Icons.schedule),
        title: Text(
          AppLocalizations.of(context)!.reading_plans,
          style: textStyle,
        ),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/reading_plans');
        },
      ),
      DrawerItem.readingHistory => ListTile(
        leading: const Icon(Icons.history),
        title: Text(
          AppLocalizations.of(context)!.reading_history,
          style: textStyle,
        ),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/readinghistory');
        },
      ),
      DrawerItem.quotesImageGenerator => ListTile(
        leading: const Icon(Icons.format_quote),
        title: Text(
          AppLocalizations.of(context)!.quotes_image_generator,
          style: textStyle,
        ),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/quotes_generator', arguments: {null});
        },
      ),
      DrawerItem.profile => ListTile(
        leading: const Icon(Icons.person),
        title: Text(AppLocalizations.of(context)!.profile, style: textStyle),
        onTap: () async {
          Navigator.pop(context);
          await Navigator.pushNamed(context, '/profile');
          // Refresh profile data when returning from profile page
          _loadUserProfile();
        },
      ),
      DrawerItem.settings => ListTile(
        leading: const Icon(Icons.settings),
        title: Text(AppLocalizations.of(context)!.settings, style: textStyle),
        onTap: () {
          Navigator.pop(context);
          Navigator.pushNamed(context, '/settings');
        },
      ),
      DrawerItem.welcomeTour => ListTile(
        leading: const Icon(Icons.celebration),
        title: Text(
          AppLocalizations.of(context)!.welcome_tour,
          style: textStyle,
        ),
        onTap: () {
          // Show welcome screen for first-time users
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const WelcomeScreen()),
          );
        },
      ),
      DrawerItem.marketingShowcase =>
        kDebugMode
            ? ListTile(
              leading: const Icon(Icons.star),
              title: Text(
                '${AppLocalizations.of(context)!.sakshatSavita} (Debug)',
                style: textStyle,
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/marketing_showcase');
              },
            )
            : const SizedBox.shrink(),
      DrawerItem.migration =>
        kDebugMode
            ? ListTile(
              leading: const Icon(Icons.transfer_within_a_station),
              title: Text("Migration (Debug)", style: textStyle),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/migration');
              },
            )
            : const SizedBox.shrink(),
      DrawerItem.adminpanel =>
        kDebugMode && kIsWeb
            ? ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: Text("Admin Panel (Debug)", style: textStyle),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/admin');
              },
            )
            : const SizedBox.shrink(),
      DrawerItem.logout => ListTile(
        leading: const Icon(Icons.logout),
        title: Text(AppLocalizations.of(context)!.logout, style: textStyle),
        onTap: _logoutEvent,
      ),
    };
  }

  void _logoutEvent() async {
    // Store context-dependent values before async operations
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
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
          MaterialPageRoute(builder: (context) => const GoogleSignInPage()),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Pop the loading indicator
      if (mounted) {
        navigator.pop();
        // Show Firebase Auth specific error
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Authentication error: ${e.message ?? e.code}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Firebase Auth sign out error: ${e.code} - ${e.message}');
    } on FirebaseException catch (e) {
      // Pop the loading indicator
      if (mounted) {
        navigator.pop();
        // Show Firebase specific error
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Firebase error: ${e.message ?? e.code}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Firebase sign out error: ${e.code} - ${e.message}');
    } catch (e) {
      // Pop the loading indicator
      if (mounted) {
        navigator.pop();
        // Show general error
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('Sign out error: $e');
    }
  }
}
