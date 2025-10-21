import 'package:flutter/foundation.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/models/bookuserinfo_model.dart';
import 'package:saxatsavita_flutter/models/reading_history_model.dart';
import 'package:saxatsavita_flutter/models/kiranuserinfo_model.dart';
import 'package:saxatsavita_flutter/models/reading_plan_model.dart';
import 'package:saxatsavita_flutter/services/firebase_sync_service.dart';
import 'package:saxatsavita_flutter/services/reading_history_service.dart';
import 'package:saxatsavita_flutter/services/bookservice.dart';
import 'package:saxatsavita_flutter/services/kiranuser_service.dart';
import 'package:saxatsavita_flutter/services/reading_plan_service.dart';

/// Integration helper for Firebase sync
/// This shows how to integrate the Firebase sync service with your existing services
class FirebaseIntegrationHelper {
  static final FirebaseIntegrationHelper _instance =
      FirebaseIntegrationHelper._internal();
  factory FirebaseIntegrationHelper() => _instance;
  FirebaseIntegrationHelper._internal();

  final FirebaseSyncService _firebaseSync = FirebaseSyncService();

  /// Auto-sync when app settings change
  Future<void> onAppSettingsChanged(AppSettings settings) async {
    debugPrint('App settings changed, syncing to Firebase...');
    await _firebaseSync.syncAppSettings(settings);
  }

  /*
  /// Auto-sync when reading history is added
  Future<void> onReadingHistoryAdded() async {
    debugPrint('Reading history updated, syncing to Firebase...');
    final history = await ReadingHistoryService.loadReadingHistory();
    await _firebaseSync.syncReadingHistory(history);
  }*/

  /// Auto-sync when reading history is added
  Future<void> onNewReadingHistoryAdded(ReadingHistory history) async {
    debugPrint('Reading history updated, syncing to Firebase...$history');
    await _firebaseSync.addReadingHistory(history);
  }

  Future<void> onBookUserInfoChanged(BookUserInfo bookUserInfo) async {
    debugPrint('Book user info changed, syncing to Firebase...');
    await _firebaseSync.syncBookUserInfo([bookUserInfo]);
  }

  /// Auto-sync when kiran user info changes
  Future<void> onKiranUserInfoChanged() async {
    debugPrint('Kiran user info changed, syncing to Firebase...');
    final kiranUserInfo = KiranUserService().kiranUserInfoList;
    await _firebaseSync.syncKiranUserInfo(kiranUserInfo);
  }

  /// Auto-sync single kiran user info change (for efficiency)
  Future<void> onSingleKiranUserInfoChanged(KiranUserInfo kiranUserInfo) async {
    debugPrint('Single kiran user info changed, syncing to Firebase...');
    await _firebaseSync.syncSingleKiranUserInfo(kiranUserInfo);
  }

  /// Auto-sync when reading plan is added
  Future<void> onNewReadingPlanAdded(ReadingPlan plan) async {
    debugPrint('Reading plan added, syncing to Firebase...$plan');
    await _firebaseSync.addReadingPlan(plan);
  }

  /// Auto-sync when reading plan is updated
  Future<void> onReadingPlanUpdated(ReadingPlan plan) async {
    debugPrint('Reading plan updated, syncing to Firebase...$plan');
    await _firebaseSync.updateReadingPlan(plan);
  }

  /// Auto-sync when reading plan is deleted
  Future<void> onReadingPlanDeleted(String planId) async {
    debugPrint('Reading plan deleted, syncing to Firebase...$planId');
    await _firebaseSync.deleteReadingPlan(planId);
  }

