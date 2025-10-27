import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saxatsavita_flutter/models/user_profile_model.dart';

class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _localStorageKey = 'user_profile';

  UserProfile? _cachedProfile;

  /// Get the current user profile
  Future<UserProfile> getUserProfile() async {
    // Return cached profile if available
    if (_cachedProfile != null) {
      return _cachedProfile!;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    try {
      // Try to get from Firebase first
      final doc =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('profile')
              .doc('info')
              .get();

      UserProfile profile;

      if (doc.exists && doc.data() != null) {
        // Load from Firebase
        profile = UserProfile.fromJson(doc.data()!);
      } else {
        // Try to load from local storage
        profile = await _loadFromLocalStorage();

        // If not in local storage, create default profile
        if (profile.firstName.isEmpty) {
          profile = _createDefaultProfile(user);
        }
      }

      _cachedProfile = profile;
      return profile;
    } catch (e) {
      // Fallback to local storage
      final profile = await _loadFromLocalStorage();
      if (profile.firstName.isEmpty) {
        final defaultProfile = _createDefaultProfile(user);
        _cachedProfile = defaultProfile;
        return defaultProfile;
      }
      _cachedProfile = profile;
      return profile;
    }
  }

  /// Update user profile
  Future<void> updateUserProfile(UserProfile profile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final updatedProfile = profile.copyWith(
      email: user.email ?? profile.email,
      updatedAt: DateTime.now(),
    );

    try {
      // Save to Firebase
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('info')
          .set(updatedProfile.toJson(), SetOptions(merge: true));

      // Save to local storage as backup
      await _saveToLocalStorage(updatedProfile);

      // Update cache
      _cachedProfile = updatedProfile;
    } catch (e) {
      // If Firebase fails, at least save locally
      await _saveToLocalStorage(updatedProfile);
      _cachedProfile = updatedProfile;

      // Re-throw the error so UI can show appropriate message
      throw Exception('Failed to sync profile to cloud: ${e.toString()}');
    }
  }

  /// Load profile from local storage
  Future<UserProfile> _loadFromLocalStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = prefs.getString(_localStorageKey);

      if (profileJson != null) {
        final profileMap = json.decode(profileJson) as Map<String, dynamic>;
        return UserProfile.fromJson(profileMap);
      }
    } catch (e) {
      // Ignore errors and return empty profile
    }

    // Return empty profile if nothing found
    final user = FirebaseAuth.instance.currentUser;
    return _createDefaultProfile(user);
  }

  /// Save profile to local storage
  Future<void> _saveToLocalStorage(UserProfile profile) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final profileJson = json.encode(profile.toJson());
      await prefs.setString(_localStorageKey, profileJson);
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Create default profile from Firebase user
  UserProfile _createDefaultProfile(User? user) {
    if (user == null) {
      return UserProfile(
        firstName: '',
        lastName: '',
        city: '',
        email: '',
        createdAt: DateTime.now(),
      );
    }

    // Try to parse display name into first and last name
    String firstName = '';
    String lastName = '';

    if (user.displayName != null && user.displayName!.isNotEmpty) {
      final nameParts = user.displayName!.trim().split(' ');
      firstName = nameParts.isNotEmpty ? nameParts.first : '';
      lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    }

    return UserProfile(
      firstName: firstName,
      lastName: lastName,
      city: '',
      email: user.email ?? '',
      createdAt: DateTime.now(),
    );
  }

  /// Clear cached profile
  void clearCache() {
    _cachedProfile = null;
  }

  /// Delete user profile (for account deletion)
  Future<void> deleteUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Delete from Firebase
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('info')
          .delete();
    } catch (e) {
      // Ignore Firebase errors
    }

    try {
      // Delete from local storage
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localStorageKey);
    } catch (e) {
      // Ignore local storage errors
    }

    // Clear cache
    clearCache();
  }

  /// Sync profile from Firebase (useful for multi-device sync)
  Future<UserProfile?> syncFromFirebase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final doc =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('profile')
              .doc('info')
              .get();

      if (doc.exists && doc.data() != null) {
        final profile = UserProfile.fromJson(doc.data()!);

        // Save to local storage
        await _saveToLocalStorage(profile);

        // Update cache
        _cachedProfile = profile;

        return profile;
      }
    } catch (e) {
      // Ignore sync errors
    }

    return null;
  }
}
