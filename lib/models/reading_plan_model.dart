class ReadingPlan {
  final String id;
  final String title;
  final String description;
  final ReadingPlanType type;
  final int targetSeconds; // Daily reading goal in seconds
  final int targetKirans; // Daily kiran reading goal
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final List<ReminderTime> reminderTimes; // Reminder times with hour and minute
  final Map<String, int> dailyProgress; // Date -> minutes read
  final Map<String, List<int>>
  dailyKirans; // Date -> list of kiran indices read
  final DateTime createdAt;
  final DateTime updatedAt;

  ReadingPlan({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.targetSeconds,
    required this.targetKirans,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.reminderTimes = const [
      ReminderTime(hour: 9, minute: 0), // 9:00 AM
      ReminderTime(hour: 18, minute: 0), // 6:00 PM
    ],
    this.dailyProgress = const {},
    this.dailyKirans = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  factory ReadingPlan.fromJson(Map<String, dynamic> json) {
    return ReadingPlan(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: ReadingPlanType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReadingPlanType.custom,
      ),
      targetSeconds: json['targetSeconds'] ?? 15 * 60,
      targetKirans: json['targetKirans'] ?? 1,
      startDate: DateTime.parse(json['startDate']),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isActive: json['isActive'] ?? true,
      reminderTimes:
          (json['reminderTimes'] as List?)?.map((item) {
            if (item is Map<String, dynamic>) {
              return ReminderTime.fromJson(item);
            } else if (item is int) {
              // Backwards compatibility: treat as hour with 0 minutes
              return ReminderTime(hour: item, minute: 0);
            }
            return const ReminderTime(hour: 9, minute: 0);
          }).toList() ??
          [
            const ReminderTime(hour: 9, minute: 0),
            const ReminderTime(hour: 18, minute: 0),
          ],
      dailyProgress: Map<String, int>.from(json['dailyProgress'] ?? {}),
      dailyKirans: Map<String, List<int>>.from(
        (json['dailyKirans'] ?? {}).map(
          (key, value) => MapEntry(key, List<int>.from(value ?? [])),
        ),
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type.name,
      'targetSeconds': targetSeconds,
      'targetKirans': targetKirans,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'reminderTimes': reminderTimes.map((rt) => rt.toJson()).toList(),
      'dailyProgress': dailyProgress,
      'dailyKirans': dailyKirans.map((key, value) => MapEntry(key, value)),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  ReadingPlan copyWith({
    String? id,
    String? title,
    String? description,
    ReadingPlanType? type,
    int? targetSeconds,
    int? targetKirans,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    List<ReminderTime>? reminderTimes,
    Map<String, int>? dailyProgress,
    Map<String, List<int>>? dailyKirans,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ReadingPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      targetSeconds: targetSeconds ?? this.targetSeconds,
      targetKirans: targetKirans ?? this.targetKirans,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      dailyProgress: dailyProgress ?? this.dailyProgress,
      dailyKirans: dailyKirans ?? this.dailyKirans,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Helper methods
  String get todayKey => DateTime.now().toIso8601String().split('T').first;

  int get todayProgress => dailyProgress[todayKey] ?? 0;
  List<int> get todayKirans => dailyKirans[todayKey] ?? [];

  bool get todayGoalAchieved =>
      todayProgress >= targetSeconds && todayKirans.length >= targetKirans;

  double get todayProgressPercentage {
    final secondsProgress =
        targetSeconds > 0 ? (todayProgress / targetSeconds) : 0.0;
    final kiransProgress =
        targetKirans > 0 ? (todayKirans.length / targetKirans) : 0.0;
    return ((secondsProgress + kiransProgress) / 2).clamp(0.0, 1.0);
  }

  int get streakDays {
    int streak = 0;
    final today = DateTime.now();

    for (int i = 0; i < 365; i++) {
      final checkDate = today.subtract(Duration(days: i));
      final dateKey = checkDate.toIso8601String().split('T').first;

      final dayProgress = dailyProgress[dateKey] ?? 0;
      final dayKirans = dailyKirans[dateKey] ?? [];

      if (dayProgress >= targetSeconds && dayKirans.length >= targetKirans) {
        streak++;
      } else if (i > 0) {
        break; // Streak broken
      } else {
        // Today hasn't achieved goal yet, check yesterday
        continue;
      }
    }

    return streak;
  }

  @override
  String toString() {
    int targetMinutes = (targetSeconds ~/ 60);
    return 'ReadingPlan{id: $id, title: $title, targetMinutes: $targetMinutes, targetKirans: $targetKirans}';
  }
}

enum ReadingPlanType {
  daily15min('Daily 15 Minutes'),
  daily30min('Daily 30 Minutes'),
  daily1hour('Daily 1 Hour'),
  weekly('Weekly Goal'),
  monthly('Monthly Challenge'),
  custom('Custom Plan');

  const ReadingPlanType(this.displayName);
  final String displayName;
}

class ReminderTime {
  final int hour; // 0-23
  final int minute; // 0-59

  const ReminderTime({required this.hour, required this.minute});

  factory ReminderTime.fromJson(Map<String, dynamic> json) {
    return ReminderTime(hour: json['hour'] ?? 0, minute: json['minute'] ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'hour': hour, 'minute': minute};
  }

  String format24Hour() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String format12Hour() {
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  @override
  String toString() => format24Hour();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReminderTime &&
        other.hour == hour &&
        other.minute == minute;
  }

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode;
}

class ReadingPlanProgress {
  final String date;
  final int secondsRead;
  final List<int> kiransRead;
  final bool goalAchieved;

  ReadingPlanProgress({
    required this.date,
    required this.secondsRead,
    required this.kiransRead,
    required this.goalAchieved,
  });

  factory ReadingPlanProgress.fromJson(Map<String, dynamic> json) {
    return ReadingPlanProgress(
      date: json['date'] ?? '',
      secondsRead: json['secondsRead'] ?? 0,
      kiransRead: List<int>.from(json['kiransRead'] ?? []),
      goalAchieved: json['goalAchieved'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'secondsRead': secondsRead,
      'kiransRead': kiransRead,
      'goalAchieved': goalAchieved,
    };
  }
}