  /// Sync all data manually (e.g., on app start or login)
  Future<void> syncAllData() async {
    if (!_firebaseSync.isAuthenticated) {
      debugPrint('User not logged in, skipping sync');
      return;
    }

    debugPrint('Performing full data sync...');

    try {
      // Get current app settings
      final currentSettings = appSettingsNotifier.value;

      // Get current book user info
      final bookUserInfo = Bookservice().bookUserInfoList ?? [];

      // Get current kiran user info
      final kiranUserInfo = KiranUserService().kiranUserInfoList;

      // Get current reading history
      final readingHistory = await ReadingHistoryService.loadReadingHistory();

      // Sync all data
      await _firebaseSync.syncAllUserData(
        appSettings: currentSettings,
        bookUserInfo: bookUserInfo,
        kiranUserInfo: kiranUserInfo,
        readingHistory: readingHistory,
      );

      debugPrint('Full data sync completed successfully');
    } catch (e) {
      debugPrint('Error during full data sync: $e');
    }
  }

  /// Load data from Firebase (e.g., on login or new device)
  Future<void> loadDataFromFirebase() async {
    if (!_firebaseSync.isAuthenticated) {
      debugPrint('User not logged in, skipping load');
      return;
    }

    debugPrint('Loading data from Firebase...');

    try {
      final data = await _firebaseSync.loadAllUserData();

      // Update app settings if available
      if (data['appSettings'] != null) {
        final appSettings = data['appSettings'] as AppSettings;
        appSettingsNotifier.value = appSettings;
        debugPrint('App settings loaded from Firebase');
      }

      // Update book user info if available
      if (data['bookUserInfo'] != null &&
          data['bookUserInfo'] is List &&
          data['bookUserInfo'].isNotEmpty) {
        final bookUserInfoList = data['bookUserInfo'] as List;
        Bookservice().insertBookUserInfoList(bookUserInfoList.cast());
        debugPrint('Book user info loaded from Firebase');
      } else {
        Bookservice()
            .insertDefaultBookUserInfoList(); // Insert default book user info list if not available
      }

      // Update kiran user info if available
      if (data['kiranUserInfo'] != null &&
          data['kiranUserInfo'] is List &&
          data['kiranUserInfo'].isNotEmpty) {
        final kiranUserInfoList = data['kiranUserInfo'] as List;
        KiranUserService().insertKiranUserInfoList(kiranUserInfoList.cast());
        debugPrint('Kiran user info loaded from Firebase');
      }

      // Update reading history if available
      if (data['readingHistory'] != null) {
        final readingHistoryList = data['readingHistory'] as List;
        ReadingHistoryService().readingHistoryList = readingHistoryList.cast();
        debugPrint('Reading history loaded from Firebase');
      }

      // Update reading plans if available
      if (data['readingPlans'] != null &&
          data['readingPlans'] is List &&
          data['readingPlans'].isNotEmpty) {
        final readingPlanList = data['readingPlans'] as List;
        ReadingPlanService().setReadingPlans(readingPlanList.cast());
        debugPrint('Reading plans loaded from Firebase');
      }

      debugPrint('Data loading from Firebase completed');
    } catch (e) {
      debugPrint('Error loading data from Firebase: $e');
    }
  }

  /// Setup automatic sync listeners
  void setupAutoSync() {
    debugPrint('Setting up automatic sync listeners...');

    // Listen to app settings changes
    // appSettingsNotifier.addListener(() {
    //  onAppSettingsChanged(appSettingsNotifier.value);
    //});

    debugPrint('Auto-sync listeners configured');
  }

  Future<void> saveUserDetailsToFirebase() async {
    await _firebaseSync.saveUserDetailsToFirebase();
  }

  Future<void> saveAppleUserDetailsToFirebase(
    String displayName,
    String email,
  ) async {
    await _firebaseSync.saveAppleUserDetailsToFirebase(displayName, email);
  }

  Future<Map<String, String>> getUserInfoSummary() async {
    return await _firebaseSync.getUserInfoSummary();
  }
}

/// Extension methods to add Firebase sync to existing services
extension KiranFirebaseSyncExtensions on KiranUserService {
  Future<void> syncToFirebase() async {
    await FirebaseIntegrationHelper().onKiranUserInfoChanged();
  }

  Future<void> syncSingleToFirebase(KiranUserInfo kiranUserInfo) async {
    await FirebaseIntegrationHelper().onSingleKiranUserInfoChanged(
      kiranUserInfo,
    );
  }
}
