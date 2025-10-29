import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saxatsavita_flutter/services/reading_plan_service.dart';

/// Service to manage home screen widgets for Android and iOS
class HomeWidgetService {
  static const String _widgetGroupId = 'group.com.saxatsavita.flutter.widgets';
  static const String _widgetUpdateCountKey = 'widget_update_count';

  // Widget identifiers
  static const String readingProgressWidgetId = 'ReadingProgressWidget';

  static final HomeWidgetService _instance = HomeWidgetService._internal();
  factory HomeWidgetService() => _instance;
  HomeWidgetService._internal();

  final ReadingPlanService _readingPlanService = ReadingPlanService();

  /// Initialize the home widget service
  Future<void> initialize() async {
    try {
      // Register widget update callback
      HomeWidget.setAppGroupId(_widgetGroupId);
      HomeWidget.registerInteractivityCallback(_backgroundCallback);

      debugPrint('HomeWidgetService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing HomeWidgetService: $e');
    }
  }

  /// Background callback for widget interactions
  @pragma('vm:entry-point')
  static Future<void> _backgroundCallback(Uri? uri) async {
    if (uri != null) {
      // Handle widget tap actions
      final action = uri.host;
      final params = uri.queryParameters;

      debugPrint('Widget action: $action with params: $params');

      switch (action) {
        case 'openApp':
          // Track widget usage analytics
          await _trackWidgetInteraction('app_opened_from_widget');
          break;
        case 'startReading':
          await _trackWidgetInteraction('reading_started_from_widget');
          break;
        case 'viewProgress':
          await _trackWidgetInteraction('progress_viewed_from_widget');
          break;
      }
    }
  }

  static Future<void> _trackWidgetInteraction(String action) async {
    try {
      // Track analytics if service is available
      final prefs = await SharedPreferences.getInstance();
      final count = prefs.getInt(_widgetUpdateCountKey) ?? 0;
      await prefs.setInt(_widgetUpdateCountKey, count + 1);

      debugPrint('Widget interaction tracked: $action');
    } catch (e) {
      debugPrint('Error tracking widget interaction: $e');
    }
  }

  /// Update reading progress widget
  Future<void> updateReadingProgressWidget() async {
    try {
      final progress = await _getReadingProgress();
      final todayDate = DateTime.now().toIso8601String().split('T').first;

      // Save widget data with active plan information
      await HomeWidget.saveWidgetData<String>(
        'progress_title',
        progress['planTitle'] != null
            ? 'Reading Plan: ${progress['planTitle']}'
            : 'Reading Progress',
      );
      await HomeWidget.saveWidgetData<int>(
        'daily_target_minutes',
        progress['targetMinutes'],
      );
      await HomeWidget.saveWidgetData<int>(
        'completed_minutes',
        progress['completedMinutes'],
      );
      await HomeWidget.saveWidgetData<int>(
        'target_kirans',
        progress['targetKirans'],
      );
      await HomeWidget.saveWidgetData<int>(
        'completed_kirans',
        progress['completedKirans'],
      );
      await HomeWidget.saveWidgetData<String>(
        'progress_percentage',
        progress['progressPercentage'].toString(),
      );
      await HomeWidget.saveWidgetData<String>('progress_date', todayDate);
      await HomeWidget.saveWidgetData<bool>(
        'goal_achieved',
        progress['goalAchieved'],
      );
      await HomeWidget.saveWidgetData<String>(
        'streak_days',
        '${progress['streakDays']} days',
      );

      // Add formatted display strings for better widget presentation
      await HomeWidget.saveWidgetData<String>(
        'progress_summary',
        '${progress['completedMinutes']}/${progress['targetMinutes']} min • ${progress['completedKirans']}/${progress['targetKirans']} kirans',
      );
      await HomeWidget.saveWidgetData<String>(
        'progress_status',
        progress['goalAchieved'] ? 'Goal Achieved!' : 'In Progress',
      );

      // Add action URLs
      await HomeWidget.saveWidgetData<String>(
        'progress_action',
        'saxatsavita://widget/viewProgress',
      );
      await HomeWidget.saveWidgetData<String>(
        'start_reading_action',
        'saxatsavita://widget/startReading',
      );

      await HomeWidget.updateWidget(
        name: readingProgressWidgetId,
        androidName: 'ReadingProgressWidget',
        iOSName: 'ReadingProgressWidget',
      );

      debugPrint('Reading progress widget updated successfully');
    } catch (e) {
      debugPrint('Error updating reading progress widget: $e');
    }
  }

  /// Update all widgets
  Future<void> updateAllWidgets() async {
    await updateReadingProgressWidget();
  }

