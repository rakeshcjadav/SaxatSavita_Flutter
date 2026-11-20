import 'package:saxatsavita_flutter/models/saved_suvichar.dart';

enum SuvicharDateFilter { any, today, thisWeek, last30Days, custom }

class SuvicharQuery {
  final String text;
  final SuvicharDateFilter date;
  final DateTime? from;
  final DateTime? to;
  final Set<String> authors;
  final Set<int> parts;
  final Set<int> templates;

  const SuvicharQuery({
    this.text = '',
    this.date = SuvicharDateFilter.any,
    this.from,
    this.to,
    this.authors = const {},
    this.parts = const {},
    this.templates = const {},
  });

  bool get hasFilters =>
      date != SuvicharDateFilter.any ||
      authors.isNotEmpty ||
      parts.isNotEmpty ||
      templates.isNotEmpty;

  bool get isActive => text.trim().isNotEmpty || hasFilters;

  SuvicharQuery copyWith({
    String? text,
    SuvicharDateFilter? date,
    DateTime? from,
    DateTime? to,
    bool clearFrom = false,
    bool clearTo = false,
    Set<String>? authors,
    Set<int>? parts,
    Set<int>? templates,
  }) {
    return SuvicharQuery(
      text: text ?? this.text,
      date: date ?? this.date,
      from: clearFrom ? null : (from ?? this.from),
      to: clearTo ? null : (to ?? this.to),
      authors: authors ?? this.authors,
      parts: parts ?? this.parts,
      templates: templates ?? this.templates,
    );
  }

  SuvicharQuery clearedFilters() {
    return SuvicharQuery(text: text);
  }
}

List<SavedSuvichar> applySuvicharQuery(
  List<SavedSuvichar> items,
  SuvicharQuery query, {
  DateTime? now,
}) {
  final clock = now ?? DateTime.now();
  final needle = query.text.trim().toLowerCase();
  return [
    for (final item in items)
      if (_matches(item, query, needle, clock)) item,
  ];
}

bool _matches(
  SavedSuvichar item,
  SuvicharQuery query,
  String needle,
  DateTime now,
) {
  if (needle.isNotEmpty) {
    final quote = item.quote.toLowerCase();
    final author = item.author.toLowerCase();
    if (!quote.contains(needle) && !author.contains(needle)) return false;
  }
  if (query.authors.isNotEmpty && !query.authors.contains(item.author.trim())) {
    return false;
  }
  if (query.parts.isNotEmpty && !query.parts.contains(item.partNumber)) {
    return false;
  }
  if (query.templates.isNotEmpty &&
      !query.templates.contains(item.templateIndex)) {
    return false;
  }
  return _matchesDate(item.updatedAt, query, now);
}

bool _matchesDate(DateTime updatedAt, SuvicharQuery query, DateTime now) {
  final local = updatedAt.toLocal();
  switch (query.date) {
    case SuvicharDateFilter.any:
      return true;
    case SuvicharDateFilter.today:
      return _sameDay(local, now);
    case SuvicharDateFilter.thisWeek:
      final start = _startOfDay(now).subtract(Duration(days: now.weekday - 1));
      return _inRange(local, start, _endOfDay(now));
    case SuvicharDateFilter.last30Days:
      final start = _startOfDay(now).subtract(const Duration(days: 29));
      return _inRange(local, start, _endOfDay(now));
    case SuvicharDateFilter.custom:
      final from = query.from;
      final to = query.to;
      if (from == null && to == null) return true;
      final start = _startOfDay(from ?? DateTime(2000));
      final end = _endOfDay(to ?? now);
      final rangeStart = start.isBefore(end) ? start : _startOfDay(to ?? now);
      final rangeEnd = start.isBefore(end) ? end : _endOfDay(from ?? now);
      return _inRange(local, rangeStart, rangeEnd);
  }
}

bool _sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime _startOfDay(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

DateTime _endOfDay(DateTime value) {
  return DateTime(value.year, value.month, value.day, 23, 59, 59, 999);
}

bool _inRange(DateTime value, DateTime start, DateTime end) {
  return !value.isBefore(start) && !value.isAfter(end);
}
