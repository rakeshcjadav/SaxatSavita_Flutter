import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saxatsavita_flutter/services/analytics_service.dart';

class InAppReviewService {
  static const String _reviewRequestedKey = 'review_requested';
  static const String _reviewPromptCountKey = 'review_prompt_count';
  static const String _lastReviewPromptKey = 'last_review_prompt';
  static const String _appLaunchCountKey = 'app_launch_count';
  static const String _readingSessionCountKey = 'reading_session_count';

  // Review prompt conditions
  static const int _minLaunchCount = 5; // Minimum app launches before asking
  static const int _minReadingSessions =
      3; // Minimum reading sessions before asking
  static const int _daysBetweenPrompts = 30; // Days between review prompts
  static const int _maxPrompts = 3; // Maximum number of review prompts

  static final InAppReviewService _instance = InAppReviewService._internal();
  factory InAppReviewService() => _instance;
  InAppReviewService._internal();

  final InAppReview _inAppReview = InAppReview.instance;

  /// Initialize the service and increment app launch count
  Future<void> initialize() async {
    await _incrementAppLaunchCount();
  }

  /// Check if in-app review is available on this platform
  Future<bool> isAvailable() async {
    try {
      return await _inAppReview.isAvailable();
    } catch (e) {
      debugPrint('Error checking in-app review availability: $e');
      return false;
    }
  }

  /// Increment app launch count
  Future<void> _incrementAppLaunchCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_appLaunchCountKey) ?? 0;
    await prefs.setInt(_appLaunchCountKey, currentCount + 1);
  }

  /// Increment reading session count (call this when user completes reading a kiran)
  Future<void> incrementReadingSessionCount() async {
    final prefs = await SharedPreferences.getInstance();
    final currentCount = prefs.getInt(_readingSessionCountKey) ?? 0;
    await prefs.setInt(_readingSessionCountKey, currentCount + 1);

    // Check if we should prompt for review after reading session
    await _checkAndPromptForReview();
  }

  /// Check if we should prompt for review based on conditions
  Future<bool> _shouldPromptForReview() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if user already reviewed or declined too many times
    final hasReviewed = prefs.getBool(_reviewRequestedKey) ?? false;
    if (hasReviewed) return false;

    final promptCount = prefs.getInt(_reviewPromptCountKey) ?? 0;
    if (promptCount >= _maxPrompts) return false;

    // Check time since last prompt
    final lastPrompt = prefs.getInt(_lastReviewPromptKey) ?? 0;
    final daysSinceLastPrompt =
        DateTime.now()
            .difference(DateTime.fromMillisecondsSinceEpoch(lastPrompt))
            .inDays;

    if (lastPrompt > 0 && daysSinceLastPrompt < _daysBetweenPrompts) {
      return false;
    }

    // Check launch and reading session counts
    final launchCount = prefs.getInt(_appLaunchCountKey) ?? 0;
    final readingCount = prefs.getInt(_readingSessionCountKey) ?? 0;

    return launchCount >= _minLaunchCount &&
        readingCount >= _minReadingSessions;
  }

  /// Check conditions and prompt for review if appropriate
  Future<void> _checkAndPromptForReview() async {
    if (!await _shouldPromptForReview()) return;
    if (!await isAvailable()) return;

    // Show the review prompt
    await _showReviewPrompt();
  }

  /// Show the native in-app review dialog
  Future<void> _showReviewPrompt() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Update prompt statistics
      final promptCount = prefs.getInt(_reviewPromptCountKey) ?? 0;
      await prefs.setInt(_reviewPromptCountKey, promptCount + 1);
      await prefs.setInt(
        _lastReviewPromptKey,
        DateTime.now().millisecondsSinceEpoch,
      );

      // Request the review
      await _inAppReview.requestReview();

      // Track analytics
      await AnalyticsService().logCustomEvent(
        name: 'review_prompt_shown',
        parameters: {'prompt_count': promptCount + 1},
      );

      debugPrint('In-app review requested');
    } catch (e) {
      debugPrint('Error showing review prompt: $e');

      // Track error
      await AnalyticsService().logError(
        errorType: 'in_app_review_error',
        errorMessage: e.toString(),
        screen: 'review_service',
      );
    }
  }

  /// Manually trigger review prompt (for testing or manual triggers)
  Future<void> promptForReview() async {
    if (!await isAvailable()) {
      debugPrint('In-app review not available, opening store page');
      await openStorePage();
      return;
    }

    await _showReviewPrompt();
  }

  /// Open the app store page for manual review
  Future<void> openStorePage() async {
    try {
      await _inAppReview.openStoreListing(
        appStoreId: null, // Add your App Store ID if needed
      );

      // Track analytics
      await AnalyticsService().logCustomEvent(
        name: 'store_page_opened',
        parameters: {'source': 'manual_review_request'},
      );
    } catch (e) {
      debugPrint('Error opening store page: $e');

      // Track error
      await AnalyticsService().logError(
        errorType: 'store_page_error',
        errorMessage: e.toString(),
        screen: 'review_service',
      );
    }
  }

  /// Mark that user has completed the review process
  Future<void> markReviewCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reviewRequestedKey, true);

    // Track analytics
    await AnalyticsService().logCustomEvent(
      name: 'review_completed',
      parameters: {},
    );
  }

  /// Reset review statistics (for testing purposes)
  Future<void> resetReviewStats() async {
    if (kDebugMode) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_reviewRequestedKey);
      await prefs.remove(_reviewPromptCountKey);
      await prefs.remove(_lastReviewPromptKey);
      await prefs.remove(_appLaunchCountKey);
      await prefs.remove(_readingSessionCountKey);
      debugPrint('Review statistics reset');
    }
  }

  /// Get current review statistics (for debugging)
  Future<Map<String, dynamic>> getReviewStats() async {
    final prefs = await SharedPreferences.getInstance();

    return {
      'hasReviewed': prefs.getBool(_reviewRequestedKey) ?? false,
      'promptCount': prefs.getInt(_reviewPromptCountKey) ?? 0,
      'launchCount': prefs.getInt(_appLaunchCountKey) ?? 0,
      'readingCount': prefs.getInt(_readingSessionCountKey) ?? 0,
      'lastPrompt': prefs.getInt(_lastReviewPromptKey) ?? 0,
      'isAvailable': await isAvailable(),
      'shouldPrompt': await _shouldPromptForReview(),
    };
  }

  /// Force prompt for review (ignoring conditions, for manual testing)
  Future<void> forcePromptForReview() async {
    if (kDebugMode) {
      if (await isAvailable()) {
        await _showReviewPrompt();
      } else {
        await openStorePage();
      }
    }
  }
}
