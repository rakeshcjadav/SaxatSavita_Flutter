import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Analytics Service
/// 
/// This service provides a centralized way to track analytics events
/// throughout the SakshatSavita app.
class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  late FirebaseAnalytics _analytics;
  bool _initialized = false;

  /// Initialize the analytics service
  void initialize(FirebaseAnalytics analytics) {
    _analytics = analytics;
    _initialized = true;
    debugPrint('AnalyticsService initialized');
  }

  /// Check if analytics is initialized and available
  bool get isInitialized => _initialized;

  // =================== USER EVENTS ===================

  /// Track user sign in event
  Future<void> logSignIn(String method) async {
    if (!_initialized) return;
    try {
      await _analytics.logLogin(loginMethod: method);
      debugPrint('Analytics: User signed in with $method');
    } catch (e) {
      debugPrint('Analytics error - logSignIn: $e');
    }
  }

  /// Track user sign out event
  Future<void> logSignOut() async {
    if (!_initialized) return;
    try {
      await _analytics.logEvent(name: 'sign_out');
      debugPrint('Analytics: User signed out');
    } catch (e) {
      debugPrint('Analytics error - logSignOut: $e');
    }
  }

  /// Set user properties
  Future<void> setUserProperties({
    String? userId,
    String? language,
    String? provider,
  }) async {
    if (!_initialized) return;
    try {
      if (userId != null) {
        await _analytics.setUserId(id: userId);
      }
      if (language != null) {
        await _analytics.setUserProperty(name: 'language', value: language);
      }
      if (provider != null) {
        await _analytics.setUserProperty(name: 'auth_provider', value: provider);
      }
      debugPrint('Analytics: User properties set');
    } catch (e) {
      debugPrint('Analytics error - setUserProperties: $e');
    }
  }

  // =================== READING EVENTS ===================

  /// Track when user starts reading
  Future<void> logStartReading({
    required String bookName,
    required String chapterName,
    String? partName,
  }) async {
    if (!_initialized) return;
    try {
      await _analytics.logEvent(
        name: 'start_reading',
        parameters: {
          'book_name': bookName,
          'chapter_name': chapterName,
          if (partName != null) 'part_name': partName,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      debugPrint('Analytics: Started reading $bookName - $chapterName');
    } catch (e) {
      debugPrint('Analytics error - logStartReading: $e');
    }
  }

  /// Track reading session completion
  Future<void> logCompleteReading({
    required String bookName,
    required String chapterName,
    required int readingTimeSeconds,
    String? partName,
  }) async {
    if (!_initialized) return;
    try {
      await _analytics.logEvent(
        name: 'complete_reading',
        parameters: {
          'book_name': bookName,
          'chapter_name': chapterName,
          if (partName != null) 'part_name': partName,
          'reading_time_seconds': readingTimeSeconds,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      debugPrint('Analytics: Completed reading $bookName - $chapterName (${readingTimeSeconds}s)');
    } catch (e) {
      debugPrint('Analytics error - logCompleteReading: $e');
    }
  }

  /// Track auto-scroll usage
  Future<void> logAutoScroll({
    required bool enabled,
    required String bookName,
    required String chapterName,
  }) async {
    if (!_initialized) return;
    try {
      await _analytics.logEvent(
        name: 'auto_scroll_${enabled ? 'start' : 'stop'}',
        parameters: {
          'book_name': bookName,
          'chapter_name': chapterName,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      debugPrint('Analytics: Auto scroll ${enabled ? 'started' : 'stopped'}');
    } catch (e) {
      debugPrint('Analytics error - logAutoScroll: $e');
    }
  }

  // =================== SEARCH EVENTS ===================

  /// Track search usage
  Future<void> logSearch({
    required String query,
    required int resultsCount,
    String? category,
  }) async {
    if (!_initialized) return;
    try {
      await _analytics.logSearch(
        searchTerm: query,
        numberOfNights: resultsCount,
      );
      await _analytics.logEvent(
        name: 'search_performed',
        parameters: {
          'search_query': query,
          'results_count': resultsCount,
          if (category != null) 'category': category,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      debugPrint('Analytics: Search performed - "$query" ($resultsCount results)');
    } catch (e) {
      debugPrint('Analytics error - logSearch: $e');
    }
  }

  // =================== NAVIGATION EVENTS ===================

  /// Track screen views
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_initialized) return;
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
      debugPrint('Analytics: Screen view - $screenName');
    } catch (e) {
      debugPrint('Analytics error - logScreenView: $e');
    }
  }

  // =================== FEATURE USAGE EVENTS ===================

  /// Track note creation/editing
  Future<void> logNoteActivity({
    required String action, // 'create', 'edit', 'delete'
    required String bookName,
    required String chapterName,
  }) async {
    if (!_initialized) return;
    try {
      await _analytics.logEvent(
        name: 'note_$action',
        parameters: {
          'book_name': bookName,
          'chapter_name': chapterName,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      debugPrint('Analytics: Note $action - $bookName/$chapterName');
    } catch (e) {
      debugPrint('Analytics error - logNoteActivity: $e');
    }
  }

  /// Track sharing activity
  Future<void> logShare({
    required String contentType, // 'verse', 'quote', 'chapter'
    required String method, // 'image', 'text'
    String? bookName,
    String? chapterName,
  }) async {
    if (!_initialized) return;
    try {
      final itemId = bookName != null && chapterName != null ? '${bookName}_$chapterName' : 'unknown';
      await _analytics.logShare(
        contentType: contentType,
        method: method,
        itemId: itemId,
      );
      debugPrint('Analytics: Share $contentType via $method');
    } catch (e) {
      debugPrint('Analytics error - logShare: $e');
    }
  }

  /// Track settings changes
  Future<void> logSettingsChange({
    required String setting,
    required String value,
  }) async {
    if (!_initialized) return;
    try {
      await _analytics.logEvent(
        name: 'settings_change',
        parameters: {
          'setting_name': setting,
          'setting_value': value,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      debugPrint('Analytics: Settings change - $setting: $value');
    } catch (e) {
      debugPrint('Analytics error - logSettingsChange: $e');
    }
  }

  // =================== ERROR TRACKING ===================

  /// Track errors or crashes
  Future<void> logError({
    required String errorType,
    required String errorMessage,
    String? screen,
  }) async {
    if (!_initialized) return;
    try {
      await _analytics.logEvent(
        name: 'app_error',
        parameters: {
          'error_type': errorType,
          'error_message': errorMessage.length > 100 
              ? errorMessage.substring(0, 100) + '...' 
              : errorMessage,
          if (screen != null) 'screen': screen,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      debugPrint('Analytics: Error tracked - $errorType');
    } catch (e) {
      debugPrint('Analytics error - logError: $e');
    }
  }

  // =================== CUSTOM EVENTS ===================

  /// Log custom event with parameters
  Future<void> logCustomEvent({
    required String name,
    Map<String, Object?>? parameters,
  }) async {
    if (!_initialized) return;
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters?.cast<String, Object>(),
      );
      debugPrint('Analytics: Custom event - $name');
    } catch (e) {
      debugPrint('Analytics error - logCustomEvent: $e');
    }
  }
}