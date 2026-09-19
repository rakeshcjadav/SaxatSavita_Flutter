import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:saxatsavita_flutter/models/kiran_quiz_model.dart';
import 'package:saxatsavita_flutter/services/firebase_sync_service.dart';
import 'package:saxatsavita_flutter/services/remote_config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class KiranQuizService {
  static final KiranQuizService _instance = KiranQuizService._internal();
  factory KiranQuizService() => _instance;
  KiranQuizService._internal();

  static const firstQuizBadge = 'badge_first_quiz';
  static const _bankAsset =
      'assets/book/saxatsavita/quizzes/kiran_quizzes.json';
  static const _bankPref = 'kiran_quiz_bank';
  static const _resultsPref = 'quiz_results';

  Map<String, KiranQuiz>? _bank;
  List<KiranQuizResult>? _results;
  Future<void>? _bankLoad;
  Future<void>? _resultsLoad;

  static String docId(int part, int kiranIndex) => '${part}_$kiranIndex';

  void clearMemoryCache() {
    _bank = null;
    _results = null;
    _bankLoad = null;
    _resultsLoad = null;
  }

  Future<bool> isEnabled() async {
    return RemoteConfigService().enableQuiz;
  }

  Future<KiranQuiz?> quizFor(int part, int kiranIndex) async {
    if (!RemoteConfigService().enableQuiz) return null;
    await _ensureBank();
    final quiz = _bank?[docId(part, kiranIndex)];
    if (quiz == null || quiz.questions.isEmpty) return null;
    return quiz;
  }

  Future<bool> hasQuiz(int part, int kiranIndex) async {
    return await quizFor(part, kiranIndex) != null;
  }

  Future<KiranQuizResult?> resultFor(int part, int kiranIndex) async {
    await _ensureResults();
    for (final result in _results ?? const <KiranQuizResult>[]) {
      if (result.part == part && result.kiranIndex == kiranIndex) {
        return result;
      }
    }
    return null;
  }

  Future<bool> hasScoredAttempt(int part, int kiranIndex) async {
    return await resultFor(part, kiranIndex) != null;
  }

  int pointsForScore({required int score, required int total}) {
    final config = RemoteConfigService();
    var points = config.quizPointsPerCorrect * score;
    if (total > 0 && score == total) {
      points += config.quizPerfectBonus;
    }
    return points;
  }

  Future<int> totalPoints() async {
    await _ensureResults();
    return (_results ?? const <KiranQuizResult>[]).fold<int>(
      0,
      (sum, result) => sum + result.pointsAwarded,
    );
  }

  Future<int> completedQuizCount() async {
    await _ensureResults();
    return _results?.length ?? 0;
  }

  Future<bool> hasFirstQuizBadge() async {
    await _ensureResults();
    return (_results ?? const <KiranQuizResult>[]).any(
      (result) => result.rewardIds.contains(firstQuizBadge),
    );
  }

  /// First attempt is scored. Later calls keep the original result.
  Future<KiranQuizResult> submitAttempt({
    required KiranQuiz quiz,
    required int score,
  }) async {
    await _ensureResults();
    final existing = await resultFor(quiz.part, quiz.kiranIndex);
    if (existing != null) {
      return existing;
    }

    final rewards = <String>[];
    if (!await hasFirstQuizBadge()) {
      rewards.add(firstQuizBadge);
    }
    final result = KiranQuizResult(
      part: quiz.part,
      kiranIndex: quiz.kiranIndex,
      score: score,
      total: quiz.questions.length,
      completedAt: DateTime.now(),
      quizVersion: quiz.version,
      rewardIds: rewards,
      pointsAwarded: pointsForScore(score: score, total: quiz.questions.length),
    );

    final results = List<KiranQuizResult>.from(_results ?? const []);
    results.add(result);
    _results = results;
    await _persistResults();
    await FirebaseSyncService().syncQuizResult(result);
    return result;
  }

  Future<void> mergeRemoteResults(List<KiranQuizResult> remote) async {
    await _ensureResults();
    final merged = <String, KiranQuizResult>{
      for (final result in _results ?? const <KiranQuizResult>[])
        result.docId: result,
    };
    for (final result in remote) {
      final local = merged[result.docId];
      if (local == null || result.completedAt.isAfter(local.completedAt)) {
        merged[result.docId] = result;
      }
    }
    _results = merged.values.toList();
    await _persistResults();
  }

  Future<void> refreshBankFromFirestore() async {
    await _ensureBank();
    if (FirebaseAuth.instance.currentUser == null) return;
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('kiranQuizzes').get();
      if (snapshot.docs.isEmpty) return;
      final bank = Map<String, KiranQuiz>.from(_bank ?? {});
      for (final doc in snapshot.docs) {
        final quiz = KiranQuiz.fromMap(doc.data());
        if (quiz.questions.isEmpty) continue;
        final current = bank[quiz.docId];
        if (current == null || quiz.version >= current.version) {
          bank[quiz.docId] = quiz;
        }
      }
      _bank = bank;
      await _persistBank();
    } catch (e) {
      debugPrint('KiranQuizService: Firestore bank fetch failed: $e');
    }
  }

  Future<void> _ensureBank() {
    return _bankLoad ??= _loadBank();
  }

  Future<void> _ensureResults() {
    return _resultsLoad ??= _loadResults();
  }

  Future<void> _loadBank() async {
    final bank = <String, KiranQuiz>{};
    try {
      final raw = await rootBundle.loadString(_bankAsset);
      _mergeBankJson(bank, raw);
    } catch (e) {
      debugPrint('KiranQuizService: seed bank missing: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_bankPref);
      if (cached != null && cached.isNotEmpty) {
        _mergeBankJson(bank, cached);
      }
    } catch (e) {
      debugPrint('KiranQuizService: cache bank failed: $e');
    }

    _bank = bank;
    unawaited(refreshBankFromFirestore());
  }

  void _mergeBankJson(Map<String, KiranQuiz> bank, String raw) {
    final decoded = jsonDecode(raw);
    final items =
        decoded is Map
            ? (decoded['quizzes'] as List<dynamic>? ?? [decoded])
            : decoded as List<dynamic>;
    for (final item in items) {
      if (item is! Map) continue;
      final quiz = KiranQuiz.fromMap(Map<String, dynamic>.from(item));
      if (quiz.questions.isEmpty) continue;
      final current = bank[quiz.docId];
      if (current == null || quiz.version >= current.version) {
        bank[quiz.docId] = quiz;
      }
    }
  }

  Future<void> _persistBank() async {
    final prefs = await SharedPreferences.getInstance();
    final quizzes = (_bank ?? {}).values.map((quiz) => quiz.toMap()).toList();
    await prefs.setString(_bankPref, jsonEncode({'quizzes': quizzes}));
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
                    KiranQuizResult.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList();
    } catch (e) {
      debugPrint('KiranQuizService: load results failed: $e');
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
}
