import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saxatsavita_flutter/services/reading_history_service.dart';
import 'package:saxatsavita_flutter/services/kiranuser_service.dart';
import 'package:saxatsavita_flutter/services/reading_plan_service.dart';
import 'package:saxatsavita_flutter/services/firebase_sync_service.dart';
import 'package:saxatsavita_flutter/services/bookservice.dart';

/// Service to manage all local cache clearing operations
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  /// Clear all local cache data (used during logout)
  Future<void> clearAllLocalCache() async {
    debugPrint('🧹 Starting to clear all local cache data...');

    try {
      await Future.wait([
        _clearSharedPreferences(),
        _clearInMemoryCache(),
        //_clearFirebaseCache(),
      ]);

      debugPrint('✅ All local cache cleared successfully');
    } catch (e) {
      debugPrint('❌ Error clearing local cache: $e');
      rethrow;
    }
  }

  /// Clear all SharedPreferences data
  Future<void> _clearSharedPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get all keys before clearing to log what's being removed
      final keys = prefs.getKeys();
      debugPrint('📝 Clearing SharedPreferences keys: ${keys.toList()}');

      // Clear all SharedPreferences data
      await prefs.clear();

      debugPrint('✅ SharedPreferences cleared');
    } catch (e) {
      debugPrint('❌ Error clearing SharedPreferences: $e');
      rethrow;
    }
  }

  /// Clear all in-memory cache data
  Future<void> _clearInMemoryCache() async {
    try {
      // Clear reading history
      ReadingHistoryService().readingHistoryList.clear();
      debugPrint('✅ Reading history cache cleared');

      // Clear kiran user info
      KiranUserService().kiranUserInfoList = [];
      debugPrint('✅ Kiran user info cache cleared');

      // Clear reading plans
      ReadingPlanService().clearAllPlans();
      debugPrint('✅ Reading plans cache cleared');

      // Clear book user info if applicable
      Bookservice().bookUserInfoList = [];
      debugPrint('✅ Book user info cache cleared');

      // Note: AppSettings are stored in Firebase and cleared by _clearFirebaseCache()
      // No additional local settings clearing needed

      // Note: AppDataService contains static app data loaded from assets
      // This data is not user-specific and doesn't need to be cleared
      // We only clear user-generated data

      debugPrint('✅ In-memory cache cleared');
    } catch (e) {
      debugPrint('❌ Error clearing in-memory cache: $e');
      rethrow;
    }
  }

  /// Clear Firebase-related cache (optional - clears remote data)
  Future<void> _clearFirebaseCache() async {
    try {
      // Note: This clears remote Firebase data, which might not always be desired
      // You might want to make this optional based on user preference
      final firebaseSync = FirebaseSyncService();

      // Only clear if user is authenticated
      if (firebaseSync.isAuthenticated) {
        await firebaseSync.clearAllUserData();
        debugPrint('✅ Firebase user data cleared');
      } else {
        debugPrint(
          'ℹ️ User not authenticated, skipping Firebase data clearing',
        );
      }
    } catch (e) {
      debugPrint('❌ Error clearing Firebase cache: $e');
      // Don't rethrow - Firebase clearing is optional and shouldn't block logout
    }
  }

  /// Clear only local cache without touching Firebase data
  Future<void> clearLocalCacheOnly() async {
    debugPrint('🧹 Starting to clear local cache only...');

    try {
      await Future.wait([_clearSharedPreferences(), _clearInMemoryCache()]);

      debugPrint(
        '✅ Local cache cleared successfully (Firebase data preserved)',
      );
    } catch (e) {
      debugPrint('❌ Error clearing local cache: $e');
      rethrow;
    }
  }

  /// Clear specific cache types
  Future<void> clearSearchHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('search_history');
      debugPrint('✅ Search history cleared');
    } catch (e) {
      debugPrint('❌ Error clearing search history: $e');
      rethrow;
    }
  }

  Future<void> clearReadingHistory() async {
    try {
      ReadingHistoryService().readingHistoryList.clear();
      debugPrint('✅ Reading history cleared');
    } catch (e) {
      debugPrint('❌ Error clearing reading history: $e');
      rethrow;
    }
  }

  /// Get cache size information for debugging
  Future<Map<String, dynamic>> getCacheInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      return {
        'sharedPreferences': {'keyCount': keys.length, 'keys': keys.toList()},
        'inMemory': {
          'readingHistoryCount':
              ReadingHistoryService().readingHistoryList.length,
          'kiranUserInfoCount': KiranUserService().kiranUserInfoList.length,
          'readingPlansCount': ReadingPlanService().getAllPlans().length,
        },
      };
    } catch (e) {
      debugPrint('❌ Error getting cache info: $e');
      return {'error': e.toString()};
    }
  }
}
