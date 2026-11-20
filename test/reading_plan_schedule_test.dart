import 'package:flutter_test/flutter_test.dart';
import 'package:saxatsavita_flutter/helpers/reading_plan_schedule.dart';

ReadingPlanSchedule schedule({
  int startKiran = 5,
  int kiransPerDay = 1,
  DateTime? startDate,
  Map<String, List<int>> dailyKirans = const {},
}) {
  return ReadingPlanSchedule(
    startKiran: startKiran,
    kiransPerDay: kiransPerDay,
    startDate: startDate ?? DateTime(2026, 1, 5),
    dailyKirans: dailyKirans,
  );
}

void main() {
  test('extra kirans move the next day to the next unfinished kiran', () {
    final plan = schedule(
      dailyKirans: {
        '2026-01-05': [5, 6, 7],
      },
    );

    final today = plan.assignmentOn(DateTime(2026, 1, 5));
    expect(today.assigned, [5]);
    expect(today.remaining, isEmpty);
    expect(today.extraFinished, [6, 7]);
    expect(today.goalMet, isTrue);

    expect(plan.assignmentOn(DateTime(2026, 1, 6)).assigned, [8]);
  });

  test('a missed day piles onto the next day', () {
    final plan = schedule();
    expect(plan.assignmentOn(DateTime(2026, 1, 6)).assigned, [5, 6]);
  });

  test('two missed days pile three kirans onto the third day', () {
    final plan = schedule();
    expect(plan.assignmentOn(DateTime(2026, 1, 7)).assigned, [5, 6, 7]);
  });

  test('extras cover a later miss until the surplus is used up', () {
    final plan = schedule(
      dailyKirans: {
        '2026-01-05': [5, 6, 7],
      },
    );

    expect(plan.assignmentOn(DateTime(2026, 1, 7)).assigned, [8]);
    expect(plan.assignmentOn(DateTime(2026, 1, 9)).assigned, [8, 9]);
  });

  test('reading a kiran again does not count twice', () {
    final plan = schedule(
      dailyKirans: {
        '2026-01-05': [5],
        '2026-01-06': [5],
      },
    );

    expect(plan.assignmentOn(DateTime(2026, 1, 6)).assigned, [6]);
    final week = plan.weekContaining(
      DateTime(2026, 1, 6),
      today: DateTime(2026, 1, 12),
    );
    expect(week.read, 1);
  });

  test('a full week targets 7 or 14 and succeeds only after Sunday', () {
    final oneADay = schedule();
    final during = oneADay.weekContaining(
      DateTime(2026, 1, 7),
      today: DateTime(2026, 1, 7),
    );
    expect(during.target, 7);
    expect(during.status, WeekStatus.inProgress);

    final twoADay = schedule(kiransPerDay: 2);
    expect(
      twoADay
          .weekContaining(DateTime(2026, 1, 5), today: DateTime(2026, 1, 5))
          .target,
      14,
    );

    final finished = schedule(
      dailyKirans: {
        '2026-01-05': [5, 6, 7, 8, 9, 10, 11],
      },
    );
    final afterSunday = finished.weekContaining(
      DateTime(2026, 1, 5),
      today: DateTime(2026, 1, 12),
    );
    expect(afterSunday.read, 7);
    expect(afterSunday.status, WeekStatus.successful);

    final short = schedule(
      dailyKirans: {
        '2026-01-05': [5, 6, 7, 8],
      },
    );
    expect(
      short
          .weekContaining(DateTime(2026, 1, 5), today: DateTime(2026, 1, 12))
          .status,
      WeekStatus.missed,
    );
  });

  test('a Wednesday start prorates the first week to 5 days', () {
    final plan = schedule(startDate: DateTime(2026, 1, 7));
    final week = plan.weekContaining(
      DateTime(2026, 1, 7),
      today: DateTime(2026, 1, 7),
    );
    expect(week.target, 5);
    expect(week.status, WeekStatus.inProgress);
  });

  test('the plan stops at kiran 697', () {
    final plan = schedule(startKiran: 696, kiransPerDay: 5);
    expect(plan.assignmentOn(DateTime(2026, 1, 5)).assigned, [696, 697]);

    final last = schedule(
      startKiran: 697,
      dailyKirans: {
        '2026-01-05': [697],
      },
    );
    final next = last.assignmentOn(DateTime(2026, 1, 6));
    expect(next.assigned, isEmpty);
    expect(next.planComplete, isTrue);
    expect(next.goalMet, isTrue);
    expect(last.nextUnfinishedOn(DateTime(2026, 1, 6)), isNull);
  });
}
