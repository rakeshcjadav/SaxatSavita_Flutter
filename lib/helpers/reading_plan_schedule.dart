/// Sequential kiran schedule for a reading plan.
///
/// Today's list is fixed from kirans finished before today. Missed days add to
/// that list. Extra kirans finished today do not add a new assignment today;
/// they move the next day forward. A Monday–Sunday week succeeds when the
/// kirans first finished that week reach the week's target.
class ReadingPlanSchedule {
  static const int lastKiran = 697;

  ReadingPlanSchedule({
    required this.startKiran,
    required this.kiransPerDay,
    required DateTime startDate,
    required Map<String, List<int>> dailyKirans,
  }) : startDate = dateOnly(startDate),
       firstFinished = _firstFinished(dailyKirans, startKiran);

  final int startKiran;
  final int kiransPerDay;
  final DateTime startDate;

  /// First calendar day a plan kiran was finished, from [startKiran] through
  /// [lastKiran]. A later reread does not replace this date.
  final Map<int, DateTime> firstFinished;

  bool get isSequential =>
      startKiran >= 1 && startKiran <= lastKiran && kiransPerDay > 0;

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime? parseDateKey(String key) {
    final parts = key.split('-');
    if (parts.length < 3) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day);
  }

  static Map<int, DateTime> _firstFinished(
    Map<String, List<int>> dailyKirans,
    int startKiran,
  ) {
    final result = <int, DateTime>{};
    if (startKiran < 1) return result;
    final entries =
        dailyKirans.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    for (final entry in entries) {
      final date = parseDateKey(entry.key);
      if (date == null) continue;
      for (final kiran in entry.value) {
        if (kiran < startKiran || kiran > lastKiran) continue;
        result.putIfAbsent(kiran, () => date);
      }
    }
    return result;
  }

  DayAssignment assignmentOn(DateTime day) {
    final date = dateOnly(day);
    if (!isSequential || date.isBefore(startDate)) {
      return DayAssignment.empty(date);
    }

    final completedBefore = <int>{
      for (final entry in firstFinished.entries)
        if (entry.value.isBefore(date)) entry.key,
    };
    final completedOnDay = <int>{
      for (final entry in firstFinished.entries)
        if (entry.value == date) entry.key,
    };

    final daysBefore = date.difference(startDate).inDays;
    final backlog = (daysBefore * kiransPerDay - completedBefore.length).clamp(
      0,
      1 << 30,
    );
    final dueCount = kiransPerDay + backlog;

    final assigned = <int>[];
    for (
      var kiran = startKiran;
      kiran <= lastKiran && assigned.length < dueCount;
      kiran++
    ) {
      if (!completedBefore.contains(kiran)) assigned.add(kiran);
    }

    final remaining =
        assigned.where((kiran) => !completedOnDay.contains(kiran)).toList();
    final extraFinished =
        completedOnDay.where((kiran) => !assigned.contains(kiran)).toList()
          ..sort();

    final planComplete = _unfinishedThrough(date) == 0;
    final goalMet = assigned.isEmpty ? planComplete : remaining.isEmpty;

    return DayAssignment(
      date: date,
      assigned: assigned,
      remaining: remaining,
      extraFinished: extraFinished,
      backlog: backlog,
      goalMet: goalMet,
      planComplete: planComplete,
    );
  }

  /// Next plan kiran not finished on or before [day].
  int? nextUnfinishedOn(DateTime day) {
    if (!isSequential) return null;
    final date = dateOnly(day);
    for (var kiran = startKiran; kiran <= lastKiran; kiran++) {
      final finished = firstFinished[kiran];
      if (finished == null || finished.isAfter(date)) return kiran;
    }
    return null;
  }

  WeekProgress weekContaining(DateTime day, {required DateTime today}) {
    final date = dateOnly(day);
    final now = dateOnly(today);
    final weekStart = date.subtract(
      Duration(days: date.weekday - DateTime.monday),
    );
    final weekEnd = weekStart.add(const Duration(days: 6));

    var target = 0;
    if (isSequential && !startDate.isAfter(weekEnd)) {
      final activeStart = startDate.isAfter(weekStart) ? startDate : weekStart;
      final unfinished = _unfinishedBefore(activeStart);
      final days = weekEnd.difference(activeStart).inDays + 1;
      target = days * kiransPerDay;
      if (unfinished < target) target = unfinished;
    }

    var read = 0;
    for (final finished in firstFinished.values) {
      if (!finished.isBefore(weekStart) && !finished.isAfter(weekEnd)) {
        read++;
      }
    }

    final WeekStatus status;
    if (target == 0 || now.isBefore(weekStart)) {
      status = WeekStatus.inactive;
    } else if (!now.isAfter(weekEnd)) {
      status = WeekStatus.inProgress;
    } else if (read >= target) {
      status = WeekStatus.successful;
    } else {
      status = WeekStatus.missed;
    }

    return WeekProgress(
      weekStart: weekStart,
      weekEnd: weekEnd,
      target: target,
      read: read,
      status: status,
    );
  }

  /// Current week first, then older weeks that had a target.
  List<WeekProgress> recentWeeks(DateTime today, {int count = 8}) {
    final now = dateOnly(today);
    final thisMonday = now.subtract(
      Duration(days: now.weekday - DateTime.monday),
    );
    final weeks = <WeekProgress>[];
    for (var i = 0; i < count; i++) {
      final monday = thisMonday.subtract(Duration(days: 7 * i));
      final week = weekContaining(monday, today: now);
      if (week.target > 0) weeks.add(week);
    }
    return weeks;
  }

  /// Consecutive days, ending today or yesterday, whose assignment was finished.
  int streakEnding(DateTime today) {
    if (!isSequential) return 0;
    final start = dateOnly(today);
    var streak = 0;
    for (var i = 0; i < 366; i++) {
      final day = start.subtract(Duration(days: i));
      if (day.isBefore(startDate)) break;
      final assignment = assignmentOn(day);
      final counted = assignment.assigned.isNotEmpty && assignment.goalMet;
      if (counted) {
        streak++;
      } else if (i == 0) {
        continue;
      } else {
        break;
      }
    }
    return streak;
  }

  int _unfinishedBefore(DateTime date) {
    var count = 0;
    for (var kiran = startKiran; kiran <= lastKiran; kiran++) {
      final finished = firstFinished[kiran];
      if (finished == null || !finished.isBefore(date)) count++;
    }
    return count;
  }

  int _unfinishedThrough(DateTime date) {
    var count = 0;
    for (var kiran = startKiran; kiran <= lastKiran; kiran++) {
      final finished = firstFinished[kiran];
      if (finished == null || finished.isAfter(date)) count++;
    }
    return count;
  }
}

