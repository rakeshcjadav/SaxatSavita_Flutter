import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';
import 'package:saxatsavita_flutter/services/utils.dart';

/// Associates a [KiranInfo] with its part number so calendar entries
/// can navigate directly to the correct [KiranReadPage].
class KiranCalendarEntry {
  final int partNumber;
  final KiranInfo kiranInfo;

  /// The actual publication date (with real year) for display purposes.
  final DateTime date;

  const KiranCalendarEntry({
    required this.partNumber,
    required this.kiranInfo,
    required this.date,
  });
}

/// Loads all five parts and builds a map from calendar date → list of
/// [KiranCalendarEntry] objects, so the calendar view can render event
/// markers and show per-day kiran lists.
class KiranCalendarService {
  static final KiranCalendarService _instance =
      KiranCalendarService._internal();
  factory KiranCalendarService() => _instance;
  KiranCalendarService._internal();

  // Date (midnight UTC) → entries for that day
  Map<DateTime, List<KiranCalendarEntry>>? _calendar;

  bool get isLoaded => _calendar != null;

  /// Returns a normalised (midnight UTC) key using a fixed year (2000) so
  /// entries from the same month/day across different years share one bucket.
  static DateTime _normalise(DateTime date) =>
      DateTime.utc(2000, date.month, date.day);

  /// Load and index all parts. Safe to call multiple times — subsequent
  /// calls are no-ops once already loaded.
  Future<void> load() async {
    if (_calendar != null) return;

    final Map<DateTime, List<KiranCalendarEntry>> calendar = {};

    for (int part = 1; part <= 5; part++) {
      final String raw = await rootBundle.loadString(
        'assets/book/saxatsavita/part$part/_kirans_.json',
      );
      final Map<String, dynamic> json = jsonDecode(raw);
      final List<dynamic> list = json['list'] as List<dynamic>;

      for (final item in list) {
        final KiranInfo info = KiranInfo.fromMap(item as Map<String, dynamic>);
        final DateTime? date = Utils.parseKiranDate(info.date);
        if (date == null) continue;

        final DateTime key = _normalise(date);
        calendar
            .putIfAbsent(key, () => [])
            .add(
              KiranCalendarEntry(partNumber: part, kiranInfo: info, date: date),
            );
      }
    }

    // Sort entries within each day chronologically (oldest year first)
    for (final entries in calendar.values) {
      entries.sort((a, b) => a.date.compareTo(b.date));
    }

    _calendar = calendar;
  }

  /// Returns entries for [day], or an empty list if none.
  List<KiranCalendarEntry> entriesFor(DateTime day) {
    if (_calendar == null) return [];
    return _calendar![_normalise(day)] ?? [];
  }

  /// Returns all dates that have at least one kiran.
  Iterable<DateTime> get datesWithKirans =>
      _calendar?.keys ?? const Iterable.empty();

  /// Earliest date across all kirans, or null if not loaded.
  DateTime? get firstDate {
    if (_calendar == null || _calendar!.isEmpty) return null;
    return _calendar!.keys.reduce((a, b) => a.isBefore(b) ? a : b);
  }

  /// Latest date across all kirans, or null if not loaded.
  DateTime? get lastDate {
    if (_calendar == null || _calendar!.isEmpty) return null;
    return _calendar!.keys.reduce((a, b) => a.isAfter(b) ? a : b);
  }
}
