import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:saxatsavita_flutter/helpers/firebase_integration_helper.dart';
import 'package:saxatsavita_flutter/models/reading_event_model.dart';
import 'package:saxatsavita_flutter/models/reading_history_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

/// Service to manage active reading events (in-progress reading sessions)
class ReadingEventService {
  static const String _storageKey = 'reading_events';
  static String? _cachedDeviceId;

  /// Get unique device identifier
  static Future<String> getDeviceId() async {
    if (_cachedDeviceId != null) return _cachedDeviceId!;

    try {
      final deviceInfo = DeviceInfoPlugin();

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        _cachedDeviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        _cachedDeviceId = iosInfo.identifierForVendor ?? 'ios_unknown';
      } else {
        _cachedDeviceId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
      }

      return _cachedDeviceId!;
    } catch (e) {
      debugPrint('Error getting device ID: $e');
      _cachedDeviceId = 'unknown_${DateTime.now().millisecondsSinceEpoch}';
      return _cachedDeviceId!;
    }
  }

  /// Save or update a reading event
  static Future<void> saveReadingEvent(ReadingEvent event) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final events = await getAllReadingEvents();

      // Remove existing event with same ID if it exists
      events.removeWhere((e) => e.id == event.id);

      // Add updated event
      events.add(event);

      // Save to local storage
      final eventsJson = events.map((e) => e.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(eventsJson));

      // Sync to Firebase
      await FirebaseIntegrationHelper().onReadingEventUpdated(event);

      debugPrint('📝 Reading event saved: ${event.id}');
    } catch (e) {
      debugPrint('❌ Error saving reading event: $e');
      rethrow;
    }
  }

  /// Get all reading events from local storage
  static Future<List<ReadingEvent>> getAllReadingEvents() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final eventsJson = prefs.getString(_storageKey);

      if (eventsJson == null || eventsJson.isEmpty) {
        return [];
      }

      final List<dynamic> eventsList = jsonDecode(eventsJson);
      return eventsList.map((json) => ReadingEvent.fromJson(json)).toList();
    } catch (e) {
      debugPrint('❌ Error loading reading events: $e');
      return [];
    }
  }

  /// Get reading event for a specific kiran
  static Future<ReadingEvent?> getReadingEventForKiran(int kiranIndex) async {
    try {
      final events = await getAllReadingEvents();
      final deviceId = await getDeviceId();

      // Find event for this kiran on this device
      final event =
          events.where((e) {
            return e.kiranIndex == kiranIndex && e.deviceId == deviceId;
          }).firstOrNull;

      return event;
    } catch (e) {
      debugPrint('❌ Error getting reading event for kiran: $e');
      return null;
    }
  }

  /// Get reading event by ID
  static Future<ReadingEvent?> getReadingEventById(String eventId) async {
    try {
      final events = await getAllReadingEvents();
      return events.where((e) => e.id == eventId).firstOrNull;
    } catch (e) {
      debugPrint('❌ Error getting reading event by ID: $e');
      return null;
    }
  }

  /// Delete a reading event
  static Future<void> deleteReadingEvent(String eventId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final events = await getAllReadingEvents();

      // Remove the event
      events.removeWhere((e) => e.id == eventId);

      // Save updated list
      final eventsJson = events.map((e) => e.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(eventsJson));

      // Sync deletion to Firebase
      await FirebaseIntegrationHelper().onReadingEventDeleted(eventId);

      debugPrint('🗑️ Reading event deleted: $eventId');
    } catch (e) {
      debugPrint('❌ Error deleting reading event: $e');
      rethrow;
    }
  }

  /// Convert reading event to reading history (on completion)
  static ReadingHistory convertEventToHistory(ReadingEvent event) {
    return ReadingHistory(
      category: event.category,
      durationSeconds: event.durationSeconds,
      kiranIndex: event.kiranIndex,
      partNumber: event.partNumber,
      createdAt: event.startedAt,
    );
  }

  /// Complete a reading event (convert to history and delete event)
  static Future<ReadingHistory> completeReadingEvent(ReadingEvent event) async {
    try {
      // Convert to history
      final history = convertEventToHistory(event);

      // Delete the event
      await deleteReadingEvent(event.id);

      debugPrint('✅ Reading event completed and converted to history');
      return history;
    } catch (e) {
      debugPrint('❌ Error completing reading event: $e');
      rethrow;
    }
  }

  /// Clean up stale events (older than 7 days)
  static Future<int> cleanupStaleEvents() async {
    try {
      final events = await getAllReadingEvents();
      final staleEvents = events.where((e) => e.isStale).toList();

      for (final event in staleEvents) {
        await deleteReadingEvent(event.id);
      }

      debugPrint('🧹 Cleaned up ${staleEvents.length} stale reading events');
      return staleEvents.length;
    } catch (e) {
      debugPrint('❌ Error cleaning up stale events: $e');
      return 0;
    }
  }

  /// Get count of active reading events
  static Future<int> getActiveEventCount() async {
    try {
      final events = await getAllReadingEvents();
      return events.length;
    } catch (e) {
      debugPrint('❌ Error getting active event count: $e');
      return 0;
    }
  }

  /// Check if a kiran has an active reading event
  static Future<bool> hasActiveEvent(int kiranIndex) async {
    final event = await getReadingEventForKiran(kiranIndex);
    return event != null;
  }

  /// Update event progress
  static Future<void> updateEventProgress({
    required String eventId,
    required int progress,
    required int durationSeconds,
    double? scrollPosition,
  }) async {
    try {
      final event = await getReadingEventById(eventId);
      if (event == null) {
        debugPrint('⚠️ Event not found: $eventId');
        return;
      }

      final updatedEvent = event.copyWith(
        currentProgress: progress,
        durationSeconds: durationSeconds,
        lastScrollPosition: scrollPosition,
        lastUpdatedAt: DateTime.now(),
      );

      await saveReadingEvent(updatedEvent);
    } catch (e) {
      debugPrint('❌ Error updating event progress: $e');
    }
  }

  /// Pause/resume event
  static Future<void> toggleEventPause(String eventId) async {
    try {
      final event = await getReadingEventById(eventId);
      if (event == null) {
        debugPrint('⚠️ Event not found: $eventId');
        return;
      }

      final updatedEvent = event.copyWith(
        isPaused: !event.isPaused,
        lastUpdatedAt: DateTime.now(),
      );

      await saveReadingEvent(updatedEvent);
      debugPrint('⏯️ Event ${event.isPaused ? "resumed" : "paused"}: $eventId');
    } catch (e) {
      debugPrint('❌ Error toggling event pause: $e');
    }
  }

  /// Load events from Firebase (for syncing across devices)
  static Future<void> syncFromFirebase() async {
    try {
      await FirebaseIntegrationHelper().syncReadingEventsFromFirebase();
      debugPrint('🔄 Reading events synced from Firebase');
    } catch (e) {
      debugPrint('❌ Error syncing from Firebase: $e');
    }
  }

  /// Get statistics about reading events
  static Future<Map<String, dynamic>> getEventStatistics() async {
    try {
      final events = await getAllReadingEvents();
      final totalEvents = events.length;
      final totalDuration = events.fold<int>(
        0,
        (sum, event) => sum + event.durationSeconds,
      );
      final avgProgress =
          events.isEmpty
              ? 0
              : events.fold<int>(
                    0,
                    (sum, event) => sum + event.currentProgress,
                  ) ~/
                  events.length;

      return {
        'totalEvents': totalEvents,
        'totalDurationSeconds': totalDuration,
        'averageProgress': avgProgress,
        'pausedEvents': events.where((e) => e.isPaused).length,
        'activeEvents': events.where((e) => !e.isPaused).length,
      };
    } catch (e) {
      debugPrint('❌ Error getting event statistics: $e');
      return {
        'totalEvents': 0,
        'totalDurationSeconds': 0,
        'averageProgress': 0,
        'pausedEvents': 0,
        'activeEvents': 0,
      };
    }
  }
}
