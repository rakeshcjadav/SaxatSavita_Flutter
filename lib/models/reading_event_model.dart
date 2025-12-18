import 'package:cloud_firestore/cloud_firestore.dart';

/// Enum to represent the reading mode
enum ReadingMode {
  reading, // Progress tracking enabled
  browse, // No tracking, casual browsing
}

/// Model for an active reading session (in-progress)
/// Gets converted to ReadingHistory upon completion
class ReadingEvent {
  final String id; // Unique identifier
  final int kiranIndex;
  final int partNumber;
  final DateTime startedAt;
  int currentProgress; // 0-100
  int durationSeconds; // Time spent so far
  final bool isPaused;
  final double? lastScrollPosition; // Optional: track where user left off
  final String deviceId; // To handle multi-device scenarios
  DateTime lastUpdatedAt;
  final String category; // Morning/Afternoon/Evening/Night Reading

  ReadingEvent({
    required this.id,
    required this.kiranIndex,
    required this.partNumber,
    required this.startedAt,
    this.currentProgress = 0,
    this.durationSeconds = 0,
    this.isPaused = false,
    this.lastScrollPosition,
    required this.deviceId,
    required this.lastUpdatedAt,
    required this.category,
  });

  /// Create a new reading event with generated ID
  factory ReadingEvent.create({
    required int kiranIndex,
    required int partNumber,
    required String deviceId,
    required String category,
  }) {
    final now = DateTime.now();
    return ReadingEvent(
      id: '${deviceId}_${kiranIndex}_${now.millisecondsSinceEpoch}',
      kiranIndex: kiranIndex,
      partNumber: partNumber,
      startedAt: now,
      deviceId: deviceId,
      lastUpdatedAt: now,
      category: category,
    );
  }

  /// Create a copy with updated values
  ReadingEvent copyWith({
    String? id,
    int? kiranIndex,
    int? partNumber,
    DateTime? startedAt,
    int? currentProgress,
    int? durationSeconds,
    bool? isPaused,
    double? lastScrollPosition,
    String? deviceId,
    DateTime? lastUpdatedAt,
    String? category,
  }) {
    return ReadingEvent(
      id: id ?? this.id,
      kiranIndex: kiranIndex ?? this.kiranIndex,
      partNumber: partNumber ?? this.partNumber,
      startedAt: startedAt ?? this.startedAt,
      currentProgress: currentProgress ?? this.currentProgress,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      isPaused: isPaused ?? this.isPaused,
      lastScrollPosition: lastScrollPosition ?? this.lastScrollPosition,
      deviceId: deviceId ?? this.deviceId,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
      category: category ?? this.category,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kiranIndex': kiranIndex,
      'partNumber': partNumber,
      'startedAt': startedAt.toIso8601String(),
      'currentProgress': currentProgress,
      'durationSeconds': durationSeconds,
      'isPaused': isPaused,
      'lastScrollPosition': lastScrollPosition,
      'deviceId': deviceId,
      'lastUpdatedAt': lastUpdatedAt.toIso8601String(),
      'category': category,
    };
  }

  /// Create from JSON
  factory ReadingEvent.fromJson(Map<String, dynamic> json) {
    return ReadingEvent(
      id: json['id'] as String,
      kiranIndex: json['kiranIndex'] as int,
      partNumber: json['partNumber'] as int,
      startedAt: DateTime.parse(json['startedAt'] as String),
      currentProgress: json['currentProgress'] as int? ?? 0,
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      isPaused: json['isPaused'] as bool? ?? false,
      lastScrollPosition: json['lastScrollPosition'] as double?,
      deviceId: json['deviceId'] as String,
      lastUpdatedAt: DateTime.parse(json['lastUpdatedAt'] as String),
      category: json['category'] as String,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'id': id,
      'kiranIndex': kiranIndex,
      'partNumber': partNumber,
      'startedAt': Timestamp.fromDate(startedAt),
      'currentProgress': currentProgress,
      'durationSeconds': durationSeconds,
      'isPaused': isPaused,
      'lastScrollPosition': lastScrollPosition,
      'deviceId': deviceId,
      'lastUpdatedAt': Timestamp.fromDate(lastUpdatedAt),
      'category': category,
    };
  }

  /// Create from Firestore document
  factory ReadingEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReadingEvent(
      id: data['id'] as String,
      kiranIndex: data['kiranIndex'] as int,
      partNumber: data['partNumber'] as int,
      startedAt: (data['startedAt'] as Timestamp).toDate(),
      currentProgress: data['currentProgress'] as int? ?? 0,
      durationSeconds: data['durationSeconds'] as int? ?? 0,
      isPaused: data['isPaused'] as bool? ?? false,
      lastScrollPosition: data['lastScrollPosition'] as double?,
      deviceId: data['deviceId'] as String,
      lastUpdatedAt: (data['lastUpdatedAt'] as Timestamp).toDate(),
      category: data['category'] as String,
    );
  }

  /// Get formatted duration
  String get formattedDuration {
    final duration = Duration(seconds: durationSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Get formatted time ago
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(lastUpdatedAt);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  /// Check if event is stale (older than 7 days)
  bool get isStale {
    final now = DateTime.now();
    final difference = now.difference(lastUpdatedAt);
    return difference.inDays > 7;
  }

  @override
  String toString() {
    return 'ReadingEvent(id: $id, kiranIndex: $kiranIndex, progress: $currentProgress%, duration: $formattedDuration, isPaused: $isPaused)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ReadingEvent && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
