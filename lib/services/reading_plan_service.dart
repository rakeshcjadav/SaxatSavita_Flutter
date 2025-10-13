import 'package:flutter/foundation.dart';
import 'package:saxatsavita_flutter/helpers/firebase_integration_helper.dart';
import 'package:saxatsavita_flutter/models/reading_plan_model.dart';
import 'package:saxatsavita_flutter/services/notification_service.dart';

class ReadingPlanService {
  static final ReadingPlanService _instance = ReadingPlanService._internal();
  factory ReadingPlanService() => _instance;
  ReadingPlanService._internal();

  List<ReadingPlan> _readingPlans = [];
  String? _activePlanId;

  List<ReadingPlan> get readingPlans => List.unmodifiable(_readingPlans);
  ReadingPlan? get activePlan =>
      _readingPlans.where((p) => p.id == _activePlanId).firstOrNull;

  void setReadingPlans(List<ReadingPlan> plans) {
    _readingPlans = plans;
    // Search through all plans to find the active one
    for (final plan in _readingPlans) {
      if (plan.isActive) {
        _activePlanId = plan.id;
        debugPrint('✅ Active reading plan found: ${plan.title}');
        break;
      }
    }
  }

  /// Load reading plans from storage
  Future<List<ReadingPlan>> loadReadingPlans() async {
    try {
      //final prefs = await SharedPreferences.getInstance();
      //final activePlanId = prefs.getString(_activeplanKey);
      //_activePlanId = activePlanId;

      if (_readingPlans.isNotEmpty) {
        return _readingPlans;
      }

      debugPrint('📚 Loaded ${_readingPlans.length} reading plans');

      return _readingPlans;
    } catch (e) {
      debugPrint('❌ Error loading reading plans: $e');
      return [];
    }
  }

