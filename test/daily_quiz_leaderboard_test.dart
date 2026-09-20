import 'package:flutter_test/flutter_test.dart';
import 'package:saxatsavita_flutter/models/daily_quiz_leaderboard_model.dart';
import 'package:saxatsavita_flutter/services/daily_quiz_service.dart';

void main() {
  group('DailyQuizService week helpers', () {
    test('startOfWeek is Monday of the local calendar week', () {
      final wednesday = DateTime(2026, 9, 16);
      expect(DailyQuizService.startOfWeek(wednesday), DateTime(2026, 9, 14));
      expect(
        DailyQuizService.startOfWeek(DateTime(2026, 9, 14)),
        DateTime(2026, 9, 14),
      );
      expect(
        DailyQuizService.startOfWeek(DateTime(2026, 9, 20)),
        DateTime(2026, 9, 14),
      );
    });

    test('dateKeysForWeek is Monday through Sunday', () {
      expect(DailyQuizService.dateKeysForWeek(DateTime(2026, 9, 16)), [
        '2026-09-14',
        '2026-09-15',
        '2026-09-16',
        '2026-09-17',
        '2026-09-18',
        '2026-09-19',
        '2026-09-20',
      ]);
    });
  });

  group('DailyQuizLeaderboardEntry', () {
    test('sanitizeDisplayName drops emails and empty values', () {
      expect(
        DailyQuizLeaderboardEntry.sanitizeDisplayName('Ada Lovelace'),
        'Ada Lovelace',
      );
      expect(
        DailyQuizLeaderboardEntry.sanitizeDisplayName('ada@example.com'),
        '',
      );
      expect(DailyQuizLeaderboardEntry.sanitizeDisplayName('  '), '');
      expect(DailyQuizLeaderboardEntry.sanitizeDisplayName(null), '');
    });

    test('ranks by points, then score, then earlier completion', () {
      final later = DateTime(2026, 9, 20, 10);
      final earlier = DateTime(2026, 9, 20, 8);
      final a = DailyQuizLeaderboardEntry(
        uid: 'a',
        pointsAwarded: 30,
        score: 5,
        completedAt: later,
      );
      final b = DailyQuizLeaderboardEntry(
        uid: 'b',
        pointsAwarded: 25,
        score: 5,
        completedAt: earlier,
      );
      final c = DailyQuizLeaderboardEntry(
        uid: 'c',
        pointsAwarded: 30,
        score: 4,
        completedAt: earlier,
      );
      final d = DailyQuizLeaderboardEntry(
        uid: 'd',
        pointsAwarded: 30,
        score: 5,
        completedAt: earlier,
      );

      final snapshot = DailyQuizLeaderboardSnapshot.ranked(
        entries: [a, b, c, d],
        currentUid: 'b',
      );

      expect(snapshot.entries.map((e) => e.uid), ['d', 'a', 'c', 'b']);
      expect(snapshot.currentUserRank, 4);
      expect(snapshot.currentUserInTop5, isTrue);
      expect(snapshot.top5.map((e) => e.uid), ['d', 'a', 'c', 'b']);
    });

    test('aggregates weekly points per user', () {
      final day1 = [
        DailyQuizLeaderboardEntry(
          uid: 'a',
          displayName: 'Asha',
          pointsAwarded: 30,
          score: 5,
          completedAt: DateTime(2026, 9, 14, 9),
        ),
        DailyQuizLeaderboardEntry(
          uid: 'b',
          displayName: 'Bina',
          pointsAwarded: 20,
          score: 4,
          completedAt: DateTime(2026, 9, 14, 10),
        ),
      ];
      final day2 = [
        DailyQuizLeaderboardEntry(
          uid: 'a',
          displayName: '',
          pointsAwarded: 25,
          score: 4,
          completedAt: DateTime(2026, 9, 15, 9),
        ),
      ];

      final weekly = DailyQuizLeaderboardSnapshot.ranked(
        entries: DailyQuizLeaderboardSnapshot.aggregateWeekly([day1, day2]),
        currentUid: 'a',
      );

      expect(weekly.entries, hasLength(2));
      expect(weekly.entries.first.uid, 'a');
      expect(weekly.entries.first.pointsAwarded, 55);
      expect(weekly.entries.first.score, 9);
      expect(weekly.entries.first.daysCompleted, 2);
      expect(weekly.entries.first.displayName, 'Asha');
      expect(weekly.currentUserRank, 1);
    });

    test('highlights current user outside top 5', () {
      final entries = List.generate(6, (i) {
        return DailyQuizLeaderboardEntry(
          uid: 'u$i',
          pointsAwarded: 30 - i,
          score: 5,
          completedAt: DateTime(2026, 9, 20, i + 1),
        );
      });
      final snapshot = DailyQuizLeaderboardSnapshot.ranked(
        entries: entries,
        currentUid: 'u5',
      );
      expect(snapshot.currentUserRank, 6);
      expect(snapshot.currentUserInTop5, isFalse);
      expect(snapshot.top5, hasLength(5));
    });
  });
}
