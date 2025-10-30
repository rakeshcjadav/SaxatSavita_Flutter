# Firebase Sync Setup Guide

This guide will help you complete the Firebase sync integration for your app.

## Step 1: Install Dependencies

Run the following command to install Cloud Firestore:

```bash
flutter pub get
```

The required dependency has already been added to `pubspec.yaml`:
- `cloud_firestore: ^5.4.4`

## Step 2: Update Firebase Rules

Add these Firestore security rules to allow users to read/write their own data:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Step 3: Replace the Basic Service

Once `flutter pub get` completes successfully, replace the imports in your files:

### In any file using Firebase sync:
```dart
// Replace this:
import 'package:saxatsavita_flutter/services/firebase_sync_service_basic.dart';

// With this:
import 'package:saxatsavita_flutter/services/firebase_sync_service.dart';
```

## Step 4: Integration Points

### A. App Settings Sync
Add this to your settings page where app settings are updated:

```dart
import 'package:saxatsavita_flutter/helpers/firebase_integration_helper.dart';

// After updating settings:
void updateAppSettings(AppSettings newSettings) {
  appSettingsNotifier.value = newSettings;
  // This will automatically trigger Firebase sync due to listener
}

// Setup auto-sync (call this in main.dart or app initialization):
FirebaseIntegrationHelper().setupAutoSync();
```

### B. Reading History Sync
Update your `ReadingHistoryService.saveReadingHistory()` method:

```dart
static Future<void> saveReadingHistory(ReadingHistory history) async {
  // ... existing local save logic ...
  
  // Add Firebase sync
  await FirebaseIntegrationHelper().onReadingHistoryAdded();
}
```

### C. Book User Info Sync
Update your book service when user info changes:

```dart
import 'package:saxatsavita_flutter/helpers/firebase_integration_helper.dart';

// After updating BookUserInfo:
void updateBookUserInfo(BookUserInfo info) {
  // ... existing logic ...
  
  // Sync to Firebase
  FirebaseIntegrationHelper().onBookUserInfoChanged();
}
```

### D. Login/Logout Integration
Add sync on login and data clearing on logout:

```dart
// On successful login:
Future<void> onUserLogin() async {
  // Load user data from Firebase
  await FirebaseIntegrationHelper().loadDataFromFirebase();
  
  // Setup auto-sync
  FirebaseIntegrationHelper().setupAutoSync();
}

// On logout:
Future<void> onUserLogout() async {
  // Optional: Final sync before logout
  await FirebaseIntegrationHelper().syncAllData();
}
```

## Step 5: App Initialization

Add this to your `main.dart` or app initialization:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Check if user is already logged in
  if (FirebaseAuth.instance.currentUser != null) {
    // Load data from Firebase
    await FirebaseIntegrationHelper().loadDataFromFirebase();
    
    // Setup auto-sync
    FirebaseIntegrationHelper().setupAutoSync();
  }
  
  runApp(MyApp());
}
```

## Step 6: Testing

1. **Test data sync**: Update app settings and check Firebase console
2. **Test data loading**: Login from a new device and verify data loads
3. **Test offline/online**: Ensure sync works when connection is restored

## Data Structure in Firebase

Your Firebase data will be organized as:

```
users/{userId}/
├── appSettings/
│   └── settings -> {fontSize, lineHeight, themeColor, ...}
├── bookUserInfo/
│   ├── 1 -> {id, partNumber, bookmarkKiranIndex, ...}
│   └── 2 -> {id, partNumber, bookmarkKiranIndex, ...}
├── kiranUserInfo/
│   ├── 1 -> {kiranIndex, isFavourite, readCount, note, ...}
│   └── 2 -> {kiranIndex, isFavourite, readCount, note, ...}
└── readingHistory/
    ├── {timestamp1} -> {category, durationSeconds, kiranIndex, ...}
    └── {timestamp2} -> {category, durationSeconds, kiranIndex, ...}
```

## Advanced Features

The Firebase service includes:

- ✅ **Batch operations** for efficient syncing
- ✅ **Real-time listeners** for live updates
- ✅ **Conflict resolution** with timestamps
- ✅ **Error handling** and retry logic
- ✅ **Data statistics** and monitoring
- ✅ **Selective sync** for bandwidth optimization

## Troubleshooting

### Common Issues:

1. **Permission denied**: Check Firebase rules and user authentication
2. **Data not syncing**: Verify user is logged in and has internet connection
3. **Large data sets**: Consider pagination for reading history
4. **Offline support**: Firebase automatically handles offline caching

### Debug Tips:

- Enable debug prints to monitor sync operations
- Use Firebase console to verify data structure
- Test with airplane mode to verify offline behavior
- Monitor Firebase usage quotas

## Performance Optimization

- **Batch writes**: Multiple updates in single transaction
- **Selective sync**: Only sync changed data
- **Background sync**: Use isolates for large operations
- **Compression**: Minimize data size for mobile users

Your Firebase sync system is now ready for production use! 🚀