import 'package:cloud_firestore/cloud_firestore.dart';

/// Legacy reading history model for migrating old Firebase data
/// This represents the old data structure from Firebase collections
class LegacyReadingHistory {
  final String category;
  final DateTime createdAt;
  final int durationSeconds;
  final int historyIndex;
  final int kiranIndex;
  final int partNumber;
  final String? documentId; // Firebase document ID

  LegacyReadingHistory({
    required this.category,
    required this.createdAt,
    required this.durationSeconds,
    required this.historyIndex,
    required this.kiranIndex,
    required this.partNumber,
    this.documentId,
  });

  /// Create from Firebase document
  factory LegacyReadingHistory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return LegacyReadingHistory(
      category: data['category'] ?? 'KIRAN_READ',
      createdAt: _parseDateTime(data['createdAt']),
      durationSeconds: data['durationSeconds'] ?? 0,
      historyIndex: data['historyIndex'] ?? 0,
      kiranIndex: data['kiranIndex'] ?? 0,
      partNumber: data['partNumber'] ?? 1,
      documentId: doc.id,
    );
  }

  /// Create from Map (for JSON parsing)
  factory LegacyReadingHistory.fromMap(Map<String, dynamic> map, {String? docId}) {
    return LegacyReadingHistory(
      category: map['category'] ?? 'KIRAN_READ',
      createdAt: _parseDateTime(map['createdAt']),
      durationSeconds: map['durationSeconds'] ?? 0,
      historyIndex: map['historyIndex'] ?? 0,
      kiranIndex: map['kiranIndex'] ?? 0,
      partNumber: map['partNumber'] ?? 1,
      documentId: docId,
    );
  }

  /// Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'durationSeconds': durationSeconds,
      'historyIndex': historyIndex,
      'kiranIndex': kiranIndex,
      'partNumber': partNumber,
    };
  }

  /// Helper method to parse different datetime formats from Firebase
  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    
    if (dateValue is Timestamp) {
      return dateValue.toDate();
    } else if (dateValue is DateTime) {
      return dateValue;
    } else if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    } else if (dateValue is int) {
      // Assume it's milliseconds since epoch
      return DateTime.fromMillisecondsSinceEpoch(dateValue);
    }
    
    return DateTime.now();
  }

  /// Check if this is a valid reading session (has meaningful duration)
  bool get isValidSession => durationSeconds > 0;

  /// Get reading duration in a human-readable format
  String get formattedDuration {
    if (durationSeconds < 60) {
      return '${durationSeconds}s';
    } else if (durationSeconds < 3600) {
      final minutes = durationSeconds ~/ 60;
      final seconds = durationSeconds % 60;
      return '${minutes}m ${seconds}s';
    } else {
      final hours = durationSeconds ~/ 3600;
      final minutes = (durationSeconds % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
  }

  /// Get the part name for display
  String get partName => 'Part $partNumber';

  /// Convert to current ReadingHistoryEntry format for migration
  Map<String, dynamic> toCurrentFormat() {
    return {
      'timestamp': createdAt.millisecondsSinceEpoch,
      'partNumber': partNumber,
      'kiranIndex': kiranIndex,
      'durationSeconds': durationSeconds,
      'category': category,
      // Add any additional fields needed for current format
      'readingDate': createdAt.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'progress': 100, // Assume completed if in history
    };
  }

  @override
  String toString() {
    return 'LegacyReadingHistory(documentId: $documentId, category: $category, '
        'createdAt: $createdAt, duration: ${formattedDuration}, '
        'part: $partNumber, kiran: $kiranIndex, historyIndex: $historyIndex)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LegacyReadingHistory &&
        other.category == category &&
        other.createdAt == createdAt &&
        other.durationSeconds == durationSeconds &&
        other.historyIndex == historyIndex &&
        other.kiranIndex == kiranIndex &&
        other.partNumber == partNumber;
  }

  @override
  int get hashCode {
    return category.hashCode ^
        createdAt.hashCode ^
        durationSeconds.hashCode ^
        historyIndex.hashCode ^
        kiranIndex.hashCode ^
        partNumber.hashCode;
  }
}

/// Statistics helper for legacy reading history
class LegacyReadingHistoryStats {
  final List<LegacyReadingHistory> entries;

  LegacyReadingHistoryStats(this.entries);

  /// Total reading time in seconds
  int get totalReadingTime => entries.fold(0, (sum, entry) => sum + entry.durationSeconds);

  /// Total number of sessions
  int get totalSessions => entries.length;

  /// Number of valid sessions (with duration > 0)
  int get validSessions => entries.where((entry) => entry.isValidSession).length;

  /// Number of unique kirans read
  int get uniqueKiransRead {
    final uniqueKirans = <String>{};
    for (final entry in entries) {
      uniqueKirans.add('${entry.partNumber}-${entry.kiranIndex}');
    }
    return uniqueKirans.length;
  }

  /// Get entries grouped by part number
  Map<int, List<LegacyReadingHistory>> get entriesByPart {
    final Map<int, List<LegacyReadingHistory>> grouped = {};
    for (final entry in entries) {
      grouped.putIfAbsent(entry.partNumber, () => []).add(entry);
    }
    return grouped;
  }

  /// Get entries for a specific date range
  List<LegacyReadingHistory> getEntriesInDateRange(DateTime start, DateTime end) {
    return entries.where((entry) {
      return entry.createdAt.isAfter(start) && entry.createdAt.isBefore(end);
    }).toList();
  }

  /// Get formatted total reading time
  String get formattedTotalTime {
    if (totalReadingTime < 60) {
      return '${totalReadingTime}s';
    } else if (totalReadingTime < 3600) {
      final minutes = totalReadingTime ~/ 60;
      final seconds = totalReadingTime % 60;
      return '${minutes}m ${seconds}s';
    } else {
      final hours = totalReadingTime ~/ 3600;
      final minutes = (totalReadingTime % 3600) ~/ 60;
      return '${hours}h ${minutes}m';
    }
  }
}