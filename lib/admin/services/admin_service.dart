import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:saxatsavita_flutter/admin/models/admin_user_data.dart';

class AdminService {
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // List of admin email addresses
  static const List<String> _adminEmails = [
    'rakeshcjadav@gmail.com', // Main admin email
    'admin@saxatsavita.com',
    'contact@saxatsavita.com',
    // Add more admin emails as needed
  ];

  /// Check if the given email has admin privileges
  Future<bool> isUserAdmin(String email) async {
    // Check against hardcoded list first
    if (_adminEmails.contains(email.toLowerCase())) {
      return true;
    }

    // Optionally check against Firestore admin collection
    try {
      final adminDoc =
          await _firestore.collection('admins').doc(email.toLowerCase()).get();
      return adminDoc.exists && adminDoc.data()?['isActive'] == true;
    } catch (e) {
      debugPrint('Error checking admin status: $e');
      return false;
    }
  }

  /// Get all users with their complete data
  Future<List<AdminUserData>> getAllUsers() async {
    try {
      final users = <AdminUserData>[];

      // Get all user documents
      final usersSnapshot = await _firestore.collection('users').get();

      for (final userDoc in usersSnapshot.docs) {
        try {
          final userData = await _getUserCompleteData(userDoc.id);
          if (userData != null) {
            users.add(userData);
          }
        } catch (e) {
          debugPrint('Error loading data for user ${userDoc.id}: $e');
          // Continue with other users even if one fails
        }
      }

      return users;
    } catch (e) {
      debugPrint('Error getting all users: $e');
      rethrow;
    }
  }

  /// Get complete data for a specific user
  Future<AdminUserData?> getUserData(String userId) async {
    return await _getUserCompleteData(userId);
  }

