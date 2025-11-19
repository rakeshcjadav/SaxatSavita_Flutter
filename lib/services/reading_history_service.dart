import 'package:saxatsavita_flutter/helpers/firebase_integration_helper.dart';
import 'package:saxatsavita_flutter/models/reading_history_model.dart';
import 'package:saxatsavita_flutter/services/reading_plan_service.dart';

class ReadingHistoryService {
  static final ReadingHistoryService _instance =
      ReadingHistoryService._internal();
  factory ReadingHistoryService() => _instance;
  ReadingHistoryService._internal();

  List<ReadingHistory> readingHistoryList = [];

  /// Save a reading history entry to SharedPreferences
  static Future<void> saveReadingHistory(ReadingHistory history) async {
    try {
      await ReadingPlanService().recordReadingProgress(
        secondsRead: history.durationSeconds,
        kiransRead: [history.kiranIndex],
      );
      ReadingHistoryService().readingHistoryList.add(history);
      await FirebaseIntegrationHelper().onNewReadingHistoryAdded(history);
    } catch (e) {
      throw Exception('Error saving reading history: $e');
    }
  }

  /// Load all reading history from SharedPreferences
  static Future<List<ReadingHistory>> loadReadingHistory() async {
    try {
      return ReadingHistoryService().readingHistoryList;
    } catch (e) {
      throw Exception('Error loading reading history: $e');
    }
  }

  static bool isReadingHistoryLoaded() =>
      ReadingHistoryService().readingHistoryList.isNotEmpty;

  /// Get reading statistics
  static Future<Map<String, dynamic>> getReadingStatistics() async {
    try {
      final history = await loadReadingHistory();

      final totalSessions = history.length;
      final totalSeconds = history.fold<int>(
        0,
        (sum, h) => sum + h.durationSeconds,
      );
      final categories = history.map((h) => h.category).toSet().toList();
      final kiransRead = history.map((h) => h.kiranIndex).toSet().length;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final todaysSessions =
          history.where((h) => h.createdAt.isAfter(today)).length;

      final thisWeek = now.subtract(Duration(days: 7));
      final weekSessions =
          history.where((h) => h.createdAt.isAfter(thisWeek)).length;

      return {
        'totalSessions': totalSessions,
        'totalDurationSeconds': totalSeconds,
        'categories': categories,
        'uniqueKiransRead': kiransRead,
        'todaysSessions': todaysSessions,
        'weekSessions': weekSessions,
      };
    } catch (e) {
      throw Exception('Error calculating statistics: $e');
    }
  }

  /// Get reading history for a specific date range
  static Future<List<ReadingHistory>> getHistoryForDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final history = await loadReadingHistory();
      return history
          .where(
            (h) =>
                h.createdAt.isAfter(startDate) && h.createdAt.isBefore(endDate),
          )
          .toList();
    } catch (e) {
      throw Exception('Error getting history for date range: $e');
    }
  }

  /// Get reading history for a specific Kiran
  static Future<List<ReadingHistory>> getHistoryForKiran(int kiranIndex) async {
    try {
      final history = await loadReadingHistory();
      return history.where((h) => h.kiranIndex == kiranIndex).toList();
    } catch (e) {
      throw Exception('Error getting history for Kiran: $e');
    }
  }

  /// Delete a specific reading history entry
  static Future<bool> deleteReadingHistory(
    ReadingHistory historyToDelete,
  ) async {
    try {
      final service = ReadingHistoryService();
      final index = service.readingHistoryList.indexWhere(
        (history) =>
            history.kiranIndex == historyToDelete.kiranIndex &&
            history.createdAt == historyToDelete.createdAt &&
            history.durationSeconds == historyToDelete.durationSeconds,
      );

      if (index != -1) {
        service.readingHistoryList.removeAt(index);
        // You might want to also sync this deletion with Firebase if needed
        await FirebaseIntegrationHelper().onReadingHistoryDeleted(
          historyToDelete,
        );
        return true;
      }
      return false;
    } catch (e) {
      throw Exception('Error deleting reading history: $e');
    }
  }
}
