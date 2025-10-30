# Reading History Migration Guide

This guide explains how to use the legacy reading history migration tools to migrate your Firebase data to the current format.

## Files Created

1. **`models/legacy_reading_history_model.dart`** - Model for parsing legacy Firebase data
2. **`services/reading_history_migration_service.dart`** - Service to handle the migration process
3. **`pages/migration_page.dart`** - UI page to run the migration

## Usage

### 1. Add Migration Page to Your App

Add the migration route to your main.dart:

```dart
// In main.dart routes
routes: {
  // ...existing routes...
  '/migration': (context) => const MigrationPage(),
},
```

### 2. Programmatic Usage

```dart
import 'package:saxatsavita_flutter/services/reading_history_migration_service.dart';

// Check if user has legacy data
final migrationService = ReadingHistoryMigrationService();
final hasLegacyData = await migrationService.hasLegacyData(userId);

if (hasLegacyData) {
  // Get migration preview
  final preview = await migrationService.getMigrationPreview(userId);
  print('Found ${preview.totalLegacyEntries} legacy entries');
  print('${preview.newEntriesToMigrate} new entries to migrate');
  
  // Run migration
  final result = await migrationService.migrateLegacyData(
    userId,
    onProgress: (current, total) {
      print('Progress: $current/$total');
    },
  );
  
  if (result.success) {
    print('Migration completed: ${result.migratedCount} entries migrated');
  } else {
    print('Migration failed: ${result.message}');
  }
}
```

### 3. Auto-Migration for Current User

```dart
// Simple auto-migration for logged-in user
final result = await migrationService.autoMigrateCurrentUser();
print(result.message);
```

## Data Structure

### Legacy Format (Firebase)
```json
{
  "category": "KIRAN_READ",
  "createdAt": "2024-08-01T09:17:24.000Z",
  "durationSeconds": 62,
  "historyIndex": 18,
  "kiranIndex": 52,
  "partNumber": 1
}
```

### Current Format (Local)
```dart
ReadingHistory(
  category: "KIRAN_READ",
  createdAt: DateTime(2024, 8, 1, 9, 17, 24),
  durationSeconds: 62,
  kiranIndex: 52,
  partNumber: 1,
)
```

## Features

- **Duplicate Detection**: Skips entries that already exist
- **Progress Tracking**: Shows migration progress
- **Error Handling**: Handles partial failures gracefully
- **Preview Mode**: See what will be migrated before running
- **Statistics**: Get reading statistics from legacy data

## Safety Features

- No data is deleted unless explicitly requested
- Duplicates are automatically detected and skipped
- Detailed error reporting for failed migrations
- Rollback capability (existing data remains intact)

## Navigation to Migration Page

Add a button or menu item to navigate to the migration page:

```dart
// In settings or main menu
ListTile(
  leading: const Icon(Icons.sync),
  title: const Text('Migrate Legacy Data'),
  onTap: () => Navigator.pushNamed(context, '/migration'),
),
```

## Firebase Collections Structure

The migration service expects legacy data in this Firebase structure:

```
/users/{userId}/reading_history/{documentId}
```

Each document should contain the fields shown in the legacy format above.

## Testing

Before running on production data:

1. Test with a small dataset first
2. Use the preview feature to verify data detection
3. Check the migration results carefully
4. Verify that your current reading history service works correctly

## Troubleshooting

- **No legacy data found**: Check Firebase collection path and authentication
- **Migration fails**: Check network connectivity and Firebase permissions
- **Duplicates not detected**: Verify timestamp and data matching logic
- **Performance issues**: Consider migrating in batches for large datasets