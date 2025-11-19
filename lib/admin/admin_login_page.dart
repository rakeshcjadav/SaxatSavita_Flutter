import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:saxatsavita_flutter/admin/admin_panel_page.dart';
import 'package:saxatsavita_flutter/admin/services/admin_service.dart';
import 'package:flutter/foundation.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final AdminService _adminService = AdminService();
  bool _isLoading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _checkExistingAuth();
  }

  Future<void> _checkExistingAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _checkAdminAccessAndNavigate();
    }
  }

  Future<void> _checkAdminAccessAndNavigate() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user?.email == null) {
        throw Exception('No email found');
      }

      final isAdmin = await _adminService.isUserAdmin(user!.email!);
      if (isAdmin) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const AdminPanelPage()),
          );
        }
      } else {
        throw Exception('Access denied - Admin privileges required');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      // Web-specific Google Sign-In approach
      if (kIsWeb) {
        // For web, use Firebase Auth directly with Google provider
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');

        // Use signInWithPopup for web
        final UserCredential result = await FirebaseAuth.instance
            .signInWithPopup(googleProvider);

        if (result.user?.email == null) {
          throw Exception('No email found in Google account');
        }

        await _checkAdminAccessAndNavigate();
      } else {
        // Mobile approach (existing code)
        await GoogleSignIn.instance.signOut();
        await FirebaseAuth.instance.signOut();

        final GoogleSignInAccount googleUser =
            await GoogleSignIn.instance.authenticate();

        final GoogleSignInAuthentication googleAuth = googleUser.authentication;

        if (googleAuth.idToken == null) {
          throw Exception('Failed to get Google ID token');
        }

        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );

        await FirebaseAuth.instance.signInWithCredential(credential);
        await _checkAdminAccessAndNavigate();
      }
    } catch (e) {
      if (e.toString().contains('canceled') ||
          e.toString().contains('cancelled') ||
          e.toString().contains('popup-closed-by-user')) {
        // User cancelled - just stop loading
        setState(() {
          _isLoading = false;
        });
        return;
      }
      setState(() {
        _error = 'Sign-in failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Saxat Savita - Admin Access'),
        centerTitle: true,
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo/Icon
              Icon(
                Icons.admin_panel_settings,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),

              const SizedBox(height: 32),

              // Title
              Text(
                'Admin Panel Access',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                'Sign in with your admin account to access the admin panel',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 48),

              // Error message
              if (_error.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _error,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Sign in button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _signInWithGoogle,
                  icon:
                      _isLoading
                          ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : const Icon(Icons.login, size: 24),
                  label: Text(
                    _isLoading ? 'Signing in...' : 'Sign in with Google',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Admin info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Admin Access Required',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Only authorized administrators can access this panel. Contact the system administrator if you need access.',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Back to app button
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Back to App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
