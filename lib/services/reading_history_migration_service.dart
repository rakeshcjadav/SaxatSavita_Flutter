import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:saxatsavita_flutter/models/legacy_reading_history_model.dart';
import 'package:saxatsavita_flutter/models/reading_history_model.dart';
import 'package:saxatsavita_flutter/services/reading_history_service.dart';

/// Service to migrate legacy reading history data to the current format
class ReadingHistoryMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if user has legacy data that needs migration
  Future<bool> hasLegacyData(String userId) async {
    try {
      final legacyCollection = _firestore
          .collection('users')
          .doc(userId)
          .collection('reading_history');

      final snapshot = await legacyCollection.limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking for legacy data: $e');
      return false;
    }
  }

  /// Get all legacy reading history for a user
  Future<List<LegacyReadingHistory>> getLegacyReadingHistory(
    String userId,
  ) async {
    try {
      final legacyCollection = _firestore
          .collection('users')
          .doc(userId)
          .collection('reading_history');

      final snapshot = await legacyCollection.orderBy('createdAt').get();

      return snapshot.docs.map((doc) {
        return LegacyReadingHistory.fromFirestore(doc);
      }).toList();
    } catch (e) {
      debugPrint('Error fetching legacy reading history: $e');
      return [];
    }
  }

  /// Migrate legacy data to current format
  Future<MigrationResult> migrateLegacyData(
    String userId, {
    bool deleteAfterMigration = false,
    Function(int current, int total)? onProgress,
  }) async {
    try {
      // Get all legacy data
      final legacyEntries = await getLegacyReadingHistory(userId);

      if (legacyEntries.isEmpty) {
        return MigrationResult(
          success: true,
          migratedCount: 0,
          skippedCount: 0,
          errorCount: 0,
          message: 'No legacy data found to migrate.',
        );
      }

      int migratedCount = 0;
      int skippedCount = 0;
      int errorCount = 0;
      final List<String> errors = [];

      // Process each legacy entry
      for (int i = 0; i < legacyEntries.length; i++) {
        final legacyEntry = legacyEntries[i];

        try {
          // Convert to current format
          final currentEntry = ReadingHistory(
            category: legacyEntry.category,
            partNumber: legacyEntry.partNumber,
            kiranIndex: legacyEntry.kiranIndex,
            durationSeconds: legacyEntry.durationSeconds,
            createdAt: legacyEntry.createdAt,
          );

          // Check if entry already exists (avoid duplicates)
          final existingEntries =
              await ReadingHistoryService.loadReadingHistory();
          final isDuplicate = existingEntries.any((entry) {
            return entry.createdAt == currentEntry.createdAt &&
                entry.partNumber == currentEntry.partNumber &&
                entry.kiranIndex == currentEntry.kiranIndex;
          });

          if (isDuplicate) {
            debugPrint('Skipping duplicate entry: ${legacyEntry.toString()}');
            skippedCount++;
          } else {
            // Add to current reading history
            await ReadingHistoryService.saveReadingHistory(currentEntry);
            migratedCount++;
            debugPrint('Migrated entry: ${legacyEntry.toString()}');
          }

          // Report progress
          onProgress?.call(i + 1, legacyEntries.length);
        } catch (e) {
          errorCount++;
          final errorMsg =
              'Failed to migrate entry ${legacyEntry.documentId}: $e';
          errors.add(errorMsg);
          debugPrint(errorMsg);
        }
      }

      // Optionally delete legacy data after successful migration
      if (deleteAfterMigration && errorCount == 0) {
        await _deleteLegacyData(userId);
      }

      return MigrationResult(
        success: errorCount == 0,
        migratedCount: migratedCount,
        skippedCount: skippedCount,
        errorCount: errorCount,
        message: _buildMigrationMessage(
          migratedCount,
          skippedCount,
          errorCount,
        ),
        errors: errors,
      );
    } catch (e) {
      debugPrint('Migration failed: $e');
      return MigrationResult(
        success: false,
        migratedCount: 0,
        skippedCount: 0,
        errorCount: 1,
        message: 'Migration failed: $e',
        errors: [e.toString()],
      );
    }
  }

  /// Delete all legacy data for a user
  Future<void> _deleteLegacyData(String userId) async {
    try {
      final legacyCollection = _firestore
          .collection('users')
          .doc(userId)
          .collection('reading_history');

      final snapshot = await legacyCollection.get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint(
        'Deleted ${snapshot.docs.length} legacy reading history entries',
      );
    } catch (e) {
      debugPrint('Error deleting legacy data: $e');
      rethrow;
    }
  }

  /// Get migration preview without actually migrating
  Future<MigrationPreview> getMigrationPreview(String userId) async {
    try {
      final legacyEntries = await getLegacyReadingHistory(userId);
      final currentEntries = await ReadingHistoryService.loadReadingHistory();

      int duplicatesFound = 0;
      int newEntries = 0;

      for (final legacyEntry in legacyEntries) {
        final isDuplicate = currentEntries.any((entry) {
          return entry.createdAt == legacyEntry.createdAt &&
              entry.partNumber == legacyEntry.partNumber &&
              entry.kiranIndex == legacyEntry.kiranIndex;
        });

        if (isDuplicate) {
          duplicatesFound++;
        } else {
          newEntries++;
        }
      }

      final stats = LegacyReadingHistoryStats(legacyEntries);

      return MigrationPreview(
        totalLegacyEntries: legacyEntries.length,
        duplicatesFound: duplicatesFound,
        newEntriesToMigrate: newEntries,
        totalReadingTime: stats.formattedTotalTime,
        uniqueKiransRead: stats.uniqueKiransRead,
        dateRange:
            legacyEntries.isNotEmpty
                ? DateRange(
                  start: legacyEntries.first.createdAt,
                  end: legacyEntries.last.createdAt,
                )
                : null,
      );
    } catch (e) {
      debugPrint('Error creating migration preview: $e');
      return MigrationPreview(
        totalLegacyEntries: 0,
        duplicatesFound: 0,
        newEntriesToMigrate: 0,
        totalReadingTime: '0s',
        uniqueKiransRead: 0,
      );
    }
  }

  /// Auto-migrate for current user (if logged in)
  Future<MigrationResult> autoMigrateCurrentUser({
    Function(int current, int total)? onProgress,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return MigrationResult(
        success: false,
        migratedCount: 0,
        skippedCount: 0,
        errorCount: 1,
        message: 'No user logged in',
      );
    }

    return await migrateLegacyData(user.uid, onProgress: onProgress);
  }

  /// Helper methods

  String _buildMigrationMessage(int migrated, int skipped, int errors) {
    if (errors > 0) {
      return 'Migration completed with errors: $migrated migrated, $skipped skipped, $errors failed';
    } else if (skipped > 0) {
      return 'Migration successful: $migrated new entries migrated, $skipped duplicates skipped';
    } else {
      return 'Migration successful: $migrated entries migrated';
    }
  }
}

