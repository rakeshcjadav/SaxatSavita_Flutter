import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:saxatsavita_flutter/models/daily_quiz_model.dart';
import 'package:saxatsavita_flutter/services/firebase_sync_service.dart';
import 'package:saxatsavita_flutter/services/remote_config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyQuizService {
  static final DailyQuizService _instance = DailyQuizService._internal();
  factory DailyQuizService() => _instance;
  DailyQuizService._internal();

  static const assetPath =
      'assets/book/saxatsavita/quizzes/daily_quiz_bank.json';
  static const defaultReminderHour = 8;
  static const defaultReminderMinute = 0;
  static const scoredQuestionCount = 5;
  static const _resultsPref = 'daily_quiz_results';
  static const _bankPref = 'daily_quiz_bank_remote';
  static const _reminderEnabledPref = 'daily_quiz_reminder_enabled';
  static const _reminderHourPref = 'daily_quiz_reminder_hour';
  static const _reminderMinutePref = 'daily_quiz_reminder_minute';
  static const _fetchTimeout = Duration(seconds: 4);

  DailyQuizBank? _bank;
  List<DailyQuizResult>? _results;
  DailyQuizPack? _datedPackCache;
  String? _datedPackCacheKey;
  Future<void>? _bankLoad;
  Future<void>? _resultsLoad;

  bool get isEnabled => RemoteConfigService().enableDailyQuiz;

  static String dateKey([DateTime? date]) {
    final local = date ?? DateTime.now();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static DateTime dateOnly([DateTime? date]) {
    final local = date ?? DateTime.now();
    return DateTime(local.year, local.month, local.day);
  }

  /// Monday of the local calendar week that contains [date].
  static DateTime startOfWeek([DateTime? date]) {
    final local = dateOnly(date);
    return DateTime(
      local.year,
      local.month,
      local.day - (local.weekday - DateTime.monday),
    );
  }

  static DateTime? parseDateKey(String key) {
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  /// Local Monday–Sunday date keys for the week containing [date].
  static List<String> dateKeysForWeek([DateTime? date]) {
    final start = startOfWeek(date);
    return List.generate(7, (i) {
      return dateKey(DateTime(start.year, start.month, start.day + i));
    });
  }

  void clearMemoryCache() {
    _bank = null;
    _results = null;
    _datedPackCache = null;
    _datedPackCacheKey = null;
    _bankLoad = null;
    _resultsLoad = null;
  }

  int pointsForScore({required int score, required int total}) {
    final config = RemoteConfigService();
    var points = config.quizPointsPerCorrect * score;
    if (total > 0 && score == total) {
      points += config.quizPerfectBonus;
    }
    return points;
  }

  Future<DailyQuizPack?> packForToday() => packForDate(dateOnly());

  Future<DailyQuizPack?> packForDate(DateTime date) async {
    if (!isEnabled) return null;
    await _ensureBank();
    final key = dateKey(date);
    final remote = await _fetchDatedPack(key);
    if (remote != null) return remote;

    final packs = _bank?.packs ?? const <DailyQuizPack>[];
    if (packs.isEmpty) return null;
    final days = dateOnly(date).difference(DateTime(1970, 1, 1)).inDays;
    final index = days.abs() % packs.length;
    return packs[index];
  }

  Future<DailyQuizResult?> resultForToday() => resultFor(dateKey());

  Future<DailyQuizResult?> resultFor(String key) async {
    await _ensureResults();
    for (final result in _results ?? const <DailyQuizResult>[]) {
      if (result.dateKey == key) return result;
    }
    return null;
  }

  Future<int> currentStreak() async {
    await _ensureResults();
    final completed =
        (_results ?? const <DailyQuizResult>[])
            .map((item) => item.dateKey)
            .toSet();
    if (completed.isEmpty) return 0;

    var cursor = dateOnly();
    if (!completed.contains(dateKey(cursor))) {
      cursor = cursor.subtract(const Duration(days: 1));
    }
    var streak = 0;
    while (completed.contains(dateKey(cursor))) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  Future<DailyQuizResult> submitAttempt({
    required DailyQuizPack pack,
    required int score,
    required List<int> answers,
    DateTime? date,
  }) async {
    final key = dateKey(date);
    await _ensureResults();
    final existing = await resultFor(key);
    if (existing != null) return existing;

    final questions = pack.scoredQuestions;
    final result = DailyQuizResult(
      dateKey: key,
      packId: pack.id,
      score: score,
      total: questions.length,
      completedAt: DateTime.now(),
      pointsAwarded: pointsForScore(score: score, total: questions.length),
      answers: answers,
      questionIds: questions.map((item) => item.id).toList(),
    );

    final results = List<DailyQuizResult>.from(_results ?? const []);
    results.add(result);
    _results = results;
    await _persistResults();
    await _syncResult(result);
    return result;
  }

  Future<void> mergeRemoteResults(List<DailyQuizResult> remote) async {
    await _ensureResults();
    final merged = <String, DailyQuizResult>{
      for (final result in _results ?? const <DailyQuizResult>[])
        result.docId: result,
    };
    for (final result in remote) {
      if (result.dateKey.isEmpty) continue;
      final local = merged[result.docId];
      if (local == null || result.completedAt.isAfter(local.completedAt)) {
        merged[result.docId] = result;
      }
    }
    _results = merged.values.toList();
    await _persistResults();
  }

  Future<void> syncLocalResultsToFirebase() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    await _ensureResults();
    final sync = FirebaseSyncService();
    for (final result in _results ?? const <DailyQuizResult>[]) {
      await sync.syncDailyQuizResult(result);
    }
  }

  Future<bool> reminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_reminderEnabledPref) ?? true;
  }

  Future<({int hour, int minute})> reminderTime() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      hour: prefs.getInt(_reminderHourPref) ?? defaultReminderHour,
      minute: prefs.getInt(_reminderMinutePref) ?? defaultReminderMinute,
    );
  }

  Future<void> setReminderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderEnabledPref, enabled);
  }

  Future<void> setReminderTime({required int hour, required int minute}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderHourPref, hour);
    await prefs.setInt(_reminderMinutePref, minute);
  }

  Future<void> _ensureBank() {
    return _bankLoad ??= _loadBank();
  }

  Future<void> _ensureResults() {
    return _resultsLoad ??= _loadResults();
  }

  Future<void> _loadBank() async {
    DailyQuizBank bank = const DailyQuizBank();
    try {
      final raw = await rootBundle.loadString(assetPath);
      bank = DailyQuizBank.fromMap(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
      );
    } catch (e) {
      debugPrint('DailyQuizService: asset bank failed: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_bankPref);
      if (cached != null && cached.isNotEmpty) {
        final remote = DailyQuizBank.fromMap(
          Map<String, dynamic>.from(jsonDecode(cached) as Map),
        );
        if (remote.packs.isNotEmpty) {
          bank = remote;
        }
      }
    } catch (e) {
      debugPrint('DailyQuizService: cached bank failed: $e');
    }

    _bank = bank;
    unawaited(_refreshBankFromFirestore());
  }

  Future<void> _refreshBankFromFirestore() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('dailyQuizBank')
          .doc('current')
          .get()
          .timeout(_fetchTimeout);
      if (!snapshot.exists || snapshot.data() == null) return;
      final remote = DailyQuizBank.fromMap(snapshot.data()!);
      if (remote.packs.isEmpty) return;
      _bank = remote;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_bankPref, jsonEncode(remote.toMap()));
    } catch (e) {
      debugPrint('DailyQuizService: Firestore bank fetch failed: $e');
    }
  }

  Future<DailyQuizPack?> _fetchDatedPack(String key) async {
    if (_datedPackCacheKey == key && _datedPackCache != null) {
      return _datedPackCache;
    }
    if (FirebaseAuth.instance.currentUser == null) return null;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('dailyQuizzes')
          .doc(key)
          .get()
          .timeout(_fetchTimeout);
      if (!snapshot.exists || snapshot.data() == null) return null;
      final pack = DailyQuizPack.fromMap({
        'id': snapshot.data()?['id'] ?? key,
        ...snapshot.data()!,
      });
      if (!pack.isValid) return null;
      _datedPackCache = pack;
      _datedPackCacheKey = key;
      return pack;
    } catch (e) {
      debugPrint('DailyQuizService: dated pack $key failed: $e');
      return null;
    }
  }

  Future<void> _loadResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_resultsPref);
      if (raw == null || raw.isEmpty) {
        _results = [];
        return;
      }
      final list = jsonDecode(raw) as List<dynamic>;
      _results =
          list
              .whereType<Map>()
              .map(
                (item) =>
                    DailyQuizResult.fromJson(Map<String, dynamic>.from(item)),
              )
              .where((item) => item.dateKey.isNotEmpty)
              .toList();
    } catch (e) {
      debugPrint('DailyQuizService: load results failed: $e');
      _results = [];
    }
  }

  Future<void> _persistResults() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _resultsPref,
      jsonEncode((_results ?? []).map((item) => item.toJson()).toList()),
    );
  }

  Future<void> _syncResult(DailyQuizResult result) async {
    if (FirebaseAuth.instance.currentUser == null) return;
    await FirebaseSyncService().syncDailyQuizResult(result);
  }
}
