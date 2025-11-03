import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/models/bookuserinfo_model.dart';
import 'package:saxatsavita_flutter/models/kiranuserinfo_model.dart';
import 'package:saxatsavita_flutter/models/reading_history_model.dart';
import 'package:saxatsavita_flutter/models/reading_plan_model.dart';

/// Base interface for FirebaseSyncService
/// Platform-specific implementations will implement this interface
abstract class FirebaseSyncServiceBase {
  // Properties
  String? get currentUserId;
  bool get isAuthenticated;
  dynamic get userDoc;

  // App Settings
  Future<void> syncAppSettings(AppSettings settings);
  Future<AppSettings?> loadAppSettings();

  // Book User Info
  Future<void> syncBookUserInfo(List<BookUserInfo> bookUserInfoList);
  Future<List<BookUserInfo>> loadBookUserInfo();
  Future<void> syncSingleBookUserInfo(BookUserInfo info);

  // Kiran User Info
  Future<void> syncKiranUserInfo(List<KiranUserInfo> kiranUserInfoList);
  Future<List<KiranUserInfo>> loadKiranUserInfo();
  Future<void> syncSingleKiranUserInfo(KiranUserInfo info);

  // Reading History
  Future<void> syncReadingHistory(List<ReadingHistory> historyList);
  Future<void> addReadingHistory(ReadingHistory history);
  Future<List<ReadingHistory>> loadReadingHistory();
  Future<List<ReadingPlan>> loadReadingPlans();
  Future<void> syncSingleReadingHistory(ReadingHistory history);

  // Reading Plan
  Future<void> addReadingPlan(ReadingPlan plan);
  Future<void> updateReadingPlan(ReadingPlan plan);
  Future<void> deleteReadingPlan(String planId);

  // Batch Operations
  Future<void> syncAllUserData({
    AppSettings? appSettings,
    List<BookUserInfo>? bookUserInfo,
    List<KiranUserInfo>? kiranUserInfo,
    List<ReadingHistory>? readingHistory,
  });
  Future<Map<String, dynamic>> loadAllUserData();

  // Real-time Listeners
  Stream<AppSettings?> watchAppSettings();
  Stream<List<ReadingHistory>> watchReadingHistory();

  // Utility Methods
  Future<void> clearAllUserData();
  Future<Map<String, int>> getUserDataStats();
  Future<void> saveUserDetailsToFirebase(String displayName, String email);
  Future<bool> deleteAccount({dynamic reauthCredential});
  Future<void> deleteReadingHistory(ReadingHistory historyToDelete);
}
