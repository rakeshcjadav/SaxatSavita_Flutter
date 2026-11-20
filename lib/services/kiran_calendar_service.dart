import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:saxatsavita_flutter/helpers/kiran_tithi.dart';
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

  /// Kiran index → lunar date such as `સંવત્ ૨૦૩૧ વૈશાખ સુદિ-૧૦`.
  /// Empty string means the kiran was checked and has no tithi.
  final Map<int, String> _tithis = {};

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

  /// Lunar date for each entry, loaded from the kiran's meta date line.
  Future<Map<int, String>> tithisFor(List<KiranCalendarEntry> entries) {
    return tithisForIndexes([
      for (final entry in entries)
        (partNumber: entry.partNumber, index: entry.kiranInfo.index),
    ]);
  }

  /// Lunar date for each kiran, keyed by global kiran index.
  ///
  /// Already loaded kirans are returned from cache. An empty result for an
  /// index means that kiran has no readable tithi.
  Future<Map<int, String>> tithisForIndexes(
    List<({int partNumber, int index})> kirans,
  ) async {
    final pending = <({int partNumber, int index})>[];
    for (final kiran in kirans) {
      if (!_tithis.containsKey(kiran.index)) pending.add(kiran);
    }

    await Future.wait(
      pending.map((kiran) async {
        try {
          final raw = await rootBundle.loadString(
            'assets/book/saxatsavita/part${kiran.partNumber}/kiran_${kiran.index}.json',
          );
          final json = jsonDecode(raw);
          final metaDate =
              json is Map
                  ? (json['meta']?['date'] as String? ?? '').trim()
                  : '';
          _tithis[kiran.index] = kiranTithiFromMetaDate(metaDate) ?? '';
        } catch (_) {
          _tithis[kiran.index] = '';
        }
      }),
    );

    return {
      for (final kiran in kirans)
        if ((_tithis[kiran.index] ?? '').isNotEmpty)
          kiran.index: _tithis[kiran.index]!,
    };
  }

  /// Returns entries for [day], or an empty list if none.
  /// When [village] is set, only kirans that sat in that village are returned.
  List<KiranCalendarEntry> entriesFor(DateTime day, {String? village}) {
    if (_calendar == null) return [];
    final list = _calendar![_normalise(day)] ?? [];
    if (village == null || village.isEmpty) return list;
    return list.where((e) => e.kiranInfo.visitsVillage(village)).toList();
  }

  /// Unique villages across all dated kirans, sorted.
  List<String> get allVillages {
    if (_calendar == null) return const [];
    final set = <String>{};
    for (final entries in _calendar!.values) {
      for (final entry in entries) {
        set.addAll(entry.kiranInfo.places);
        if (entry.kiranInfo.places.isEmpty &&
            entry.kiranInfo.place.isNotEmpty) {
          set.add(entry.kiranInfo.place);
        }
      }
    }
    final list = set.toList()..sort();
    return list;
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
