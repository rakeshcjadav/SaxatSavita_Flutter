class ReadingHistory {
  final String category;
  final int durationSeconds;
  final int kiranIndex;
  final int partNumber;
  final DateTime createdAt;

  ReadingHistory({
    required this.category,
    required this.durationSeconds,
    required this.kiranIndex,
    required this.partNumber,
    required this.createdAt,
  });

  factory ReadingHistory.fromJson(Map<String, dynamic> json) {
    return ReadingHistory(
      category: json['category'] ?? '',
      durationSeconds: json['durationSeconds'] ?? 0,
      kiranIndex: json['kiranIndex'] ?? 0,
      partNumber: json['partNumber'] ?? 0,
      createdAt:
          json['createdAt'] != null
              ? DateTime.parse(json['createdAt'])
              : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'durationSeconds': durationSeconds,
      'kiranIndex': kiranIndex,
      'partNumber': partNumber,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Helper methods for formatting duration
  String get formattedDuration {
    final duration = Duration(seconds: durationSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  // Helper method for getting readable duration
  String get readableDuration {
    final duration = Duration(seconds: durationSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    } else if (minutes > 0) {
      return seconds > 0 ? '${minutes}m ${seconds}s' : '${minutes}m';
    } else {
      return '${seconds}s';
    }
  }

  // Helper method for getting formatted date
  String get formattedDate {
    final now = DateTime.now();

    // Convert both dates to local date only (ignore time) for proper comparison
    final nowDate = DateTime(now.year, now.month, now.day);
    final createdDate = DateTime(
      createdAt.year,
      createdAt.month,
      createdAt.day,
    );

    final difference = nowDate.difference(createdDate).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else {
      return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
    }
  }

  @override
  String toString() {
    return 'ReadingHistory(category: $category, duration: $formattedDuration, kiranIndex: $kiranIndex, partNumber: $partNumber, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ReadingHistory &&
        other.category == category &&
        other.durationSeconds == durationSeconds &&
        other.kiranIndex == kiranIndex &&
        other.partNumber == partNumber &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return category.hashCode ^
        durationSeconds.hashCode ^
        kiranIndex.hashCode ^
        partNumber.hashCode ^
        createdAt.hashCode;
  }
}
