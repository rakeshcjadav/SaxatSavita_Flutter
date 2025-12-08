import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:saxatsavita_flutter/models/legacy_reading_history_model.dart';
import 'package:saxatsavita_flutter/models/reading_history_model.dart';
import 'package:saxatsavita_flutter/services/reading_history_service.dart';

/// Service to migrate legacy reading history data to the current format
class ReadingHistoryMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Enable verbose logging for debugging migration issues
  static const bool _enableVerboseLogging = true;

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
      if (_enableVerboseLogging) {
        debugPrint('🔍 [Migration] Fetching legacy data for user: $userId');
      }

      final legacyCollection = _firestore
          .collection('users')
          .doc(userId)
          .collection('reading_history');

      final snapshot = await legacyCollection.orderBy('createdAt').get();

      if (_enableVerboseLogging) {
        debugPrint(
          '📊 [Migration] Found ${snapshot.docs.length} legacy entries',
        );
      }

      return snapshot.docs.map((doc) {
        return LegacyReadingHistory.fromFirestore(doc);
      }).toList();
    } catch (e) {
      debugPrint('❌ [Migration] Error fetching legacy reading history: $e');
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
      if (_enableVerboseLogging) {
        debugPrint('🚀 [Migration] Starting migration for user: $userId');
      }

      // Get all legacy data
      final legacyEntries = await getLegacyReadingHistory(userId);

      if (legacyEntries.isEmpty) {
        if (_enableVerboseLogging) {
          debugPrint('✅ [Migration] No legacy data found to migrate');
        }
        return MigrationResult(
          success: true,
          migratedCount: 0,
          skippedCount: 0,
          errorCount: 0,
          message: 'No legacy data found to migrate.',
        );
      }

      if (_enableVerboseLogging) {
        debugPrint(
          '📋 [Migration] Processing ${legacyEntries.length} legacy entries',
        );
      }

      int migratedCount = 0;
      int skippedCount = 0;
      int errorCount = 0;
      final List<String> errors = [];

      // PERFORMANCE FIX: Load existing entries once, not in the loop!
      final existingEntries = await ReadingHistoryService.loadReadingHistory();
      if (_enableVerboseLogging) {
        debugPrint(
          '📂 [Migration] Loaded ${existingEntries.length} existing entries for duplicate check',
        );
      }

      // Process each legacy entry
      for (int i = 0; i < legacyEntries.length; i++) {
        final legacyEntry = legacyEntries[i];

        if (_enableVerboseLogging && i % 10 == 0) {
          debugPrint('⏳ [Migration] Progress: $i/${legacyEntries.length}');
        }

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
          final isDuplicate = existingEntries.any((entry) {
            return entry.createdAt == currentEntry.createdAt &&
                entry.partNumber == currentEntry.partNumber &&
                entry.kiranIndex == currentEntry.kiranIndex;
          });

          if (isDuplicate) {
            if (_enableVerboseLogging) {
              debugPrint(
                '⏭️  [Migration] Skipping duplicate: Kiran ${legacyEntry.kiranIndex} at ${legacyEntry.createdAt}',
              );
            }
            skippedCount++;
          } else {
            // Add to current reading history
            await ReadingHistoryService.saveReadingHistory(currentEntry);
            migratedCount++;
            if (_enableVerboseLogging) {
              debugPrint(
                '✅ [Migration] Migrated: Kiran ${legacyEntry.kiranIndex} (${legacyEntry.durationSeconds}s)',
              );
            }
          }

          // Report progress
          onProgress?.call(i + 1, legacyEntries.length);
        } catch (e) {
          errorCount++;
          final errorMsg =
              'Failed to migrate entry ${legacyEntry.documentId}: $e';
          errors.add(errorMsg);
          debugPrint('❌ [Migration] $errorMsg');
        }
      }

      // Optionally delete legacy data after successful migration
      if (deleteAfterMigration && errorCount == 0) {
        if (_enableVerboseLogging) {
          debugPrint('🗑️  [Migration] Deleting legacy data...');
        }
        await _deleteLegacyData(userId);
      }

      if (_enableVerboseLogging) {
        debugPrint(
          '🎉 [Migration] Complete: $migratedCount migrated, $skippedCount skipped, $errorCount errors',
        );
      }

      final result = MigrationResult(
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

      // Write migration log to Firebase
      await writeMigrationLog(
        userId,
        migrationType: 'reading_history',
        result: result,
        additionalData: {
          'totalLegacyEntries': legacyEntries.length,
          'deletedLegacyData': deleteAfterMigration && errorCount == 0,
        },
      );

      // Update migration status
      await writeMigrationStatus(
        userId,
        migrationType: 'reading_history',
        status: result.success ? 'completed' : 'failed',
        message: result.message,
        metadata: {
          'completedAt': DateTime.now().toIso8601String(),
          'migratedCount': migratedCount,
          'skippedCount': skippedCount,
          'errorCount': errorCount,
        },
      );

      return result;
    } catch (e) {
      debugPrint('Migration failed: $e');
      final result = MigrationResult(
        success: false,
        migratedCount: 0,
        skippedCount: 0,
        errorCount: 1,
        message: 'Migration failed: $e',
        errors: [e.toString()],
      );

      // Write error log to Firebase
      await writeMigrationLog(
        userId,
        migrationType: 'reading_history',
        result: result,
      );

      // Update migration status as failed
      await writeMigrationStatus(
        userId,
        migrationType: 'reading_history',
        status: 'failed',
        message: 'Migration encountered an error: $e',
      );

      return result;
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

  /// DEBUG: Migrate for a specific user ID (for testing/debugging)
  /// Use this to test migration with another user's ID on your device
  Future<MigrationResult> debugMigrateSpecificUser(
    String userId, {
    Function(int current, int total)? onProgress,
  }) async {
    debugPrint('🔧 [DEBUG] Migrating data for user ID: $userId');
    return await migrateLegacyData(userId, onProgress: onProgress);
  }

  /// DEBUG: Get legacy data count for a specific user ID
  Future<int> debugGetLegacyDataCount(String userId) async {
    try {
      final legacyCollection = _firestore
          .collection('users')
          .doc(userId)
          .collection('reading_history');

      final snapshot = await legacyCollection.limit(1).get();

      if (snapshot.docs.isEmpty) {
        debugPrint('🔧 [DEBUG] User $userId has no legacy data');
        return 0;
      }

      // Get actual count
      final allDocs = await legacyCollection.get();
      final count = allDocs.docs.length;
      debugPrint('🔧 [DEBUG] User $userId has $count legacy entries');
      return count;
    } catch (e) {
      debugPrint('🔧 [DEBUG] Error checking legacy data: $e');
      return 0;
    }
  }

  /// DEBUG: Get migration status for a specific user ID
  Future<Map<String, dynamic>?> debugGetMigrationStatus(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();

      if (!userDoc.exists) {
        debugPrint('🔧 [DEBUG] User document does not exist');
        return null;
      }

      final data = userDoc.data();
      final migrations = data?['migrations'] as Map<String, dynamic>?;

      debugPrint('🔧 [DEBUG] Migration status: $migrations');
      return migrations;
    } catch (e) {
      debugPrint('🔧 [DEBUG] Error getting migration status: $e');
      return null;
    }
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

/// Write migration log to Firebase under user's document
Future<void> writeMigrationLog(
  String userId, {
  required String migrationType,
  required MigrationResult result,
  Map<String, dynamic>? additionalData,
}) async {
  try {
    final logData = {
      'migrationType':
          migrationType, // e.g., 'reading_history', 'kiran_user_info'
      'timestamp': FieldValue.serverTimestamp(),
      'success': result.success,
      'migratedCount': result.migratedCount,
      'skippedCount': result.skippedCount,
      'errorCount': result.errorCount,
      'message': result.message,
      'errors': result.errors,
      'appVersion':
          'flutter', // You can add package_info_plus to get actual version
      'platform': defaultTargetPlatform.name,
      ...?additionalData,
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('migration_logs')
        .add(logData);

    debugPrint('Migration log written to Firebase for user: $userId');
  } catch (e) {
    debugPrint('Error writing migration log to Firebase: $e');
  }
}

/// Write a simple migration status message to user's metadata
Future<void> writeMigrationStatus(
  String userId, {
  required String migrationType,
  required String status,
  String? message,
  Map<String, dynamic>? metadata,
}) async {
  try {
    final statusData = {
      'migrations.$migrationType': {
        'status':
            status, // e.g., 'pending', 'in_progress', 'completed', 'failed'
        'lastUpdated': FieldValue.serverTimestamp(),
        'message': message,
        ...?metadata,
      },
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .set(statusData, SetOptions(merge: true));

    debugPrint(
      'Migration status updated for user $userId: $migrationType = $status',
    );
  } catch (e) {
    debugPrint('Error writing migration status to Firebase: $e');
  }
}
