import 'package:flutter/foundation.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/models/bookuserinfo_model.dart';
import 'package:saxatsavita_flutter/models/kiranuserinfo_model.dart';
import 'package:saxatsavita_flutter/models/reading_history_model.dart';
import 'package:saxatsavita_flutter/models/reading_plan_model.dart';
import 'firebase_sync_service_base.dart';

/// Dummy FirebaseSyncService implementation for web platform
/// All methods do nothing and return empty/null values
class FirebaseSyncServiceWeb implements FirebaseSyncServiceBase {
  static final FirebaseSyncServiceWeb _instance =
      FirebaseSyncServiceWeb._internal();
  factory FirebaseSyncServiceWeb() => _instance;
  FirebaseSyncServiceWeb._internal();

  @override
  String? get currentUserId => null;

  @override
  bool get isAuthenticated => false;

  @override
  dynamic get userDoc => null;

  // =================== APP SETTINGS ===================

  @override
  Future<void> syncAppSettings(AppSettings settings) async {
    debugPrint('[Web] syncAppSettings: No-op');
  }

  @override
  Future<AppSettings?> loadAppSettings() async {
    debugPrint('[Web] loadAppSettings: No-op, returning null');
    return null;
  }

  // =================== BOOK USER INFO ===================

  @override
  Future<void> syncBookUserInfo(List<BookUserInfo> bookUserInfoList) async {
    debugPrint('[Web] syncBookUserInfo: No-op');
  }

  @override
  Future<List<BookUserInfo>> loadBookUserInfo() async {
    debugPrint('[Web] loadBookUserInfo: No-op, returning empty list');
    return [];
  }

  @override
  Future<void> syncSingleBookUserInfo(BookUserInfo info) async {
    debugPrint('[Web] syncSingleBookUserInfo: No-op');
  }

  // =================== KIRAN USER INFO ===================

  @override
  Future<void> syncKiranUserInfo(List<KiranUserInfo> kiranUserInfoList) async {
    debugPrint('[Web] syncKiranUserInfo: No-op');
  }

  @override
  Future<List<KiranUserInfo>> loadKiranUserInfo() async {
    debugPrint('[Web] loadKiranUserInfo: No-op, returning empty list');
    return [];
  }

  @override
  Future<void> syncSingleKiranUserInfo(KiranUserInfo info) async {
    debugPrint('[Web] syncSingleKiranUserInfo: No-op');
  }

  // =================== READING HISTORY ===================

  @override
  Future<void> syncReadingHistory(List<ReadingHistory> historyList) async {
    debugPrint('[Web] syncReadingHistory: No-op');
  }

  @override
  Future<void> addReadingHistory(ReadingHistory history) async {
    debugPrint('[Web] addReadingHistory: No-op');
  }

  @override
  Future<List<ReadingHistory>> loadReadingHistory() async {
    debugPrint('[Web] loadReadingHistory: No-op, returning empty list');
    return [];
  }

  @override
  Future<List<ReadingPlan>> loadReadingPlans() async {
    debugPrint('[Web] loadReadingPlans: No-op, returning empty list');
    return [];
  }

  @override
  Future<void> syncSingleReadingHistory(ReadingHistory history) async {
    debugPrint('[Web] syncSingleReadingHistory: No-op');
  }

  // =================== READING PLAN ===================

  @override
  Future<void> addReadingPlan(ReadingPlan plan) async {
    debugPrint('[Web] addReadingPlan: No-op');
  }

  @override
  Future<void> updateReadingPlan(ReadingPlan plan) async {
    debugPrint('[Web] updateReadingPlan: No-op');
  }

  @override
  Future<void> deleteReadingPlan(String planId) async {
    debugPrint('[Web] deleteReadingPlan: No-op');
  }

  // =================== BATCH OPERATIONS ===================

  @override
  Future<void> syncAllUserData({
    AppSettings? appSettings,
    List<BookUserInfo>? bookUserInfo,
    List<KiranUserInfo>? kiranUserInfo,
    List<ReadingHistory>? readingHistory,
  }) async {
    debugPrint('[Web] syncAllUserData: No-op');
  }

  @override
  Future<Map<String, dynamic>> loadAllUserData({
    bool includeReadingHistory = true,
  }) async {
    debugPrint('[Web] loadAllUserData: No-op, returning empty map');
    return {};
  }

  // =================== REAL-TIME LISTENERS ===================

  @override
  Stream<AppSettings?> watchAppSettings() {
    debugPrint('[Web] watchAppSettings: No-op, returning empty stream');
    return Stream.value(null);
  }

  @override
  Stream<List<ReadingHistory>> watchReadingHistory() {
    debugPrint('[Web] watchReadingHistory: No-op, returning empty stream');
    return Stream.value([]);
  }

  // =================== UTILITY METHODS ===================

  @override
  Future<void> clearAllUserData() async {
    debugPrint('[Web] clearAllUserData: No-op');
  }

  @override
  Future<Map<String, int>> getUserDataStats() async {
    debugPrint('[Web] getUserDataStats: No-op, returning empty map');
    return {};
  }

  @override
  Future<void> saveUserDetailsToFirebase(
    String displayName,
    String email,
  ) async {
    debugPrint('[Web] saveUserDetailsToFirebase: No-op');
  }

  @override
  Future<bool> deleteAccount({dynamic reauthCredential}) async {
    debugPrint('[Web] deleteAccount: No-op, returning false');
    return false;
  }

  @override
  Future<void> deleteReadingHistory(ReadingHistory historyToDelete) async {
    debugPrint('[Web] deleteReadingHistory: No-op');
  }
}

FirebaseSyncServiceBase getFirebaseSyncService() => FirebaseSyncServiceWeb();