/// Result of a migration operation
class MigrationResult {
  final bool success;
  final int migratedCount;
  final int skippedCount;
  final int errorCount;
  final String message;
  final List<String> errors;

  MigrationResult({
    required this.success,
    required this.migratedCount,
    required this.skippedCount,
    required this.errorCount,
    required this.message,
    this.errors = const [],
  });

  bool get hasErrors => errorCount > 0;
  bool get hasSkipped => skippedCount > 0;
  int get totalProcessed => migratedCount + skippedCount + errorCount;
}

/// Preview of migration before executing
class MigrationPreview {
  final int totalLegacyEntries;
  final int duplicatesFound;
  final int newEntriesToMigrate;
  final String totalReadingTime;
  final int uniqueKiransRead;
  final DateRange? dateRange;

  MigrationPreview({
    required this.totalLegacyEntries,
    required this.duplicatesFound,
    required this.newEntriesToMigrate,
    required this.totalReadingTime,
    required this.uniqueKiransRead,
    this.dateRange,
  });

  bool get hasDataToMigrate => newEntriesToMigrate > 0;
}

/// Date range helper class
class DateRange {
  final DateTime start;
  final DateTime end;

  DateRange({required this.start, required this.end});

  String get formattedRange {
    final startStr = '${start.day}/${start.month}/${start.year}';
    final endStr = '${end.day}/${end.month}/${end.year}';
    return '$startStr - $endStr';
  }
}
