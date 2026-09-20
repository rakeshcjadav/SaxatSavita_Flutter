import 'package:firebase_auth/firebase_auth.dart';
import 'package:saxatsavita_flutter/models/daily_quiz_leaderboard_model.dart';
import 'package:saxatsavita_flutter/services/daily_quiz_service.dart';
import 'package:saxatsavita_flutter/services/firebase_sync_service.dart';
import 'package:saxatsavita_flutter/services/remote_config_service.dart';

class DailyQuizLeaderboardService {
  static final DailyQuizLeaderboardService _instance =
      DailyQuizLeaderboardService._internal();
  factory DailyQuizLeaderboardService() => _instance;
  DailyQuizLeaderboardService._internal();

  bool get isEnabled => RemoteConfigService().enableDailyQuiz;

  Future<DailyQuizLeaderboardSnapshot> loadDaily([DateTime? date]) {
    return _load(dateKeys: [DailyQuizService.dateKey(date)]);
  }

  Future<DailyQuizLeaderboardSnapshot> loadWeekly([DateTime? date]) {
    final today = DailyQuizService.dateOnly();
    final keys =
        DailyQuizService.dateKeysForWeek(date).where((key) {
          final parsed = DailyQuizService.parseDateKey(key);
          if (parsed == null) return false;
          return !parsed.isAfter(today);
        }).toList();
    return _load(dateKeys: keys, aggregateWeekly: true);
  }

  Future<DailyQuizLeaderboardSnapshot> _load({
    required List<String> dateKeys,
    bool aggregateWeekly = false,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return DailyQuizLeaderboardSnapshot.unsignedIn;
    if (!isEnabled || dateKeys.isEmpty) {
      return DailyQuizLeaderboardSnapshot.ranked(
        entries: const [],
        currentUid: uid,
      );
    }

    final sync = FirebaseSyncService();
    var lists = await Future.wait(dateKeys.map(sync.loadDailyQuizLeaderboard));
    if (await _publishMissingLocalResults(dateKeys, lists)) {
      lists = await Future.wait(dateKeys.map(sync.loadDailyQuizLeaderboard));
    }
    final entries =
        aggregateWeekly
            ? DailyQuizLeaderboardSnapshot.aggregateWeekly(lists)
            : [for (final list in lists) ...list];
    return DailyQuizLeaderboardSnapshot.ranked(
      entries: entries,
      currentUid: uid,
    );
  }

  /// Publishes already-completed local results that are missing publicly
  /// (e.g. scores from before the leaderboard existed).
  Future<bool> _publishMissingLocalResults(
    List<String> dateKeys,
    List<List<DailyQuizLeaderboardEntry>> lists,
  ) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return false;
    var wrote = false;
    for (var i = 0; i < dateKeys.length; i++) {
      final hasEntry = lists[i].any((entry) => entry.uid == uid);
      if (hasEntry) continue;
      final result = await DailyQuizService().resultFor(dateKeys[i]);
      if (result == null) continue;
      await FirebaseSyncService().syncDailyQuizResult(result);
      wrote = true;
    }
    return wrote;
  }
}
