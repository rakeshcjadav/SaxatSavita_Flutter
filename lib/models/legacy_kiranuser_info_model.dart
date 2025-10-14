import 'package:cloud_firestore/cloud_firestore.dart';

/// Legacy KiranUserInfo model for migrating old Firebase data
/// This represents the old data structure from Firebase collections
class LegacyKiranUserInfo {
  final int favourite;
  final int kiranIndex;
  final int listIndex;
  final String note;
  final int partNumber;
  final int progress;
  final int readCount;
  final DateTime updatedAt;
  final String? documentId; // Firebase document ID

  LegacyKiranUserInfo({
    required this.favourite,
    required this.kiranIndex,
    required this.listIndex,
    required this.note,
    required this.partNumber,
    required this.progress,
    required this.readCount,
    required this.updatedAt,
    this.documentId,
  });

  /// Create from Firebase document
  factory LegacyKiranUserInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return LegacyKiranUserInfo(
      favourite: data['favourite'] ?? 0,
      kiranIndex: data['kiranIndex'] ?? 0, // Note: lowercase 'i' in Firebase
      listIndex: data['listIndex'] ?? 0,
      note: data['note'] ?? '',
      partNumber: data['partNumber'] ?? 1,
      progress: data['progress'] ?? 0,
      readCount: data['readCount'] ?? 0,
      updatedAt: _parseDateTime(data['updatedAt']),
      documentId: doc.id,
    );
  }

  /// Create from Map (for JSON parsing)
  factory LegacyKiranUserInfo.fromMap(
    Map<String, dynamic> map, {
    String? docId,
  }) {
    return LegacyKiranUserInfo(
      favourite: map['favourite'] ?? 0,
      kiranIndex:
          map['kiranIndex'] ?? map['kiranIndex'] ?? 0, // Handle both cases
      listIndex: map['listIndex'] ?? 0,
      note: map['note'] ?? '',
      partNumber: map['partNumber'] ?? 1,
      progress: map['progress'] ?? 0,
      readCount: map['readCount'] ?? 0,
      updatedAt: _parseDateTime(map['updatedAt']),
      documentId: docId,
    );
  }

  /// Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'favourite': favourite,
      'kiranIndex': kiranIndex, // Keep original format for compatibility
      'listIndex': listIndex,
      'note': note,
      'partNumber': partNumber,
      'progress': progress,
      'readCount': readCount,
      'updatedAt': Timestamp.fromDate(updatedAt),
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

  /// Check if this Kiran is marked as favourite
  bool get isFavourite => favourite > 0;

  /// Check if this Kiran has been read (has progress > 0 or readCount > 0)
  bool get hasBeenRead => progress > 0 || readCount > 0;

  /// Check if this Kiran has a note
  bool get hasNote => note.trim().isNotEmpty;

  /// Check if this Kiran is completed (progress >= 100)
  bool get isCompleted => progress >= 100;

  /// Get the part name for display
  String get partName => 'Part $partNumber';

  /// Get unique identifier for this Kiran
  String get uniqueId => 'part$partNumber-kiran$kiranIndex';

  /// Convert to current KiranUserInfo format for migration
  Map<String, dynamic> toCurrentFormat() {
    return {
      'partNumber': partNumber,
      'kiranIndex': kiranIndex,
      'listIndex': listIndex,
      'progress': progress,
      'updatedAt': updatedAt,
      'isFavourite': favourite, // Keep as int for compatibility
      'readCount': readCount,
      'note': note,
      // Add any additional fields needed for current format
      'lastReadDate':
          updatedAt.toIso8601String().split('T')[0], // YYYY-MM-DD format
      'isBookmarked': isFavourite ? 1 : 0,
    };
  }

  @override
  String toString() {
    return 'LegacyKiranUserInfo(documentId: $documentId, part: $partNumber, '
        'kiran: $kiranIndex, progress: $progress%, favourite: $isFavourite, '
        'readCount: $readCount, hasNote: $hasNote, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LegacyKiranUserInfo &&
        other.kiranIndex == kiranIndex &&
        other.partNumber == partNumber &&
        other.listIndex == listIndex &&
        other.favourite == favourite &&
        other.progress == progress &&
        other.readCount == readCount &&
        other.note == note;
  }

  @override
  int get hashCode {
    return kiranIndex.hashCode ^
        partNumber.hashCode ^
        listIndex.hashCode ^
        favourite.hashCode ^
        progress.hashCode ^
        readCount.hashCode ^
        note.hashCode;
  }
}

/// Statistics helper for legacy KiranUserInfo data
class LegacyKiranUserInfoStats {
  final List<LegacyKiranUserInfo> entries;

  LegacyKiranUserInfoStats(this.entries);

  /// Total number of Kirans
  int get totalKirans => entries.length;

  /// Number of favourite Kirans
  int get favouriteKirans => entries.where((entry) => entry.isFavourite).length;

  /// Number of Kirans with progress
  int get kiransWithProgress =>
      entries.where((entry) => entry.hasBeenRead).length;

  /// Number of completed Kirans
  int get completedKirans => entries.where((entry) => entry.isCompleted).length;

  /// Number of Kirans with notes
  int get kiransWithNotes => entries.where((entry) => entry.hasNote).length;

  /// Total read count across all Kirans
  int get totalReadCount =>
      entries.fold(0, (sum, entry) => sum + entry.readCount);

  /// Average progress across all Kirans
  double get averageProgress {
    if (entries.isEmpty) return 0.0;
    final totalProgress = entries.fold(0, (sum, entry) => sum + entry.progress);
    return totalProgress / entries.length;
  }

  /// Get entries grouped by part number
  Map<int, List<LegacyKiranUserInfo>> get entriesByPart {
    final Map<int, List<LegacyKiranUserInfo>> grouped = {};
    for (final entry in entries) {
      grouped.putIfAbsent(entry.partNumber, () => []).add(entry);
    }
    return grouped;
  }

  /// Get entries grouped by favourite status
  Map<bool, List<LegacyKiranUserInfo>> get entriesByFavourite {
    final Map<bool, List<LegacyKiranUserInfo>> grouped = {true: [], false: []};

    for (final entry in entries) {
      grouped[entry.isFavourite]!.add(entry);
    }

    return grouped;
  }

  /// Get entries with progress in a specific range
  List<LegacyKiranUserInfo> getEntriesWithProgressRange(
    int minProgress,
    int maxProgress,
  ) {
    return entries.where((entry) {
      return entry.progress >= minProgress && entry.progress <= maxProgress;
    }).toList();
  }

  /// Get recently updated entries (within specified days)
  List<LegacyKiranUserInfo> getRecentlyUpdated({int days = 30}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return entries.where((entry) {
      return entry.updatedAt.isAfter(cutoffDate);
    }).toList();
  }

  /// Get summary statistics
  Map<String, dynamic> getSummary() {
    return {
      'totalKirans': totalKirans,
      'favouriteKirans': favouriteKirans,
      'kiransWithProgress': kiransWithProgress,
      'completedKirans': completedKirans,
      'kiransWithNotes': kiransWithNotes,
      'totalReadCount': totalReadCount,
      'averageProgress': averageProgress.round(),
      'completionRate':
          totalKirans > 0 ? (completedKirans / totalKirans * 100).round() : 0,
    };
  }
}