  /// Private method to get complete user data
  Future<AdminUserData?> _getUserCompleteData(String userId) async {
    try {
      final userDocRef = _firestore.collection('users').doc(userId);

      // Get user auth data (if available)
      Map<String, dynamic> userData = {};
      try {
        final authUsers =
            await _firestore.collection('userMetadata').doc(userId).get();
        if (authUsers.exists) {
          userData = authUsers.data() ?? {};
        }
      } catch (e) {
        debugPrint('No auth metadata for user $userId: $e');
      }

      // Get app settings
      Map<String, dynamic> appSettings = {};
      try {
        final settingsDoc =
            await userDocRef.collection('appSettings').doc('settings').get();
        if (settingsDoc.exists) {
          appSettings = settingsDoc.data() ?? {};
        }
      } catch (e) {
        debugPrint('No app settings for user $userId: $e');
      }

      // Get book user info
      List<Map<String, dynamic>> bookUserInfo = [];
      try {
        final bookSnapshot = await userDocRef.collection('bookUserInfo').get();
        bookUserInfo =
            bookSnapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList();
      } catch (e) {
        debugPrint('No book user info for user $userId: $e');
      }

      // Get kiran user info
      List<Map<String, dynamic>> kiranUserInfo = [];
      try {
        final kiranSnapshot =
            await userDocRef.collection('kiranUserInfo').get();
        kiranUserInfo =
            kiranSnapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList();
      } catch (e) {
        debugPrint('No kiran user info for user $userId: $e');
      }

      // Get reading history
      List<Map<String, dynamic>> readingHistory = [];
      try {
        final historySnapshot =
            await userDocRef.collection('readingHistory').get();
        readingHistory =
            historySnapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList();
      } catch (e) {
        debugPrint('No reading history for user $userId: $e');
      }

      // Get reading plans
      List<Map<String, dynamic>> readingPlans = [];
      try {
        final plansSnapshot = await userDocRef.collection('readingPlans').get();
        readingPlans =
            plansSnapshot.docs
                .map((doc) => {'id': doc.id, ...doc.data()})
                .toList();
      } catch (e) {
        debugPrint('No reading plans for user $userId: $e');
      }

      // Get user profile
      Map<String, dynamic> userProfile = {};
      try {
        final profileDoc =
            await userDocRef.collection('profile').doc('info').get();
        if (profileDoc.exists) {
          userProfile = profileDoc.data() ?? {};
        }
      } catch (e) {
        debugPrint('No user profile for user $userId: $e');
      }

      // If we have at least some data, create the AdminUserData object
      if (userData.isNotEmpty ||
          appSettings.isNotEmpty ||
          bookUserInfo.isNotEmpty ||
          userProfile.isNotEmpty) {
        return AdminUserData.fromFirestore(
          userId: userId,
          userData: userData,
          appSettings: appSettings,
          bookUserInfo: bookUserInfo,
          kiranUserInfo: kiranUserInfo,
          readingHistory: readingHistory,
          readingPlans: readingPlans,
          userProfile: userProfile,
        );
      }

      return null;
    } catch (e) {
      debugPrint('Error getting user data for $userId: $e');
      return null;
    }
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final users = await getAllUsers();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thisWeek = today.subtract(const Duration(days: 7));
      final thisMonth = today.subtract(const Duration(days: 30));

      int activeToday = 0;
      int activeThisWeek = 0;
      int activeThisMonth = 0;
      int totalReadings = 0;
      int totalBookmarks = 0;

      Map<String, int> providerCounts = {};
      Map<String, int> partCompletions = {};

      for (final user in users) {
        // Count active users
        if (user.lastActivityDate != null) {
          final lastActivity = DateTime(
            user.lastActivityDate!.year,
            user.lastActivityDate!.month,
            user.lastActivityDate!.day,
          );

          if (lastActivity.isAtSameMomentAs(today) ||
              lastActivity.isAfter(today)) {
            activeToday++;
          }
          if (lastActivity.isAfter(thisWeek)) {
            activeThisWeek++;
          }
          if (lastActivity.isAfter(thisMonth)) {
            activeThisMonth++;
          }
        }

        // Count readings and bookmarks
        totalReadings += user.totalReadings;
        totalBookmarks += user.totalBookmarks;

        // Count by provider
        providerCounts[user.signInProvider] =
            (providerCounts[user.signInProvider] ?? 0) + 1;

        // Count part completions
        for (final part in user.bookUserInfo) {
          if (part['isCompleted'] == true) {
            final partKey = 'Part ${part['partNumber']}';
            partCompletions[partKey] = (partCompletions[partKey] ?? 0) + 1;
          }
        }
      }

      return {
        'totalUsers': users.length,
        'activeToday': activeToday,
        'activeThisWeek': activeThisWeek,
        'activeThisMonth': activeThisMonth,
        'totalReadings': totalReadings,
        'totalBookmarks': totalBookmarks,
        'providerBreakdown': providerCounts,
        'partCompletions': partCompletions,
        'averageReadingsPerUser':
            users.isNotEmpty ? totalReadings / users.length : 0,
        'averageBookmarksPerUser':
            users.isNotEmpty ? totalBookmarks / users.length : 0,
      };
    } catch (e) {
      debugPrint('Error getting user stats: $e');
      rethrow;
    }
  }

  /// Export all user data
  Future<Map<String, dynamic>> exportAllData() async {
    try {
      final users = await getAllUsers();
      final stats = await getUserStats();

      return {
        'exportDate': DateTime.now().toIso8601String(),
        'totalUsers': users.length,
        'statistics': stats,
        'users': users.map((user) => user.toJson()).toList(),
      };
    } catch (e) {
      debugPrint('Error exporting data: $e');
      rethrow;
    }
  }

  /// Search users by various criteria
  Future<List<AdminUserData>> searchUsers({
    String? email,
    String? displayName,
    String? provider,
    DateTime? createdAfter,
    DateTime? createdBefore,
    bool? hasReadings,
    int? minimumReadings,
  }) async {
    try {
      final allUsers = await getAllUsers();

      return allUsers.where((user) {
        // Email filter
        if (email != null &&
            !user.email.toLowerCase().contains(email.toLowerCase())) {
          return false;
        }

        // Display name filter
        if (displayName != null &&
            !user.displayName.toLowerCase().contains(
              displayName.toLowerCase(),
            )) {
          return false;
        }

        // Provider filter
        if (provider != null &&
            user.signInProvider.toLowerCase() != provider.toLowerCase()) {
          return false;
        }

        // Created date filters
        if (createdAfter != null &&
            (user.createdAt == null ||
                user.createdAt!.isBefore(createdAfter))) {
          return false;
        }

        if (createdBefore != null &&
            (user.createdAt == null ||
                user.createdAt!.isAfter(createdBefore))) {
          return false;
        }

        // Readings filters
        if (hasReadings != null) {
          if (hasReadings && user.totalReadings == 0) {
            return false;
          }
          if (!hasReadings && user.totalReadings > 0) {
            return false;
          }
        }

        if (minimumReadings != null && user.totalReadings < minimumReadings) {
          return false;
        }

        return true;
      }).toList();
    } catch (e) {
      debugPrint('Error searching users: $e');
      rethrow;
    }
  }

  /// Add admin email (only callable by existing admins)
  Future<void> addAdmin(String email) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Not authenticated');
      }

      final isCurrentUserAdmin = await isUserAdmin(currentUser.email ?? '');
      if (!isCurrentUserAdmin) {
        throw Exception('Only admins can add other admins');
      }

      await _firestore.collection('admins').doc(email.toLowerCase()).set({
        'email': email.toLowerCase(),
        'isActive': true,
        'addedBy': currentUser.email,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding admin: $e');
      rethrow;
    }
  }

  /// Remove admin email (only callable by existing admins)
  Future<void> removeAdmin(String email) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw Exception('Not authenticated');
      }

      final isCurrentUserAdmin = await isUserAdmin(currentUser.email ?? '');
      if (!isCurrentUserAdmin) {
        throw Exception('Only admins can remove other admins');
      }

      // Don't allow removing hardcoded admins
      if (_adminEmails.contains(email.toLowerCase())) {
        throw Exception('Cannot remove hardcoded admin');
      }

      await _firestore.collection('admins').doc(email.toLowerCase()).update({
        'isActive': false,
        'removedBy': currentUser.email,
        'removedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error removing admin: $e');
      rethrow;
    }
  }
}
