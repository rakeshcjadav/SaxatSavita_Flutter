import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:saxatsavita_flutter/models/inbox_notification.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Recent notifications shown by this app, newest first.
class NotificationInboxService {
  static final NotificationInboxService _instance =
      NotificationInboxService._();
  factory NotificationInboxService() => _instance;
  NotificationInboxService._();

  static const _prefsKey = 'notification_inbox_v1';
  static const _maxItems = 50;

  final ValueNotifier<int> revision = ValueNotifier(0);
  final List<InboxNotification> _items = [];
  Future<void> _tail = Future<void>.value();

  List<InboxNotification> get items => List.unmodifiable(_items);
  int get count => _items.length;

  Future<void> ensureLoaded() {
    return _serialized(() async {
      await _load();
    });
  }

  /// Saves a notification that was just shown.
  ///
  /// Tray sync uses [fromActiveTray] so a notification still sitting in the
  /// shade is not added again on the next app open.
  Future<void> record({
    int? systemId,
    String? tag,
    required String title,
    required String body,
    String? payload,
    bool fromActiveTray = false,
  }) {
    return _serialized(() async {
      final titleText = title.trim();
      final bodyText = body.trim();
      if (titleText.isEmpty && bodyText.isEmpty) return;

      await _load();
      final receivedAt = DateTime.now();
      final id = _idFor(systemId, titleText, bodyText, receivedAt);
      if (_items.any((item) => item.id == id)) return;
      if (fromActiveTray &&
          _items.any(
            (item) =>
                item.systemId == systemId &&
                item.title == titleText &&
                item.body == bodyText,
          )) {
        return;
      }

      _items.insert(
        0,
        InboxNotification(
          id: id,
          systemId: systemId,
          tag: tag,
          title: titleText,
          body: bodyText,
          payload: payload,
          receivedAt: receivedAt,
        ),
      );
      if (_items.length > _maxItems) {
        _items.removeRange(_maxItems, _items.length);
      }
      await _save();
      revision.value++;
    });
  }

  Future<void> remove(String id) {
    return _serialized(() async {
      await _load();
      final before = _items.length;
      _items.removeWhere((item) => item.id == id);
      if (_items.length == before) return;
      await _save();
      revision.value++;
    });
  }

  Future<void> _serialized(Future<void> Function() action) {
    final run = _tail.then((_) => action());
    _tail = run.then((_) {}, onError: (Object _, StackTrace _) {});
    return run;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    _items.clear();
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;
      for (final entry in decoded) {
        if (entry is Map) {
          final item = InboxNotification.fromJson(
            Map<String, dynamic>.from(entry),
          );
          if (item.id.isEmpty) continue;
          _items.add(item);
        }
      }
    } catch (e) {
      debugPrint('Notification inbox load failed: $e');
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_items.map((item) => item.toJson()).toList());
    await prefs.setString(_prefsKey, encoded);
  }

  static String _idFor(
    int? systemId,
    String title,
    String body,
    DateTime receivedAt,
  ) {
    final day =
        '${receivedAt.year.toString().padLeft(4, '0')}-'
        '${receivedAt.month.toString().padLeft(2, '0')}-'
        '${receivedAt.day.toString().padLeft(2, '0')}';
    return '${systemId ?? ''}|$day|$title|$body';
  }
}
