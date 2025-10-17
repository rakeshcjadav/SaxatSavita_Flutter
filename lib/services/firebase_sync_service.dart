import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/models/bookuserinfo_model.dart';
import 'package:saxatsavita_flutter/models/kiranuserinfo_model.dart';
import 'package:saxatsavita_flutter/models/reading_history_model.dart';
import 'package:saxatsavita_flutter/models/reading_plan_model.dart';

class FirebaseSyncService {
  static final FirebaseSyncService _instance = FirebaseSyncService._internal();
  factory FirebaseSyncService() => _instance;
  FirebaseSyncService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Check if user is authenticated
  bool get isAuthenticated => _auth.currentUser != null;

  /// User's document reference
  DocumentReference? get userDoc =>
      currentUserId != null
          ? _firestore.collection('users').doc(currentUserId)
          : null;

  // =================== APP SETTINGS ===================

  /// Sync AppSettings to Firebase
  Future<void> syncAppSettings(AppSettings settings) async {
    if (!isAuthenticated) {
      debugPrint('User not authenticated, cannot sync AppSettings');
      return;
    }

    try {
      await userDoc!.collection('appSettings').doc('settings').set({
        ...settings.toJson(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint('AppSettings synced to Firebase successfully');
    } catch (e) {
      debugPrint('Error syncing AppSettings to Firebase: $e');
    }
  }

  /// Load AppSettings from Firebase
  Future<AppSettings?> loadAppSettings() async {
    if (!isAuthenticated) {
      debugPrint('User not authenticated, cannot load AppSettings');
      return null;
    }

    try {
      final doc =
          await userDoc!.collection('appSettings').doc('settings').get();
      if (doc.exists && doc.data() != null) {
        return AppSettings.fromJson(doc.data()!);
      }
    } catch (e) {
      debugPrint('Error loading AppSettings from Firebase: $e');
    }
    return null;
  }

  // =================== BOOK USER INFO ===================

  /// Sync BookUserInfo list to Firebase
  Future<void> syncBookUserInfo(List<BookUserInfo> bookUserInfoList) async {
    if (!isAuthenticated) {
      debugPrint('User not authenticated, cannot sync BookUserInfo');
      return;
    }

    try {
      final batch = _firestore.batch();
      final collection = userDoc!.collection('bookUserInfo');

      for (final info in bookUserInfoList) {
        final docRef = collection.doc('${info.partNumber}');
        final jsonData = info.toJson();

        // Validate bookmark queue integrity before syncing
        if (jsonData['bookmarks'] is List) {
          final bookmarks = jsonData['bookmarks'] as List;
          if (bookmarks.length > 5) {
            debugPrint(
              'Warning: Bookmark queue has more than 5 items for part ${info.partNumber}. Trimming to 5.',
            );
            jsonData['bookmarks'] = bookmarks.take(5).toList();
          }
        }

        batch.set(docRef, {
          ...jsonData,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint(
        'BookUserInfo synced to Firebase successfully (${bookUserInfoList.length} items)',
      );
    } catch (e) {
      debugPrint('Error syncing BookUserInfo to Firebase: $e');
    }
  }

  /// Load BookUserInfo list from Firebase
  Future<List<BookUserInfo>> loadBookUserInfo() async {
    if (!isAuthenticated) {
      debugPrint('User not authenticated, cannot load BookUserInfo');
      return [];
    }

    try {
      final snapshot = await userDoc!.collection('bookUserInfo').get();
      final loadedItems = <BookUserInfo>[];

      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();

          // Handle migration from old format without bookmarks array
          if (data['bookmarks'] == null && data['bookmarkKiranIndex'] != null) {
            debugPrint('Migrating old bookmark format for part ${doc.id}');
            data['bookmarks'] = [
              {
                'kiranIndex': data['bookmarkKiranIndex'],
                'createdAt':
                    data['updatedAt'] ?? DateTime.now().toIso8601String(),
              },
            ];
          }

          final bookUserInfo = BookUserInfo.fromJson(data);
          loadedItems.add(bookUserInfo);
        } catch (e) {
          debugPrint('Error parsing BookUserInfo for document ${doc.id}: $e');
          // Continue with other documents even if one fails
        }
      }

      debugPrint(
        'BookUserInfo loaded from Firebase successfully (${loadedItems.length} items)',
      );
      return loadedItems;
    } catch (e) {
      debugPrint('Error loading BookUserInfo from Firebase: $e');
      return [];
    }
  }

  /// Sync single BookUserInfo to Firebase
  Future<void> syncSingleBookUserInfo(BookUserInfo info) async {
    if (!isAuthenticated) return;

    try {
      final jsonData = info.toJson();

      // Validate bookmark queue integrity before syncing
      if (jsonData['bookmarks'] is List) {
        final bookmarks = jsonData['bookmarks'] as List;
        if (bookmarks.length > 5) {
          debugPrint(
            'Warning: Bookmark queue has more than 5 items for part ${info.partNumber}. Trimming to 5.',
          );
          jsonData['bookmarks'] = bookmarks.take(5).toList();
        }
      }

      await userDoc!.collection('bookUserInfo').doc('${info.partNumber}').set({
        ...jsonData,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      debugPrint(
        'Single BookUserInfo synced for part ${info.partNumber} with ${info.bookmarks.length} bookmarks',
      );
    } catch (e) {
      debugPrint('Error syncing single BookUserInfo: $e');
    }
  }

  // =================== KIRAN USER INFO ===================

  /// Sync KiranUserInfo list to Firebase
  Future<void> syncKiranUserInfo(List<KiranUserInfo> kiranUserInfoList) async {
    if (!isAuthenticated) {
      debugPrint('User not authenticated, cannot sync KiranUserInfo');
      return;
    }

    try {
      final batch = _firestore.batch();
      final collection = userDoc!.collection('kiranUserInfo');

      for (final info in kiranUserInfoList) {
        final docRef = collection.doc('${info.kiranIndex}');
        batch.set(docRef, {
          ...info.toJson(),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint('KiranUserInfo synced to Firebase successfully');
    } catch (e) {
      debugPrint('Error syncing KiranUserInfo to Firebase: $e');
    }
  }

  /// Load KiranUserInfo list from Firebase
  Future<List<KiranUserInfo>> loadKiranUserInfo() async {
    if (!isAuthenticated) {
      debugPrint('User not authenticated, cannot load KiranUserInfo');
      return [];
    }

    try {
      final snapshot = await userDoc!.collection('kiranUserInfo').get();
      return snapshot.docs
          .map((doc) => KiranUserInfo.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error loading KiranUserInfo from Firebase: $e');
      return [];
    }
  }

  /// Sync single KiranUserInfo to Firebase
  Future<void> syncSingleKiranUserInfo(KiranUserInfo info) async {
    if (!isAuthenticated) return;

    try {
      await userDoc!.collection('kiranUserInfo').doc('${info.kiranIndex}').set({
        ...info.toJson(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error syncing single KiranUserInfo: $e');
    }
  }

  // =================== READING HISTORY ===================

  /// Sync ReadingHistory list to Firebase
  Future<void> syncReadingHistory(List<ReadingHistory> historyList) async {
    if (!isAuthenticated) {
      debugPrint('User not authenticated, cannot sync ReadingHistory');
      return;
    }

    try {
      final batch = _firestore.batch();
      final collection = userDoc!.collection('readingHistory');

      for (final history in historyList) {
        // Use timestamp as document ID for uniqueness
        final docId = history.createdAt.millisecondsSinceEpoch.toString();
        final docRef = collection.doc(docId);

        batch.set(docRef, {
          ...history.toJson(),
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      debugPrint('ReadingHistory synced to Firebase successfully');
    } catch (e) {
      debugPrint('Error syncing ReadingHistory to Firebase: $e');
    }
  }

  Future<void> addReadingHistory(ReadingHistory history) async {
    if (!isAuthenticated) {
      debugPrint('User not authenticated, cannot sync ReadingHistory');
      return;
    }

    try {
      final docId = history.createdAt.millisecondsSinceEpoch.toString();
      await userDoc!.collection('readingHistory').doc(docId).set({
        ...history.toJson(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error syncing single ReadingHistory: $e');
    }
  }

  /// Load ReadingHistory list from Firebase
  Future<List<ReadingHistory>> loadReadingHistory() async {
    if (!isAuthenticated) {
      debugPrint('User not authenticated, cannot load ReadingHistory');
      return [];
    }

    try {
      final snapshot =
          await userDoc!
              .collection('readingHistory')
              .orderBy('createdAt', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => ReadingHistory.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error loading ReadingHistory from Firebase: $e');
      return [];
    }
  }

  // Load ReadingPlans from Firebase
  Future<List<ReadingPlan>> loadReadingPlans() async {
    if (!isAuthenticated) {
      debugPrint('User not authenticated, cannot load ReadingPlans');
      return [];
    }

    try {
      final snapshot = await userDoc!.collection('readingPlans').get();
      return snapshot.docs
          .map((doc) => ReadingPlan.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error loading ReadingPlans from Firebase: $e');
      return [];
    }
  }

  /// Sync single ReadingHistory entry to Firebase
  Future<void> syncSingleReadingHistory(ReadingHistory history) async {
    if (!isAuthenticated) return;

    try {
      final docId = history.createdAt.millisecondsSinceEpoch.toString();
      await userDoc!.collection('readingHistory').doc(docId).set({
        ...history.toJson(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error syncing single ReadingHistory: $e');
    }
  }

  // =================== READING PLAN ===================

  Future<void> addReadingPlan(ReadingPlan plan) async {
    if (!isAuthenticated) {
      debugPrint('User not authenticated, cannot sync ReadingPlan');
      return;
    }

    try {
      await userDoc!.collection('readingPlans').doc(plan.id).set({
        ...plan.toJson(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      debugPrint('ReadingPlan added to Firebase successfully');
    } catch (e) {
      debugPrint('Error adding ReadingPlan to Firebase: $e');
    }
  }

  // Update existing ReadingPlan
  Future<void> updateReadingPlan(ReadingPlan plan) async {
    if (!isAuthenticated) {
      debugPrint('User not authenticated, cannot update ReadingPlan');
      return;
    }

    try {
      await userDoc!.collection('readingPlans').doc(plan.id).set({
        ...plan.toJson(),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('ReadingPlan updated in Firebase successfully');
    } catch (e) {
      debugPrint('Error updating ReadingPlan in Firebase: $e');
    }
  }

  Future<void> deleteReadingPlan(String planId) async {
    if (!isAuthenticated) {
      debugPrint('User not authenticated, cannot delete ReadingPlan');
      return;
    }

    try {
      await userDoc!.collection('readingPlans').doc(planId).delete();
      debugPrint('ReadingPlan deleted from Firebase successfully');
    } catch (e) {
      debugPrint('Error deleting ReadingPlan from Firebase: $e');
    }
  }

  // =================== BATCH OPERATIONS ===================

  /// Sync all user data to Firebase
  Future<void> syncAllUserData({
    AppSettings? appSettings,
    List<BookUserInfo>? bookUserInfo,
    List<KiranUserInfo>? kiranUserInfo,
    List<ReadingHistory>? readingHistory,
  }) async {
    if (!isAuthenticated) {
      debugPrint('User not authenticated, cannot sync user data');
      return;
    }

    try {
      debugPrint('Starting full user data sync to Firebase...');

      // Sync in parallel for better performance
      final futures = <Future>[];

      if (appSettings != null) {
        futures.add(syncAppSettings(appSettings));
      }

      if (bookUserInfo != null) {
        futures.add(syncBookUserInfo(bookUserInfo));
      }

      if (kiranUserInfo != null) {
        futures.add(syncKiranUserInfo(kiranUserInfo));
      }

      if (readingHistory != null) {
        futures.add(syncReadingHistory(readingHistory));
      }

      await Future.wait(futures);
      debugPrint('All user data synced to Firebase successfully');
    } catch (e) {
      debugPrint('Error syncing all user data to Firebase: $e');
    }
  }

  /// Load all user data from Firebase
  Future<Map<String, dynamic>> loadAllUserData() async {
    if (!isAuthenticated) {
      debugPrint('User not authenticated, cannot load user data');
      return {};
    }

    try {
      debugPrint('Loading all user data from Firebase...');

      // Load in parallel for better performance
      final results = await Future.wait([
        loadAppSettings(),
        loadBookUserInfo(),
        loadKiranUserInfo(),
        loadReadingHistory(),
        loadReadingPlans(),
      ]);

      final data = {
        'appSettings': results[0],
        'bookUserInfo': results[1],
        'kiranUserInfo': results[2],
        'readingHistory': results[3],
        'readingPlans': results[4],
      };

      debugPrint('All user data loaded from Firebase successfully');
      return data;
    } catch (e) {
      debugPrint('Error loading all user data from Firebase: $e');
      return {};
    }
  }

  // =================== REAL-TIME LISTENERS ===================

  /// Listen to AppSettings changes
  Stream<AppSettings?> watchAppSettings() {
    if (!isAuthenticated) {
      return Stream.value(null);
    }

    return userDoc!.collection('appSettings').doc('settings').snapshots().map((
      doc,
    ) {
      if (doc.exists && doc.data() != null) {
        return AppSettings.fromJson(doc.data()!);
      }
      return null;
    });
  }

  /// Listen to ReadingHistory changes
  Stream<List<ReadingHistory>> watchReadingHistory() {
    if (!isAuthenticated) {
      return Stream.value([]);
    }

    return userDoc!
        .collection('readingHistory')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ReadingHistory.fromJson(doc.data()))
              .toList();
        });
  }

  // =================== UTILITY METHODS ===================

  /// Clear all user data from Firebase (useful for logout)
  Future<void> clearAllUserData() async {
    if (!isAuthenticated) return;

    try {
      final batch = _firestore.batch();

      // Get all subcollections
      final collections = [
        'appSettings',
        'bookUserInfo',
        'kiranUserInfo',
        'readingHistory',
      ];

      for (final collectionName in collections) {
        final snapshot = await userDoc!.collection(collectionName).get();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
      }

      await batch.commit();
      debugPrint('All user data cleared from Firebase');
    } catch (e) {
      debugPrint('Error clearing user data from Firebase: $e');
    }
  }

  /// Get user data statistics
  Future<Map<String, int>> getUserDataStats() async {
    if (!isAuthenticated) return {};

    try {
      final futures = await Future.wait([
        userDoc!.collection('bookUserInfo').count().get(),
        userDoc!.collection('kiranUserInfo').count().get(),
        userDoc!.collection('readingHistory').count().get(),
      ]);

      return {
        'bookUserInfo': futures[0].count ?? 0,
        'kiranUserInfo': futures[1].count ?? 0,
        'readingHistory': futures[2].count ?? 0,
      };
    } catch (e) {
      debugPrint('Error getting user data stats: $e');
      return {};
    }
  }

  Future<void> saveUserDetailsToFirebase() async {
    if (!isAuthenticated) return;
    // Implement saving user details logic here
    debugPrint('Saving user details to Firebase...');
    // For example, you might want to save displayName and email
    final user = _auth.currentUser;
    if (user != null) {
      await userDoc!.set({
        'displayName': user.displayName,
        'email': user.email,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('User details saved to Firebase successfully');
    } else {
      debugPrint(
        'User not authenticated, cannot save user details',
      ); // Handle the case where the user is not authenticated
    }
  }
}