  /// Create a new reading plan
  Future<ReadingPlan> createReadingPlan({
    required String title,
    required String description,
    required ReadingPlanType type,
    required int targetSeconds,
    required int targetKirans,
    List<ReminderTime> reminderTimes = const [
      ReminderTime(hour: 9, minute: 0),
      ReminderTime(hour: 18, minute: 0),
    ],
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final now = DateTime.now();
    final plan = ReadingPlan(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      description: description,
      type: type,
      targetSeconds: targetSeconds,
      targetKirans: targetKirans,
      startDate: startDate ?? now,
      endDate: endDate,
      reminderTimes: reminderTimes,
      createdAt: now,
      updatedAt: now,
    );

    _readingPlans.add(plan);
    //await _saveReadingPlans();

    // Auto-sync to Firebase
    await FirebaseIntegrationHelper().onNewReadingPlanAdded(plan);

    // Schedule notifications for this plan
    await NotificationService().scheduleReadingPlanReminders(plan);

    debugPrint('✅ Created reading plan: ${plan.title}');
    return plan;
  }

  /// Set active reading plan
  Future<void> setActivePlan(String planId) async {
    final plan = _readingPlans.where((p) => p.id == planId).firstOrNull;
    if (plan != null) {
      _activePlanId = planId;

      // Update plan as active
      final updatedPlan = plan.copyWith(
        isActive: true,
        updatedAt: DateTime.now(),
      );
      updateReadingPlan(updatedPlan);

      // Deactivate other plans and cancel their reminders
      for (final otherPlan in _readingPlans.where((p) => p.id != planId)) {
        // Cancel notifications for the plan being deactivated
        await NotificationService().cancelReadingPlanRemindersForPlan(
          otherPlan,
        );

        final deactivatedPlan = otherPlan.copyWith(
          isActive: false,
          updatedAt: DateTime.now(),
        );
        updateReadingPlan(deactivatedPlan);
      }

      //await _saveReadingPlans();

      // Schedule notifications for active plan
      await NotificationService().scheduleReadingPlanReminders(updatedPlan);

      debugPrint('✅ Set active reading plan: ${plan.title}');
    }
  }

  /// Update reading plan
  Future<void> updateReadingPlan(ReadingPlan updatedPlan) async {
    final index = _readingPlans.indexWhere((p) => p.id == updatedPlan.id);
    if (index != -1) {
      _readingPlans[index] = updatedPlan.copyWith(updatedAt: DateTime.now());
      //await _saveReadingPlans();

      // Auto-sync to Firebase
      await FirebaseIntegrationHelper().onReadingPlanUpdated(updatedPlan);

      // Handle notification updates based on plan status
      if (updatedPlan.isActive && updatedPlan.id == _activePlanId) {
        // Schedule/update notifications for active plan
        await NotificationService().scheduleReadingPlanReminders(updatedPlan);
      } else if (!updatedPlan.isActive) {
        // Cancel notifications for deactivated plan
        await NotificationService().cancelReadingPlanRemindersForPlan(
          updatedPlan,
        );
      }
    }
  }

  /// Delete reading plan
  Future<void> deleteReadingPlan(String planId) async {
    // Find the plan before removing it to cancel its notifications
    final planToDelete = _readingPlans.firstWhere((p) => p.id == planId);

    // Cancel notifications for the plan being deleted
    await NotificationService().cancelReadingPlanRemindersForPlan(planToDelete);

    _readingPlans.removeWhere((p) => p.id == planId);

    if (_activePlanId == planId) {
      _activePlanId = null;
    }

    // Auto-sync to Firebase
    await FirebaseIntegrationHelper().onReadingPlanDeleted(planId);

    debugPrint('🗑️ Deleted reading plan: $planId');
  }

  /// Record reading progress
  Future<void> recordReadingProgress({
    required int secondsRead,
    required List<int> kiransRead,
    DateTime? date,
  }) async {
    if (activePlan == null) return;

    final recordDate = date ?? DateTime.now();
    final dateKey = recordDate.toIso8601String().split('T').first;

    // Update daily progress
    final currentSeconds = activePlan!.dailyProgress[dateKey] ?? 0;
    final currentKirans = Set<int>.from(activePlan!.dailyKirans[dateKey] ?? []);

    // Add new progress
    final newProgress = Map<String, int>.from(activePlan!.dailyProgress);
    newProgress[dateKey] = currentSeconds + secondsRead;

    final newKirans = Map<String, List<int>>.from(activePlan!.dailyKirans);
    currentKirans.addAll(kiransRead);
    newKirans[dateKey] = currentKirans.toList();

    // Update the plan
    final updatedPlan = activePlan!.copyWith(
      dailyProgress: newProgress,
      dailyKirans: newKirans,
    );

    await updateReadingPlan(updatedPlan);

    // Check if goal is achieved and show encouraging notification
    if (updatedPlan.todayGoalAchieved && !activePlan!.todayGoalAchieved) {
      await NotificationService().showGoalAchievedNotification(updatedPlan);
    }

    debugPrint(
      '📈 Recorded progress: ${secondsRead ~/ 60}min, ${kiransRead.length} kirans',
    );
  }

  /// Get reading statistics
  Map<String, dynamic> getReadingStatistics({int days = 30}) {
    if (activePlan == null) {
      return {
        'totalSeconds': 0,
        'totalKirans': 0,
        'averageMinutesPerDay': 0.0,
        'averageKiransPerDay': 0.0,
        'goalsAchieved': 0,
        'streakDays': 0,
        'completionRate': 0.0,
      };
    }

    final plan = activePlan!;
    final now = DateTime.now();
    int totalSeconds = 0;
    Set<int> totalKirans = {};
    int goalsAchieved = 0;

    for (int i = 0; i < days; i++) {
      final checkDate = now.subtract(Duration(days: i));
      final dateKey = checkDate.toIso8601String().split('T').first;

      final daySeconds = plan.dailyProgress[dateKey] ?? 0;
      final dayKirans = plan.dailyKirans[dateKey] ?? [];

      totalSeconds += daySeconds;
      totalKirans.addAll(dayKirans);

      if (daySeconds >= plan.targetSeconds &&
          dayKirans.length >= plan.targetKirans) {
        goalsAchieved++;
      }
    }

    return {
      'totalSeconds': totalSeconds,
      'totalKirans': totalKirans.length,
      'averageSecondsPerDay': totalSeconds / days,
      'averageKiransPerDay': totalKirans.length / days,
      'goalsAchieved': goalsAchieved,
      'streakDays': plan.streakDays,
      'completionRate': goalsAchieved / days,
    };
  }

  /// Get predefined reading plan templates
  List<Map<String, dynamic>> getReadingPlanTemplates() {
    return [
      {
        'type': ReadingPlanType.daily15min,
        'title': 'Daily 15 Minutes',
        'description':
            'Read for 15 minutes every day to build a consistent habit',
        'targetSeconds': 15 * 60,
        'targetKirans': 1,
        'reminderTimes': [9, 20], // 9 AM, 8 PM
      },
      {
        'type': ReadingPlanType.daily30min,
        'title': 'Daily 30 Minutes',
        'description': 'Dedicate 30 minutes daily for deeper spiritual reading',
        'targetSeconds': 30 * 60,
        'targetKirans': 2,
        'reminderTimes': [8, 19], // 8 AM, 7 PM
      },
      {
        'type': ReadingPlanType.daily1hour,
        'title': 'Daily 1 Hour',
        'description': 'Immerse yourself with 1 hour of daily spiritual study',
        'targetSeconds': 60 * 60,
        'targetKirans': 3,
        'reminderTimes': [7, 18], // 7 AM, 6 PM
      },
      {
        'type': ReadingPlanType.weekly,
        'title': 'Weekly Reading',
        'description': 'Flexible weekly reading goal with weekend focus',
        'targetSeconds': 25 * 60, // ~3 hours per week / 7 days
        'targetKirans': 2,
        'reminderTimes': [10, 16], // 10 AM, 4 PM
      },
      {
        'type': ReadingPlanType.monthly,
        'title': 'Monthly Challenge',
        'description': 'Complete a specific number of parts each month',
        'targetSeconds': 20 * 60,
        'targetKirans': 2,
        'reminderTimes': [9, 21], // 9 AM, 9 PM
      },
    ];
  }

  /// Check if it's time for reading reminder
  bool shouldShowReadingReminder() {
    if (activePlan == null || !activePlan!.isActive) return false;

    final now = DateTime.now();
    final currentHour = now.hour;

    // Check if current hour matches any reminder time
    if (!activePlan!.reminderTimes.any((rt) => rt.hour == currentHour)) {
      return false;
    }

    // Check if today's goal is already achieved
    if (activePlan!.todayGoalAchieved) return false;

    return true;
  }

  /// Get daily progress summary for calendar/chart view
  List<Map<String, dynamic>> getDailyProgressSummary({int days = 30}) {
    if (activePlan == null) return [];

    final plan = activePlan!;
    final now = DateTime.now();
    final summaries = <Map<String, dynamic>>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = date.toIso8601String().split('T').first;

      final seconds = plan.dailyProgress[dateKey] ?? 0;
      final kirans = plan.dailyKirans[dateKey] ?? [];
      final goalAchieved =
          seconds >= plan.targetSeconds && kirans.length >= plan.targetKirans;

      summaries.add({
        'date': date,
        'dateKey': dateKey,
        'seconds': seconds,
        'kirans': kirans.length,
        'goalAchieved': goalAchieved,
        'progressPercentage':
            ((seconds / plan.targetSeconds) +
                (kirans.length / plan.targetKirans)) /
            2,
      });
    }

    return summaries;
  }

  /// Clear all reading plans (used during logout/cache clear)
  void clearAllPlans() {
    _readingPlans.clear();
    _activePlanId = null;
    debugPrint('🧹 All reading plans cleared from memory');
  }

  /// Get all plans (for cache info)
  List<ReadingPlan> getAllPlans() => List.unmodifiable(_readingPlans);
}
