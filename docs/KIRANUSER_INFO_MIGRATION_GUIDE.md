# KiranUserInfo Migration Guide

This guide explains how to migrate your legacy KiranUserInfo data from Firebase to the current format.

## Overview

The KiranUserInfo migration handles user-specific data for each Kiran including:
- Reading progress
- Favourite status
- Personal notes
- Read count
- Last updated timestamps

## Firebase Data Structure

Your legacy data is stored in Firebase collections with this structure:

```
/users/{userId}/Part_{partNumber}/{documentId}
```

### Legacy Data Fields
```json
{
  "favourite": 0,           // 0 or 1 (boolean as int)
  "kiranindex": 1,         // Note: lowercase 'i' 
  "listIndex": 0,
  "note": "વિરહ એક",        // User note in Gujarati
  "partNumber": 1,
  "progress": 0,           // 0-100 percentage
  "readCount": 2,          // Number of times read
  "updatedAt": "2024-07-31T09:10:05.000Z"
}
```

## Usage

### 1. Basic Migration

```dart
import 'package:saxatsavita_flutter/services/kiranuser_info_migration_service.dart';

final migrationService = KiranUserInfoMigrationService();

// Check if user has legacy data
final hasLegacyData = await migrationService.hasLegacyKiranUserInfoData(userId);

if (hasLegacyData) {
  // Get preview
  final preview = await migrationService.getKiranUserInfoMigrationPreview(userId);
  
  print('Found ${preview.totalLegacyEntries} Kiran entries');
  print('${preview.favouriteKirans} favourites');
  print('${preview.completedKirans} completed');
  
  // Run migration
  final result = await migrationService.migrateLegacyKiranUserInfoData(userId);
  
  if (result.success) {
    print('Migration successful: ${result.migratedCount} entries');
  }
}
```

### 2. Auto-Migration

```dart
// Migrate for current logged-in user
final result = await migrationService.autoMigrateCurrentUserKiranUserInfo();
print(result.message);
```

### 3. Using the UI

Use the comprehensive migration page:

```dart
// Navigate to migration page
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const ComprehensiveMigrationPage(),
  ),
);
```

## Data Mapping

### Legacy → Current Format

| Legacy Field | Current Field | Notes |
|--------------|---------------|-------|
| `favourite` | `isFavourite` | 0/1 integer |
| `kiranindex` | `kiranIndex` | Note lowercase 'i' in legacy |
| `listIndex` | `listIndex` | Direct mapping |
| `note` | `note` | Direct mapping |
| `partNumber` | `partNumber` | From collection path |
| `progress` | `progress` | 0-100 percentage |
| `readCount` | `readCount` | Direct mapping |
| `updatedAt` | `updatedAt` | Parsed to DateTime |

## Statistics Available

The migration preview provides these statistics:

- **Total Kirans**: Total number of Kiran entries found
- **Favourite Kirans**: Number marked as favourite
- **Completed Kirans**: Number with 100% progress
- **Kirans with Notes**: Number with user notes
- **Average Progress**: Average completion percentage
- **Entries by Part**: Breakdown by part number (1-5)

## Implementation Required

You need to implement these methods based on your storage system:

### 1. Check for Existing Entries

```dart
Future<bool> _checkIfKiranUserInfoExists(int partNumber, int kiranIndex, String userId) async {
  // TODO: Check your current storage (SharedPreferences, SQLite, etc.)
  // Return true if entry already exists
}
```

### 2. Save Migrated Data

```dart
Future<void> _saveKiranUserInfo(KiranUserInfo kiranUserInfo, String userId) async {
  // TODO: Save to your current storage system
  // This might be SharedPreferences, local database, or new Firebase structure
}
```

## Example Implementation

Here's how you might implement the save method:

```dart
Future<void> _saveKiranUserInfo(KiranUserInfo kiranUserInfo, String userId) async {
  try {
    // Example: Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final key = 'kiran_${kiranUserInfo.partNumber}_${kiranUserInfo.kiranIndex}_$userId';
    final json = kiranUserInfo.toJson();
    await prefs.setString(key, jsonEncode(json));
    
    // Or save to your current Firebase structure
    await FirebaseFirestore.instance
        .collection('current_user_data')
        .doc(userId)
        .collection('kirans')
        .doc('${kiranUserInfo.partNumber}_${kiranUserInfo.kiranIndex}')
        .set(json);
        
  } catch (e) {
    throw Exception('Failed to save KiranUserInfo: $e');
  }
}
```

## Collection Paths

The migration service checks these Firebase collection paths:

- `/users/{userId}/Part_1`
- `/users/{userId}/Part_2`
- `/users/{userId}/Part_3`
- `/users/{userId}/Part_4`
- `/users/{userId}/Part_5`

## Error Handling

The migration service handles:

- **Missing Collections**: Continues if some part collections don't exist
- **Invalid Data**: Skips entries with missing required fields
- **Duplicates**: Automatically detects and skips existing entries
- **Partial Failures**: Continues migration even if some entries fail

## Data Validation

Legacy entries are validated for:

- Valid part numbers (1-5)
- Non-negative progress values
- Valid timestamp formats
- Required fields presence

## Migration Preview

Before running migration, you can get a preview that shows:

```dart
final preview = await migrationService.getKiranUserInfoMigrationPreview(userId);

// Preview contains:
// - totalLegacyEntries: Total Kiran entries found
// - newEntriesToMigrate: Entries that will be migrated
// - duplicatesFound: Entries already migrated
// - favouriteKirans: Number of favourites
// - completedKirans: Number completed (100% progress)
// - kiransWithNotes: Number with user notes
// - averageProgress: Average completion percentage
// - entriesByPart: Map of part number to count
```

## Safety Features

- **No Data Loss**: Original Firebase data is preserved unless explicitly deleted
- **Duplicate Prevention**: Automatically skips entries that already exist
- **Rollback Support**: Original data remains available for rollback
- **Progress Tracking**: Real-time migration progress reporting
- **Error Reporting**: Detailed error messages for failed migrations

## Testing

Before production use:

1. Test with a small dataset
2. Verify the save/check methods work correctly
3. Test duplicate detection
4. Validate migrated data integrity
5. Test rollback procedures

## Troubleshooting

- **No data found**: Check Firebase collection paths and user permissions
- **Save errors**: Implement and test the `_saveKiranUserInfo` method
- **Duplicate detection issues**: Implement the `_checkIfKiranUserInfoExists` method
- **Performance issues**: Consider batch processing for large datasets