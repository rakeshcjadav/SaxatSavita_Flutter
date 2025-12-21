import 'package:flutter/foundation.dart';
import 'package:saxatsavita_flutter/services/reading_history_service.dart';
import 'package:saxatsavita_flutter/services/reading_plan_service.dart';
import 'package:saxatsavita_flutter/services/user_profile_service.dart';
import 'package:saxatsavita_flutter/models/user_profile_model.dart';
import 'package:saxatsavita_flutter/models/reading_plan_model.dart';
import 'package:saxatsavita_flutter/models/reading_history_model.dart';
import 'package:saxatsavita_flutter/services/utils.dart';

class DashboardStatistics {
  final int totalReadingSessions;
  final int totalReadingTimeSeconds;
  final int uniqueKiransRead;
  final int todaysSessions;
  final int weekSessions;
  final int currentStreak;
  final int longestStreak;
  final ReadingPlan? activePlan;
  final double planProgress;
  final List<ReadingHistory> recentHistory;
  final Map<int, int> weeklyReadingData; // day -> seconds

  DashboardStatistics({
    required this.totalReadingSessions,
    required this.totalReadingTimeSeconds,
    required this.uniqueKiransRead,
    required this.todaysSessions,
    required this.weekSessions,
    required this.currentStreak,
    required this.longestStreak,
    this.activePlan,
    required this.planProgress,
    required this.recentHistory,
    required this.weeklyReadingData,
  });
}

class DashboardService {
  static final DashboardService _instance = DashboardService._internal();
  factory DashboardService() => _instance;
  DashboardService._internal();

  final ReadingPlanService _planService = ReadingPlanService();
  final UserProfileService _profileService = UserProfileService();

  /// Get comprehensive dashboard statistics
  Future<DashboardStatistics> getDashboardStatistics() async {
    try {
      // Get reading statistics
      final stats = await ReadingHistoryService.getReadingStatistics();

      // Get active reading plan
      final activePlan = _planService.activePlan;

      // Calculate plan progress
      double planProgress = 0.0;
      if (activePlan != null) {
        planProgress = _calculatePlanProgress(activePlan);
      }

      // Get recent reading history (last 10 sessions)
      await _loadReadingHistoryFromFirebaseAndStorage();
      final allHistory = await ReadingHistoryService.loadReadingHistory();
      final recentHistory =
          (List<ReadingHistory>.from(allHistory)..sort(
            (a, b) => b.createdAt.compareTo(a.createdAt),
          )).take(10).toList();

      // Calculate streaks
      final streaks = _calculateStreaks(allHistory);

      // Get weekly reading data for chart
      final weeklyData = await _getWeeklyReadingData();

      return DashboardStatistics(
        totalReadingSessions: stats['totalSessions'] ?? 0,
        totalReadingTimeSeconds: stats['totalDurationSeconds'] ?? 0,
        uniqueKiransRead: stats['uniqueKiransRead'] ?? 0,
        todaysSessions: stats['todaysSessions'] ?? 0,
        weekSessions: stats['weekSessions'] ?? 0,
        currentStreak: streaks['current'] ?? 0,
        longestStreak: streaks['longest'] ?? 0,
        activePlan: activePlan,
        planProgress: planProgress,
        recentHistory: recentHistory,
        weeklyReadingData: weeklyData,
      );
    } catch (e) {
      debugPrint('❌ Error getting dashboard statistics: $e');
      rethrow;
    }
  }

  Future<void> _loadReadingHistoryFromFirebaseAndStorage() async {
    if (!ReadingHistoryService().hasLoadedReadingHistory) {
      try {
        // Load reading history from Firebase (on-demand)
        await Utils.loadReadingHistoryFromFirebase();
        debugPrint('Reading history loaded from Firebase on-demand');
      } catch (e) {
        debugPrint('Error loading reading history from Firebase: $e');
      }
    }
  }

  /// Get user profile with null safety
  Future<UserProfile?> getUserProfile() async {
    try {
      return await _profileService.getUserProfile();
    } catch (e) {
      debugPrint('❌ Error getting user profile: $e');
      return null;
    }
  }

