class DailyQuizLeaderboardEntry {
  final String uid;
  final String displayName;
  final int score;
  final int total;
  final int pointsAwarded;
  final DateTime completedAt;
  final int daysCompleted;

  const DailyQuizLeaderboardEntry({
    required this.uid,
    this.displayName = '',
    this.score = 0,
    this.total = 0,
    this.pointsAwarded = 0,
    required this.completedAt,
    this.daysCompleted = 1,
  });

  factory DailyQuizLeaderboardEntry.fromMap(
    String docId,
    Map<String, dynamic> map,
  ) {
    final uid = (map['uid'] as String? ?? docId).trim();
    return DailyQuizLeaderboardEntry(
      uid: uid,
      displayName: sanitizeDisplayName(map['displayName']?.toString()),
      score: _readInt(map['score']),
      total: _readInt(map['total']),
      pointsAwarded: _readInt(map['pointsAwarded']),
      completedAt:
          DateTime.tryParse(map['completedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  DailyQuizLeaderboardEntry mergedWith(DailyQuizLeaderboardEntry other) {
    final later = other.completedAt.isAfter(completedAt) ? other : this;
    final named =
        displayName.isEmpty
            ? other.displayName
            : other.displayName.isEmpty
            ? displayName
            : later.displayName;
    return DailyQuizLeaderboardEntry(
      uid: uid,
      displayName: named,
      score: score + other.score,
      total: total + other.total,
      pointsAwarded: pointsAwarded + other.pointsAwarded,
      completedAt: later.completedAt,
      daysCompleted: daysCompleted + other.daysCompleted,
    );
  }

  static String sanitizeDisplayName(String? raw) {
    final name = (raw ?? '').trim();
    if (name.isEmpty || name.contains('@')) return '';
    if (name.length <= 40) return name;
    return name.substring(0, 40).trim();
  }

  static int compare(DailyQuizLeaderboardEntry a, DailyQuizLeaderboardEntry b) {
    final byPoints = b.pointsAwarded.compareTo(a.pointsAwarded);
    if (byPoints != 0) return byPoints;
    final byScore = b.score.compareTo(a.score);
    if (byScore != 0) return byScore;
    final byTime = a.completedAt.compareTo(b.completedAt);
    if (byTime != 0) return byTime;
    return a.uid.compareTo(b.uid);
  }
}

class DailyQuizLeaderboardSnapshot {
  final List<DailyQuizLeaderboardEntry> entries;
  final DailyQuizLeaderboardEntry? currentUser;
  final int? currentUserRank;
  final bool isAuthenticated;

  const DailyQuizLeaderboardSnapshot({
    this.entries = const [],
    this.currentUser,
    this.currentUserRank,
    this.isAuthenticated = true,
  });

  static const unsignedIn = DailyQuizLeaderboardSnapshot(
    isAuthenticated: false,
  );

  factory DailyQuizLeaderboardSnapshot.ranked({
    required List<DailyQuizLeaderboardEntry> entries,
    String? currentUid,
    bool isAuthenticated = true,
  }) {
    final sorted = List<DailyQuizLeaderboardEntry>.from(entries)
      ..sort(DailyQuizLeaderboardEntry.compare);
    DailyQuizLeaderboardEntry? me;
    int? rank;
    if (currentUid != null && currentUid.isNotEmpty) {
      for (var i = 0; i < sorted.length; i++) {
        if (sorted[i].uid == currentUid) {
          me = sorted[i];
          rank = i + 1;
          break;
        }
      }
    }
    return DailyQuizLeaderboardSnapshot(
      entries: sorted,
      currentUser: me,
      currentUserRank: rank,
      isAuthenticated: isAuthenticated,
    );
  }

  static List<DailyQuizLeaderboardEntry> aggregateWeekly(
    Iterable<List<DailyQuizLeaderboardEntry>> dailyLists,
  ) {
    final byUid = <String, DailyQuizLeaderboardEntry>{};
    for (final list in dailyLists) {
      for (final entry in list) {
        if (entry.uid.isEmpty) continue;
        final existing = byUid[entry.uid];
        byUid[entry.uid] =
            existing == null ? entry : existing.mergedWith(entry);
      }
    }
    return byUid.values.toList();
  }

  List<DailyQuizLeaderboardEntry> get top5 => entries.take(5).toList();

  bool get currentUserInTop5 =>
      currentUserRank != null && currentUserRank! <= 5;

  bool get isEmpty => entries.isEmpty;
}

int _readInt(dynamic value, [int fallback = 0]) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
