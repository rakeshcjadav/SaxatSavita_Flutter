import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:saxatsavita_flutter/auth/pages/google_sign_in_page.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/services/cache_service.dart';
import 'package:saxatsavita_flutter/services/user_profile_service.dart';
import 'package:saxatsavita_flutter/models/user_profile_model.dart';

class ProfilePage extends StatefulWidget {
  final bool continueAfterProfile;
  final bool showScaffold;

  const ProfilePage({
    super.key,
    required this.continueAfterProfile,
    this.showScaffold = true,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _cityController = TextEditingController();

  final UserProfileService _profileService = UserProfileService();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await _profileService.getUserProfile();
      setState(() {
        _firstNameController.text = profile.firstName;
        _lastNameController.text = profile.lastName;
        _cityController.text = profile.city;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final profile = UserProfile(
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        city: _cityController.text.trim(),
        email: FirebaseAuth.instance.currentUser?.email ?? '',
      );

      await _profileService.updateUserProfile(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.profile_updated_successfully,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.profile_update_failed),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          // Navigate to main navigation page
          if (widget.continueAfterProfile) {
            Navigator.pushReplacementNamed(context, '/main');
          }
        });
      }
    }
  }

  bool _isProfileComplete() {
    return _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty &&
        _cityController.text.trim().isNotEmpty;
  }

  Future<bool> _onWillPop() async {
    // Allow back navigation if profile is complete
    if (_isProfileComplete()) {
      return true;
    }

    // Show dialog asking user to complete profile
    final shouldExit = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.incomplete_profile),
            content: Text(
              AppLocalizations.of(context)!.please_complete_profile,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context)!.continue_editing),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppLocalizations.of(context)!.exit_anyway),
              ),
            ],
          ),
    );

    return shouldExit ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final body =
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : GestureDetector(
              onTap: () {
                // Dismiss keyboard and context menu when tapping outside
                FocusScope.of(context).unfocus();
              },
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Header
                      Center(
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor:
                                  Theme.of(context).colorScheme.primary,
                              backgroundImage:
                                  FirebaseAuth.instance.currentUser?.photoURL !=
                                          null
                                      ? NetworkImage(
                                        FirebaseAuth
                                            .instance
                                            .currentUser!
                                            .photoURL!,
                                      )
                                      : null,
                              child:
                                  FirebaseAuth.instance.currentUser?.photoURL ==
                                          null
                                      ? Icon(
                                        Icons.person,
                                        size: 50,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.onPrimary,
                                      )
                                      : null,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              FirebaseAuth.instance.currentUser?.email ?? '',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Profile Form
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.personal_information,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),

                              // First Name
                              TextFormField(
                                controller: _firstNameController,
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(context)!.first_name,
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return AppLocalizations.of(
                                      context,
                                    )!.first_name_required;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Last Name
                              TextFormField(
                                controller: _lastNameController,
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(context)!.last_name,
                                  prefixIcon: const Icon(Icons.person_outline),
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return AppLocalizations.of(
                                      context,
                                    )!.last_name_required;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // City
                              TextFormField(
                                controller: _cityController,
                                decoration: InputDecoration(
                                  labelText:
                                      AppLocalizations.of(
                                        context,
                                      )!.city_or_village,
                                  prefixIcon: const Icon(Icons.location_city),
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return AppLocalizations.of(
                                      context,
                                    )!.city_or_village_required;
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),

                              // Save Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveProfile,
                                  child:
                                      _isSaving
                                          ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : Text(
                                            AppLocalizations.of(
                                              context,
                                            )!.save_profile,
                                          ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              // Logout Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade300,
                                  ),
                                  onPressed: _isSaving ? null : _logoutEvent,
                                  child:
                                      _isSaving
                                          ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                          : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                Icons.logout,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                AppLocalizations.of(
                                                  context,
                                                )!.logout,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

    if (!widget.showScaffold) {
      return body;
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: buildAppBar(
          context,
          title: AppLocalizations.of(context)!.profile,
        ),
        body: body,
      ),
    );
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