  /// Calculate reading plan progress percentage
  double _calculatePlanProgress(ReadingPlan plan) {
    if (plan.todayProgress == 0 && plan.targetSeconds == 0) {
      return 0.0;
    }

    final progress = (plan.todayProgress / plan.targetSeconds) * 100;
    return progress.clamp(0.0, 100.0);
  }

  /// Calculate current and longest reading streaks
  Map<String, int> _calculateStreaks(List<ReadingHistory> history) {
    if (history.isEmpty) {
      return {'current': 0, 'longest': 0};
    }

    // Sort history by date (newest first)
    final sortedHistory = List<ReadingHistory>.from(history)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 1;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(Duration(days: 1));

    // Check if there's activity today or yesterday to start streak
    if (sortedHistory.first.createdAt.isAfter(yesterday)) {
      currentStreak = 1;

      // Count consecutive days
      for (int i = 0; i < sortedHistory.length - 1; i++) {
        final currentDate = DateTime(
          sortedHistory[i].createdAt.year,
          sortedHistory[i].createdAt.month,
          sortedHistory[i].createdAt.day,
        );
        final nextDate = DateTime(
          sortedHistory[i + 1].createdAt.year,
          sortedHistory[i + 1].createdAt.month,
          sortedHistory[i + 1].createdAt.day,
        );

        final difference = currentDate.difference(nextDate).inDays;

        if (difference == 1) {
          currentStreak++;
          tempStreak++;
        } else if (difference > 1) {
          break;
        }
      }
    }

    // Calculate longest streak
    tempStreak = 1;
    for (int i = 0; i < sortedHistory.length - 1; i++) {
      final currentDate = DateTime(
        sortedHistory[i].createdAt.year,
        sortedHistory[i].createdAt.month,
        sortedHistory[i].createdAt.day,
      );
      final nextDate = DateTime(
        sortedHistory[i + 1].createdAt.year,
        sortedHistory[i + 1].createdAt.month,
        sortedHistory[i + 1].createdAt.day,
      );

      final difference = currentDate.difference(nextDate).inDays;

      if (difference == 1) {
        tempStreak++;
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else if (difference > 1) {
        tempStreak = 1;
      }
    }

    if (longestStreak < currentStreak) {
      longestStreak = currentStreak;
    }

    return {'current': currentStreak, 'longest': longestStreak};
  }

  /// Get reading data for the last 7 days (Mon=0 to Sun=6)
  Future<Map<int, int>> _getWeeklyReadingData() async {
    final Map<int, int> weeklyData = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Initialize all weekdays with 0 (Mon=0, Tue=1, ..., Sun=6)
    for (int i = 0; i < 7; i++) {
      weeklyData[i] = 0;
    }

    try {
      final history = await ReadingHistoryService.loadReadingHistory();

      for (final entry in history) {
        final entryDate = DateTime(
          entry.createdAt.year,
          entry.createdAt.month,
          entry.createdAt.day,
        );
        final daysAgo = today.difference(entryDate).inDays;

        // Only include data from the last 7 days
        if (daysAgo >= 0 && daysAgo < 7) {
          // Map to weekday index (1=Mon, 2=Tue, ..., 7=Sun)
          // Convert to 0-based index (0=Mon, 1=Tue, ..., 6=Sun)
          final weekdayIndex = entry.createdAt.weekday - 1;
          weeklyData[weekdayIndex] =
              (weeklyData[weekdayIndex] ?? 0) + entry.durationSeconds;
        }
      }
    } catch (e) {
      debugPrint('❌ Error getting weekly reading data: $e');
    }

    return weeklyData;
  }

  /// Format seconds to readable time string
  String formatReadingTime(int seconds) {
    if (seconds < 60) {
      return '$seconds sec';
    } else if (seconds < 3600) {
      final minutes = seconds ~/ 60;
      return '$minutes min';
    } else {
      final hours = seconds ~/ 3600;
      final minutes = (seconds % 3600) ~/ 60;
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
  }

  /// Get greeting based on time of day
  GreetingType getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return GreetingType.morning;
    } else if (hour < 17) {
      return GreetingType.afternoon;
    } else {
      return GreetingType.evening;
    }
  }
}

enum GreetingType { morning, afternoon, evening }
