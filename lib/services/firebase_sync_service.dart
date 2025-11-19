import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/models/bookuserinfo_model.dart';
import 'package:saxatsavita_flutter/models/kiranuserinfo_model.dart';
import 'package:saxatsavita_flutter/models/reading_history_model.dart';
import 'package:saxatsavita_flutter/models/reading_plan_model.dart';
import 'firebase_sync_service_base.dart';

// Conditional imports based on platform - imports the right getFirebaseSyncService function
import 'firebase_sync_service_web.dart'
    if (dart.library.io) 'firebase_sync_service_mobile.dart';

/// Main FirebaseSyncService class that delegates to platform-specific implementation
class FirebaseSyncService implements FirebaseSyncServiceBase {
  static final FirebaseSyncService _instance = FirebaseSyncService._internal();
  factory FirebaseSyncService() => _instance;
  FirebaseSyncService._internal();

  // Get the platform-specific implementation
  final FirebaseSyncServiceBase _impl = getFirebaseSyncService();

  // Delegate all methods to the platform-specific implementation

  @override
  String? get currentUserId => _impl.currentUserId;

  @override
  bool get isAuthenticated => _impl.isAuthenticated;

  @override
  dynamic get userDoc => _impl.userDoc;

  @override
  Future<void> syncAppSettings(AppSettings settings) =>
      _impl.syncAppSettings(settings);

  @override
  Future<AppSettings?> loadAppSettings() => _impl.loadAppSettings();

  @override
  Future<void> syncBookUserInfo(List<BookUserInfo> bookUserInfoList) =>
      _impl.syncBookUserInfo(bookUserInfoList);

  @override
  Future<List<BookUserInfo>> loadBookUserInfo() => _impl.loadBookUserInfo();

  @override
  Future<void> syncSingleBookUserInfo(BookUserInfo info) =>
      _impl.syncSingleBookUserInfo(info);

  @override
  Future<void> syncKiranUserInfo(List<KiranUserInfo> kiranUserInfoList) =>
      _impl.syncKiranUserInfo(kiranUserInfoList);

  @override
  Future<List<KiranUserInfo>> loadKiranUserInfo() => _impl.loadKiranUserInfo();

  @override
  Future<void> syncSingleKiranUserInfo(KiranUserInfo info) =>
      _impl.syncSingleKiranUserInfo(info);

  @override
  Future<void> syncReadingHistory(List<ReadingHistory> historyList) =>
      _impl.syncReadingHistory(historyList);

  @override
  Future<void> addReadingHistory(ReadingHistory history) =>
      _impl.addReadingHistory(history);

  @override
  Future<List<ReadingHistory>> loadReadingHistory() =>
      _impl.loadReadingHistory();

  @override
  Future<List<ReadingPlan>> loadReadingPlans() => _impl.loadReadingPlans();

  @override
  Future<void> syncSingleReadingHistory(ReadingHistory history) =>
      _impl.syncSingleReadingHistory(history);

  @override
  Future<void> addReadingPlan(ReadingPlan plan) => _impl.addReadingPlan(plan);

  @override
  Future<void> updateReadingPlan(ReadingPlan plan) =>
      _impl.updateReadingPlan(plan);

  @override
  Future<void> deleteReadingPlan(String planId) =>
      _impl.deleteReadingPlan(planId);

  @override
  Future<void> syncAllUserData({
    AppSettings? appSettings,
    List<BookUserInfo>? bookUserInfo,
    List<KiranUserInfo>? kiranUserInfo,
    List<ReadingHistory>? readingHistory,
  }) => _impl.syncAllUserData(
    appSettings: appSettings,
    bookUserInfo: bookUserInfo,
    kiranUserInfo: kiranUserInfo,
    readingHistory: readingHistory,
  );

  @override
  Future<Map<String, dynamic>> loadAllUserData({
    bool includeReadingHistory = true,
  }) => _impl.loadAllUserData(includeReadingHistory: includeReadingHistory);

  @override
  Stream<AppSettings?> watchAppSettings() => _impl.watchAppSettings();

  @override
  Stream<List<ReadingHistory>> watchReadingHistory() =>
      _impl.watchReadingHistory();

  @override
  Future<void> clearAllUserData() => _impl.clearAllUserData();

  @override
  Future<Map<String, int>> getUserDataStats() => _impl.getUserDataStats();

  @override
  Future<void> saveUserDetailsToFirebase(String displayName, String email) =>
      _impl.saveUserDetailsToFirebase(displayName, email);

  @override
  Future<bool> deleteAccount({dynamic reauthCredential}) =>
      _impl.deleteAccount(reauthCredential: reauthCredential);

  @override
  Future<void> deleteReadingHistory(ReadingHistory historyToDelete) =>
      _impl.deleteReadingHistory(historyToDelete);
}