class DayAssignment {
  const DayAssignment({
    required this.date,
    required this.assigned,
    required this.remaining,
    required this.extraFinished,
    required this.backlog,
    required this.goalMet,
    required this.planComplete,
  });

  final DateTime date;
  final List<int> assigned;
  final List<int> remaining;
  final List<int> extraFinished;
  final int backlog;
  final bool goalMet;
  final bool planComplete;

  factory DayAssignment.empty(DateTime date) {
    return DayAssignment(
      date: ReadingPlanSchedule.dateOnly(date),
      assigned: const [],
      remaining: const [],
      extraFinished: const [],
      backlog: 0,
      goalMet: false,
      planComplete: false,
    );
  }

  double get progress {
    if (assigned.isEmpty) return planComplete ? 1 : 0;
    final done = assigned.length - remaining.length;
    return (done / assigned.length).clamp(0.0, 1.0);
  }
}

enum WeekStatus { inactive, inProgress, successful, missed }

class WeekProgress {
  const WeekProgress({
    required this.weekStart,
    required this.weekEnd,
    required this.target,
    required this.read,
    required this.status,
  });

  final DateTime weekStart;
  final DateTime weekEnd;
  final int target;
  final int read;
  final WeekStatus status;

  bool get succeeded => status == WeekStatus.successful;
}
