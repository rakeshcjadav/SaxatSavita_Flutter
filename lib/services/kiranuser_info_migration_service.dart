import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:saxatsavita_flutter/models/legacy_kiranuser_info_model.dart';
import 'package:saxatsavita_flutter/models/kiranuserinfo_model.dart';
import 'package:saxatsavita_flutter/services/kiranuser_service.dart';
import 'package:saxatsavita_flutter/helpers/firebase_integration_helper.dart';

/// Service to migrate legacy KiranUserInfo data to the current format
class KiranUserInfoMigrationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if user has legacy KiranUserInfo data that needs migration
  Future<bool> hasLegacyKiranUserInfoData(String userId) async {
    try {
      // Check different possible collection paths
      final paths = [
        'users/$userId/Part_1',
        'users/$userId/Part_2',
        'users/$userId/Part_3',
        'users/$userId/Part_4',
        'users/$userId/Part_5',
      ];

      for (final path in paths) {
        final snapshot = await _firestore.collection(path).limit(1).get();
        if (snapshot.docs.isNotEmpty) {
          return true;
        }
      }

      return false;
    } catch (e) {
      debugPrint('Error checking for legacy KiranUserInfo data: $e');
      return false;
    }
  }

  /// Get all legacy KiranUserInfo data for a user
  Future<List<LegacyKiranUserInfo>> getLegacyKiranUserInfoData(
    String userId,
  ) async {
    try {
      final List<LegacyKiranUserInfo> allEntries = [];

      // Check all possible part collections (Part_1 to Part_5)
      for (int partNum = 1; partNum <= 5; partNum++) {
        final collectionPath = 'users/$userId/Part_$partNum';

        try {
          final snapshot = await _firestore.collection(collectionPath).get();

          for (final doc in snapshot.docs) {
            final entry = LegacyKiranUserInfo.fromFirestore(doc);
            // Override partNumber from collection path if it's different
            final legacyEntry = LegacyKiranUserInfo(
              favourite: entry.favourite,
              kiranIndex: entry.kiranIndex,
              listIndex: entry.listIndex,
              note: entry.note,
              partNumber: partNum, // Use part number from collection path
              progress: entry.progress,
              readCount: entry.readCount,
              updatedAt: entry.updatedAt,
              documentId: entry.documentId,
            );
            allEntries.add(legacyEntry);
          }

          debugPrint(
            'Found ${snapshot.docs.length} entries in $collectionPath',
          );
        } catch (e) {
          debugPrint('Error reading from $collectionPath: $e');
          // Continue with other parts even if one fails
        }
      }

      // Sort by part number and kiran index
      allEntries.sort((a, b) {
        final partComparison = a.partNumber.compareTo(b.partNumber);
        if (partComparison != 0) return partComparison;
        return a.kiranIndex.compareTo(b.kiranIndex);
      });

      return allEntries;
    } catch (e) {
      debugPrint('Error fetching legacy KiranUserInfo data: $e');
      return [];
    }
  }

  /// Migrate legacy KiranUserInfo data to current format
  Future<KiranUserInfoMigrationResult> migrateLegacyKiranUserInfoData(
    String userId, {
    bool deleteAfterMigration = false,
    Function(int current, int total)? onProgress,
  }) async {
    try {
      // Get all legacy data
      final legacyEntries = await getLegacyKiranUserInfoData(userId);

      if (legacyEntries.isEmpty) {
        return KiranUserInfoMigrationResult(
          success: true,
          migratedCount: 0,
          skippedCount: 0,
          errorCount: 0,
          message: 'No legacy KiranUserInfo data found to migrate.',
        );
      }

      int migratedCount = 0;
      int skippedCount = 0;
      int errorCount = 0;
      final List<String> errors = [];

      // TODO: You'll need to implement these methods in your actual service
      // For now, I'll show the conversion structure

      // Process each legacy entry
      for (int i = 0; i < legacyEntries.length; i++) {
        final legacyEntry = legacyEntries[i];

        try {
          // Convert to current format
          final currentEntry = KiranUserInfo(
            kiranIndex: legacyEntry.kiranIndex,
            listIndex: legacyEntry.listIndex,
            partNumber: legacyEntry.partNumber,
            isFavourite: legacyEntry.favourite,
            readCount: legacyEntry.readCount,
            note: legacyEntry.note.isNotEmpty ? legacyEntry.note : null,
            progress: legacyEntry.progress,
            updatedAt: legacyEntry.updatedAt,
          );

          // Check if entry already exists (you'll need to implement this based on your storage)
          final isDuplicate = await _checkIfKiranUserInfoExists(
            currentEntry.partNumber,
            currentEntry.kiranIndex,
            userId,
          );

          if (isDuplicate) {
            debugPrint(
              'Skipping duplicate KiranUserInfo: ${legacyEntry.toString()}',
            );
            skippedCount++;
          } else {
            // Save to current storage system (you'll need to implement this)
            await _saveKiranUserInfo(currentEntry, userId);
            migratedCount++;
            debugPrint('Migrated KiranUserInfo: ${legacyEntry.toString()}');
          }

          // Report progress
          onProgress?.call(i + 1, legacyEntries.length);
        } catch (e) {
          errorCount++;
          final errorMsg =
              'Failed to migrate KiranUserInfo ${legacyEntry.documentId}: $e';
          errors.add(errorMsg);
          debugPrint(errorMsg);
        }
      }

      // Optionally delete legacy data after successful migration
      if (deleteAfterMigration && errorCount == 0) {
        await _deleteLegacyKiranUserInfoData(userId);
      }

      return KiranUserInfoMigrationResult(
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
      debugPrint('KiranUserInfo migration failed: $e');
      return KiranUserInfoMigrationResult(
        success: false,
        migratedCount: 0,
        skippedCount: 0,
        errorCount: 1,
        message: 'KiranUserInfo migration failed: $e',
        errors: [e.toString()],
      );
    }
  }

  /// Delete all legacy KiranUserInfo data for a user
  Future<void> _deleteLegacyKiranUserInfoData(String userId) async {
    try {
      final batch = _firestore.batch();
      int deletedCount = 0;

      // Delete from all part collections
      for (int partNum = 1; partNum <= 5; partNum++) {
        final collectionPath = 'users/$userId/Part_$partNum';

        try {
          final snapshot = await _firestore.collection(collectionPath).get();

          for (final doc in snapshot.docs) {
            batch.delete(doc.reference);
            deletedCount++;
          }
        } catch (e) {
          debugPrint('Error preparing deletion for $collectionPath: $e');
        }
      }

      if (deletedCount > 0) {
        await batch.commit();
        debugPrint('Deleted $deletedCount legacy KiranUserInfo entries');
      }
    } catch (e) {
      debugPrint('Error deleting legacy KiranUserInfo data: $e');
      rethrow;
    }
  }

  /// Get migration preview without actually migrating
  Future<KiranUserInfoMigrationPreview> getKiranUserInfoMigrationPreview(
    String userId,
  ) async {
    try {
      final legacyEntries = await getLegacyKiranUserInfoData(userId);

      int duplicatesFound = 0;
      int newEntries = 0;

      for (final legacyEntry in legacyEntries) {
        final isDuplicate = await _checkIfKiranUserInfoExists(
          legacyEntry.partNumber,
          legacyEntry.kiranIndex,
          userId,
        );

        if (isDuplicate) {
          duplicatesFound++;
        } else {
          newEntries++;
        }
      }

      final stats = LegacyKiranUserInfoStats(legacyEntries);

      return KiranUserInfoMigrationPreview(
        totalLegacyEntries: legacyEntries.length,
        duplicatesFound: duplicatesFound,
        newEntriesToMigrate: newEntries,
        favouriteKirans: stats.favouriteKirans,
        completedKirans: stats.completedKirans,
        kiransWithNotes: stats.kiransWithNotes,
        averageProgress: stats.averageProgress.round(),
        entriesByPart: stats.entriesByPart.map(
          (partNum, entries) => MapEntry(partNum, entries.length),
        ),
      );
    } catch (e) {
      debugPrint('Error creating KiranUserInfo migration preview: $e');
      return KiranUserInfoMigrationPreview(
        totalLegacyEntries: 0,
        duplicatesFound: 0,
        newEntriesToMigrate: 0,
        favouriteKirans: 0,
        completedKirans: 0,
        kiransWithNotes: 0,
        averageProgress: 0,
        entriesByPart: {},
      );
    }
  }

  /// Auto-migrate KiranUserInfo for current user (if logged in)
  Future<KiranUserInfoMigrationResult> autoMigrateCurrentUserKiranUserInfo({
    Function(int current, int total)? onProgress,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return KiranUserInfoMigrationResult(
        success: false,
        migratedCount: 0,
        skippedCount: 0,
        errorCount: 1,
        message: 'No user logged in',
      );
    }

    return await migrateLegacyKiranUserInfoData(
      user.uid,
      onProgress: onProgress,
    );
  }

  // TODO: Implement these methods based on your current storage system

  /// Check if a KiranUserInfo entry already exists in current system
  Future<bool> _checkIfKiranUserInfoExists(
    int partNumber,
    int kiranIndex,
    String userId,
  ) async {
    try {
      // Check in the current KiranUserService
      final kiranService = KiranUserService();
      final existingKiran =
          kiranService.kiranUserInfoList
              .where((kiran) => kiran.kiranIndex == kiranIndex)
              .firstOrNull;

      if (existingKiran != null) {
        // Check if it has been modified from default values
        final hasData =
            existingKiran.isFavourite != 0 ||
            existingKiran.readCount != 0 ||
            existingKiran.progress != 0 ||
            existingKiran.note != null ||
            existingKiran.updatedAt != null;

        debugPrint(
          'KiranUserInfo exists for kiranIndex=$kiranIndex, hasData=$hasData',
        );
        return hasData;
      }

      return false;
    } catch (e) {
      debugPrint('Error checking KiranUserInfo existence: $e');
      return false;
    }
  }

  /// Save KiranUserInfo to current storage system
  Future<void> _saveKiranUserInfo(
    KiranUserInfo kiranUserInfo,
    String userId,
  ) async {
    try {
      // Use the same method as the app currently uses to update KiranUserInfo
      final kiranService = KiranUserService();
      final kiranList = kiranService.kiranUserInfoList;

      // Find and update the existing entry
      final index = kiranList.indexWhere(
        (k) => k.kiranIndex == kiranUserInfo.kiranIndex,
      );

      if (index >= 0) {
        // Update the existing entry
        kiranList[index] = kiranUserInfo;
        debugPrint(
          'Updated KiranUserInfo for kiran ${kiranUserInfo.kiranIndex}',
        );

        // Sync to Firebase using the app's existing sync mechanism
        await kiranService.syncSingleToFirebase(kiranUserInfo);

        debugPrint(
          'Successfully saved KiranUserInfo: ${kiranUserInfo.kiranIndex}',
        );
      } else {
        debugPrint(
          'Warning: KiranUserInfo not found in service for kiranIndex: ${kiranUserInfo.kiranIndex}',
        );
      }
    } catch (e) {
      debugPrint('Error saving KiranUserInfo: $e');
      throw Exception('Failed to save KiranUserInfo: $e');
    }
  }

  /// Helper methods
  String _buildMigrationMessage(int migrated, int skipped, int errors) {
    if (errors > 0) {
      return 'KiranUserInfo migration completed with errors: $migrated migrated, $skipped skipped, $errors failed';
    } else if (skipped > 0) {
      return 'KiranUserInfo migration successful: $migrated new entries migrated, $skipped duplicates skipped';
    } else {
      return 'KiranUserInfo migration successful: $migrated entries migrated';
    }
  }

  /// Auto-migrate KiranUserInfo for current user (simplified interface)
  Future<KiranUserInfoMigrationResult> autoMigrateCurrentUser({
    Function(int current, int total)? onProgress,
  }) async {
    return await autoMigrateCurrentUserKiranUserInfo(onProgress: onProgress);
  }
}

/// Result of a KiranUserInfo migration operation
class KiranUserInfoMigrationResult {
  final bool success;
  final int migratedCount;
  final int skippedCount;
  final int errorCount;
  final String message;
  final List<String> errors;

  KiranUserInfoMigrationResult({
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

/// Preview of KiranUserInfo migration before executing
class KiranUserInfoMigrationPreview {
  final int totalLegacyEntries;
  final int duplicatesFound;
  final int newEntriesToMigrate;
  final int favouriteKirans;
  final int completedKirans;
  final int kiransWithNotes;
  final int averageProgress;
  final Map<int, int> entriesByPart; // partNumber -> count

  KiranUserInfoMigrationPreview({
    required this.totalLegacyEntries,
    required this.duplicatesFound,
    required this.newEntriesToMigrate,
    required this.favouriteKirans,
    required this.completedKirans,
    required this.kiransWithNotes,
    required this.averageProgress,
    required this.entriesByPart,
  });

  bool get hasDataToMigrate => newEntriesToMigrate > 0;
}
