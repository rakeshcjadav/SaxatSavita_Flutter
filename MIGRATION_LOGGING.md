# Firebase Migration Logging

This document explains how data migration is logged to Firebase for tracking and debugging purposes.

## Overview

When users migrate their legacy data (reading history, kiran user info, etc.) from old storage formats to new ones, comprehensive logs are automatically written to Firebase under the user's document.

## Firebase Structure

### 1. Migration Logs Collection
Detailed logs for each migration attempt:

```
/users/{userId}/migration_logs/
  └── {auto-generated-doc-id}
      ├── migrationType: "reading_history" | "kiran_user_info"
      ├── timestamp: ServerTimestamp
      ├── success: boolean
      ├── migratedCount: number
      ├── skippedCount: number
      ├── errorCount: number
      ├── message: string
      ├── errors: array<string>
      ├── appVersion: string
      ├── platform: string (android, ios, web, etc.)
      └── additionalData: object (migration-specific metadata)
```

### 2. Migration Status (User Metadata)
Current status stored in the user's main document:

```
/users/{userId}
  └── migrations/
      ├── reading_history/
      │   ├── status: "pending" | "in_progress" | "completed" | "failed"
      │   ├── lastUpdated: ServerTimestamp
      │   ├── message: string
      │   ├── completedAt: ISO8601 string
      │   ├── migratedCount: number
      │   ├── skippedCount: number
      │   └── errorCount: number
      └── kiran_user_info/
          ├── status: "completed" | "failed"
          ├── lastUpdated: ServerTimestamp
          ├── message: string
          └── ... (same as above)
```

## Migration Types

### 1. Reading History Migration
- **Type**: `reading_history`
- **Purpose**: Migrate reading session data from legacy format to new format
- **Additional Data**:
  - `totalLegacyEntries`: Total number of legacy entries found
  - `deletedLegacyData`: Whether legacy data was deleted after migration

### 2. Kiran User Info Migration
- **Type**: `kiran_user_info`
- **Purpose**: Migrate user progress, favorites, notes from Part_1...Part_5 collections
- **Additional Data**:
  - `totalLegacyEntries`: Total entries across all parts
  - `deletedLegacyData`: Whether legacy data was deleted

## How It Works

### Automatic Logging
Migration services automatically write logs when migration completes:

```dart
// Example from reading_history_migration_service.dart
final result = await ReadingHistoryMigrationService()
    .migrateLegacyData(userId, deleteAfterMigration: true);

// Logs are automatically written:
// 1. Detailed log in migration_logs collection
// 2. Status update in user document
```

### Manual Status Updates
You can also manually update migration status:

```dart
await writeMigrationStatus(
  userId,
  migrationType: 'reading_history',
  status: 'in_progress',
  message: 'Starting migration...',
);
```

## Status Values

- **pending**: Migration needed but not started
- **in_progress**: Currently migrating data
- **completed**: Successfully migrated all data
- **failed**: Migration encountered errors

## Use Cases

### 1. Admin Dashboard
Query migration status across all users:

```javascript
// Firebase query
db.collection('users')
  .where('migrations.reading_history.status', '==', 'failed')
  .get()
```

### 2. User Support
Check specific user's migration history:

```javascript
db.collection('users')
  .doc(userId)
  .collection('migration_logs')
  .orderBy('timestamp', 'desc')
  .limit(10)
  .get()
```

### 3. Error Analysis
Find common migration errors:

```javascript
db.collectionGroup('migration_logs')
  .where('success', '==', false)
  .where('errorCount', '>', 0)
  .get()
```

### 4. Progress Tracking
Monitor ongoing migrations:

```javascript
db.collection('users')
  .where('migrations.kiran_user_info.status', '==', 'in_progress')
  .get()
```

## Security Rules

Ensure proper Firestore security rules:

```javascript
match /users/{userId}/migration_logs/{logId} {
  // Users can read their own logs
  allow read: if request.auth.uid == userId;
  
  // Only app can write logs
  allow write: if request.auth.uid == userId;
}

match /users/{userId} {
  // Users can read their own migration status
  allow read: if request.auth.uid == userId;
  
  // Only app can update migration status
  allow update: if request.auth.uid == userId;
}
```

## Best Practices

1. **Always log migrations**: Helps debugging and user support
2. **Include error details**: Store specific error messages for troubleshooting
3. **Track metadata**: Platform, app version, timestamp for analysis
4. **Update status atomically**: Use transactions if needed
5. **Don't log sensitive data**: Only log metadata, not actual user content
6. **Set retention policies**: Consider cleaning old logs after a period

## Example Queries

### Check if user needs migration
```dart
final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .get();

final readingHistoryStatus = 
    userDoc.data()?['migrations']?['reading_history']?['status'];

if (readingHistoryStatus == null || readingHistoryStatus == 'failed') {
  // User needs migration
}
```

### Get latest migration log
```dart
final latestLog = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('migration_logs')
    .orderBy('timestamp', descending: true)
    .limit(1)
    .get();
```

## Troubleshooting

### Migration keeps failing
1. Check error messages in migration_logs
2. Verify network connectivity
3. Check Firestore permissions
4. Validate legacy data format

### Migration status not updating
1. Ensure user is authenticated
2. Check Firestore rules
3. Verify merge: true in set operations
4. Check for network errors

### Duplicate entries
The migration service automatically skips duplicates based on:
- `createdAt` timestamp
- `partNumber` and `kiranIndex` (for reading history)
- Checks local storage before saving

## Performance Considerations

- Migration logs are written asynchronously
- Failed log writes don't block migration
- Use batched writes for large migrations
- Consider pagination for large datasets

---

For more information, see the implementation in:
- `lib/services/reading_history_migration_service.dart`
- `lib/services/kiranuser_info_migration_service.dart`
