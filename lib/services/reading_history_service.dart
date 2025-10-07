import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:saxatsavita_flutter/models/reading_history_model.dart';

class ReadingHistoryService {
  static const String _storageKey = 'reading_history';
  static const int _maxEntries = 1000;

  /// Save a reading history entry to SharedPreferences
  static Future<void> saveReadingHistory(ReadingHistory history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existingHistoryJson = prefs.getStringList(_storageKey) ?? [];

      // Add new history entry
      existingHistoryJson.add(jsonEncode(history.toJson()));

      // Keep only last entries to prevent excessive storage usage
      if (existingHistoryJson.length > _maxEntries) {
        existingHistoryJson.removeRange(
          0,
          existingHistoryJson.length - _maxEntries,
        );
      }

      await prefs.setStringList(_storageKey, existingHistoryJson);
    } catch (e) {
      throw Exception('Error saving reading history: $e');
    }
  }

  /// Load all reading history from SharedPreferences
  static Future<List<ReadingHistory>> loadReadingHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJsonList = prefs.getStringList(_storageKey) ?? [];

      final history = <ReadingHistory>[];
      for (final jsonString in historyJsonList) {
        try {
          final json = jsonDecode(jsonString) as Map<String, dynamic>;
          history.add(ReadingHistory.fromJson(json));
        } catch (e) {
          // Skip invalid entries but don't fail the entire operation
          continue;
        }
      }

      // Sort by creation date (newest first)
      history.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return history;
    } catch (e) {
      throw Exception('Error loading reading history: $e');
    }
  }

  /// Clear all reading history
  static Future<void> clearReadingHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      throw Exception('Error clearing reading history: $e');
    }
  }

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
}
