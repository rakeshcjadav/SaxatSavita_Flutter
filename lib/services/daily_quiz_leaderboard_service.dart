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
    return _load(
      dateKeys: DailyQuizService.dateKeysThroughToday(
        DailyQuizService.dateKeysForWeek(date),
      ),
      aggregate: true,
    );
  }

  Future<DailyQuizLeaderboardSnapshot> loadMonthly([DateTime? date]) {
    return _load(
      dateKeys: DailyQuizService.dateKeysThroughToday(
        DailyQuizService.dateKeysForMonth(date),
      ),
      aggregate: true,
    );
  }

  Future<DailyQuizLeaderboardSnapshot> loadYearly([DateTime? date]) {
    return _load(
      dateKeys: DailyQuizService.dateKeysThroughToday(
        DailyQuizService.dateKeysForYear(date),
      ),
      aggregate: true,
    );
  }

  static const _fetchBatchSize = 12;

  Future<DailyQuizLeaderboardSnapshot> _load({
    required List<String> dateKeys,
    bool aggregate = false,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return DailyQuizLeaderboardSnapshot.unsignedIn;
    if (!isEnabled || dateKeys.isEmpty) {
      return DailyQuizLeaderboardSnapshot.ranked(
        entries: const [],
        currentUid: uid,
      );
    }

    var lists = await _fetchDayLists(dateKeys);
    if (await _publishMissingLocalResults(dateKeys, lists)) {
      lists = await _fetchDayLists(dateKeys);
    }
    final entries =
        aggregate
            ? DailyQuizLeaderboardSnapshot.aggregateWeekly(lists)
            : [for (final list in lists) ...list];
    return DailyQuizLeaderboardSnapshot.ranked(
      entries: entries,
      currentUid: uid,
    );
  }

  /// Loads day boards in small batches so a month or year does not open
  /// hundreds of Firestore reads at once.
  Future<List<List<DailyQuizLeaderboardEntry>>> _fetchDayLists(
    List<String> dateKeys,
  ) async {
    final sync = FirebaseSyncService();
    final lists = <List<DailyQuizLeaderboardEntry>>[];
    var start = 0;
    while (start < dateKeys.length) {
      final end = start + _fetchBatchSize;
      final batch = dateKeys.sublist(
        start,
        end > dateKeys.length ? dateKeys.length : end,
      );
      lists.addAll(await Future.wait(batch.map(sync.loadDailyQuizLeaderboard)));
      start = end;
    }
    return lists;
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