  /// Get current reading progress
  Future<Map<String, dynamic>> _getReadingProgress() async {
    try {
      // Always load the latest reading plans data
      await _readingPlanService.loadReadingPlans();
      final activePlan = _readingPlanService.activePlan;

      if (activePlan != null) {
        final statistics = _readingPlanService.getReadingStatistics();

        // Get today's progress with more detailed info
        final todayKey = DateTime.now().toIso8601String().split('T').first;
        final todaySeconds = activePlan.dailyProgress[todayKey] ?? 0;
        final todayKirans = activePlan.dailyKirans[todayKey] ?? [];

        // Calculate progress percentage more accurately
        final secondsProgress =
            activePlan.targetSeconds > 0
                ? (todaySeconds / activePlan.targetSeconds).clamp(0.0, 1.0)
                : 0.0;
        final kiransProgress =
            activePlan.targetKirans > 0
                ? (todayKirans.length / activePlan.targetKirans).clamp(0.0, 1.0)
                : 0.0;
        final overallProgress =
            ((secondsProgress + kiransProgress) / 2 * 100).round();

        debugPrint('📊 Widget Progress Data:');
        debugPrint('  - Plan: ${activePlan.title}');
        debugPrint(
          '  - Today Seconds: $todaySeconds/${activePlan.targetSeconds}',
        );
        debugPrint(
          '  - Today Kirans: ${todayKirans.length}/${activePlan.targetKirans}',
        );
        debugPrint('  - Progress: $overallProgress%');
        debugPrint('  - Goal Achieved: ${activePlan.todayGoalAchieved}');

        return {
          'targetMinutes': (activePlan.targetSeconds / 60).round(),
          'completedMinutes': (todaySeconds / 60).round(),
          'targetKirans': activePlan.targetKirans,
          'completedKirans': todayKirans.length,
          'progressPercentage': overallProgress.toDouble(),
          'goalAchieved': activePlan.todayGoalAchieved,
          'streakDays': statistics['streakDays'] ?? 0,
          'planTitle': activePlan.title,
        };
      }

      return {
        'targetMinutes': 0,
        'completedMinutes': 0,
        'targetKirans': 0,
        'completedKirans': 0,
        'progressPercentage': 0.0,
        'goalAchieved': false,
        'streakDays': 0,
      };
    } catch (e) {
      debugPrint('Error getting reading progress: $e');
      return {
        'targetMinutes': 0,
        'completedMinutes': 0,
        'targetKirans': 0,
        'completedKirans': 0,
        'progressPercentage': 0.0,
        'goalAchieved': false,
        'streakDays': 0,
      };
    }
  }

  /// Check if widgets are supported on this platform
  Future<bool> areWidgetsSupported() async {
    try {
      // Check if platform supports widgets
      return await HomeWidget.isRequestPinWidgetSupported() ?? false;
    } catch (e) {
      debugPrint('Error checking widget support: $e');
      return false;
    }
  }

  /// Request to pin widget to home screen (Android 8+)
  Future<bool> requestPinWidget(String widgetName) async {
    try {
      await HomeWidget.requestPinWidget(
        androidName: widgetName,
        qualifiedAndroidName: 'com.saxatsavita.flutter.$widgetName',
      );

      return true;
    } catch (e) {
      debugPrint('Error requesting pin widget: $e');
      return false;
    }
  }

  /// Get widget analytics
  Future<Map<String, dynamic>> getWidgetAnalytics() async {
    final prefs = await SharedPreferences.getInstance();
    final updateCount = prefs.getInt(_widgetUpdateCountKey) ?? 0;

    return {
      'total_updates': updateCount,
      'last_update': DateTime.now().toIso8601String(),
      'supported': await areWidgetsSupported(),
    };
  }

  /// Schedule automatic widget updates (call this from app lifecycle)
  Future<void> scheduleWidgetUpdates() async {
    try {
      // Update widgets when app becomes active
      await updateAllWidgets();

      debugPrint('Widget updates scheduled successfully');
    } catch (e) {
      debugPrint('Error scheduling widget updates: $e');
    }
  }

  /// Update widgets when reading progress changes
  Future<void> onReadingProgressChanged() async {
    try {
      // Update reading progress widget immediately
      await updateReadingProgressWidget();

      debugPrint('📱 Reading progress widget updated after progress change');
    } catch (e) {
      debugPrint('Error updating widget after progress change: $e');
    }
  }

  /// Force refresh all widget data from current active plan
  Future<void> refreshWidgetData() async {
    try {
      // Force reload reading plans
      await _readingPlanService.loadReadingPlans();

      // Update all widgets with fresh data
      await updateAllWidgets();

      debugPrint('🔄 All widget data refreshed from active plan');
    } catch (e) {
      debugPrint('Error refreshing widget data: $e');
    }
  }
}
