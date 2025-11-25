# Firebase Remote Config - Quick Start

## ✅ Implementation Complete!

Firebase Remote Config has been successfully integrated into your Saxat Savita Flutter app.

## What Was Done

### 1. **Dependencies** ✅
- Added `firebase_remote_config: ^6.0.2` to `pubspec.yaml`
- Installed via `flutter pub get`

### 2. **Service Created** ✅
- `lib/services/remote_config_service.dart` - Main Remote Config service
  - Singleton pattern for easy access
  - 30+ default parameters configured
  - Feature flags for all major features
  - Version checking capabilities
  - Maintenance mode support

### 3. **Helper Widgets** ✅
- `lib/components/remote_config_widgets.dart`
  - `MaintenanceModeScreen` - Full-screen maintenance message
  - `UpdateRequiredDialog` - Force/optional update dialog
  - `AnnouncementBanner` - Dismissible announcement widget
  - `ConditionalFeature` - Wrap features to enable/disable remotely
  - `RemoteConfigVersionCheck` - Mixin for version checking

### 4. **Initialization** ✅
- Integrated into `main.dart`
- Initializes automatically on app startup
- Configured with 1-hour fetch interval

### 5. **Documentation** ✅
- `docs/FIREBASE_REMOTE_CONFIG_GUIDE.md` - Complete setup guide
- `docs/REMOTE_CONFIG_INTEGRATION_EXAMPLES.dart` - Code examples

## Available Features

### Feature Flags (Boolean)
```dart
final remoteConfig = RemoteConfigService();

remoteConfig.enableSearch          // Search functionality
remoteConfig.enableNotes           // Notes feature
remoteConfig.enableQuotes          // Quote image generation
remoteConfig.enableReadingHistory  // Reading history tracking
remoteConfig.enableReadingPlans    // Reading plans
remoteConfig.enableAutoScroll      // Auto-scroll feature
remoteConfig.enableBookmarks       // Bookmarks
remoteConfig.enableFavorites       // Favorites
remoteConfig.enableSocialSharing   // Social media sharing
```

### App Control
```dart
remoteConfig.isMaintenanceMode     // Enable maintenance mode
remoteConfig.maintenanceMessage    // Maintenance screen message
remoteConfig.forceUpdateRequired   // Force users to update
remoteConfig.minimumSupportedVersion // Minimum version required
remoteConfig.latestVersion         // Latest available version
```

### Content & UI
```dart
remoteConfig.featuredKiranPart     // Featured Kiran part number
remoteConfig.featuredKiranIndex    // Featured Kiran index
remoteConfig.announcementEnabled   // Show announcement banner
remoteConfig.announcementTitle     // Announcement title
remoteConfig.announcementMessage   // Announcement message
remoteConfig.defaultThemeColor     // Default theme color (#B8572A)
remoteConfig.defaultFontSize       // Default font size (18.0)
```

### A/B Testing
```dart
remoteConfig.useCustomHtmlWidget   // Toggle HTML rendering implementation
```

## Quick Usage Examples

### 1. Check Maintenance Mode
```dart
// In your main screens
if (RemoteConfigService().isMaintenanceMode) {
  return MaintenanceModeScreen();
}
```

### 2. Conditional Features
```dart
// Show/hide features based on remote config
if (RemoteConfigService().enableNotes) {
  FloatingActionButton(
    onPressed: () => openNotes(),
    child: Icon(Icons.note_add),
  )
}
```

### 3. Show Announcements
```dart
// Add to any page
Column(
  children: [
    AnnouncementBanner(),  // Auto shows/hides based on config
    // ... rest of your content
  ],
)
```

### 4. Check for Updates
```dart
class MyPage extends StatefulWidget {
  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> with RemoteConfigVersionCheck {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAppVersion(context);  // Shows update dialog if needed
    });
  }
}
```

### 5. A/B Testing
```dart
final remoteConfig = RemoteConfigService();

// Toggle between implementations
if (remoteConfig.useCustomHtmlWidget) {
  return CustomHtmlWidget(content: html);
} else {
  return HtmlToTextSpan.convertToWidgets(html, ...);
}
```

## Next Steps - Firebase Console Setup

### 1. Open Firebase Console
Go to: https://console.firebase.google.com/
- Select project: `saxat-savita-crashanalytics`
- Click **Remote Config** in left sidebar

### 2. Add Parameters
Click "Add parameter" for each configuration you want to control:

**Essential Parameters to Add First:**
```
maintenance_mode: false (Boolean)
announcement_enabled: false (Boolean)
force_update_required: false (Boolean)
enable_search: true (Boolean)
enable_notes: true (Boolean)
```

### 3. Publish Changes
- Click **"Publish changes"** button
- Changes take effect within 1 hour (or immediately on app restart)

### 4. Create Conditions (Optional)
Target specific users or regions:
- Click "Add condition"
- Examples: "Users in India", "Android users only", "10% of users"

## Testing

### Local Testing
```bash
# App works with default values without Firebase setup
flutter run
```

### Firebase Testing
1. Add parameters in Firebase Console
2. Publish changes
3. Restart app or wait for fetch interval
4. Verify behavior changes

### Debug Logging
Check console output for:
```
✅ Remote Config initialized successfully
=== Remote Config Values ===
maintenance_mode: false (source: default)
enable_search: true (source: remote)
===========================
```

## Emergency Use Cases

### 🚨 Critical Bug Found
```json
{
  "maintenance_mode": true,
  "maintenance_message": "We're fixing a critical issue. Back soon!"
}
```

### ⚠️ Disable Broken Feature
```json
{
  "enable_auto_scroll": false
}
```

### 🔄 Force Update
```json
{
  "force_update_required": true,
  "minimum_supported_version": "2.16.0"
}
```

### 📢 Important Announcement
```json
{
  "announcement_enabled": true,
  "announcement_title": "Important Update",
  "announcement_message": "New features available in v2.16!"
}
```

## Files Created/Modified

### Created:
- ✅ `lib/services/remote_config_service.dart`
- ✅ `lib/components/remote_config_widgets.dart`
- ✅ `docs/FIREBASE_REMOTE_CONFIG_GUIDE.md`
- ✅ `docs/REMOTE_CONFIG_INTEGRATION_EXAMPLES.dart`
- ✅ `docs/REMOTE_CONFIG_QUICK_START.md` (this file)

### Modified:
- ✅ `pubspec.yaml` - Added firebase_remote_config dependency
- ✅ `lib/main.dart` - Added Remote Config initialization

## Support & Troubleshooting

### Common Issues

**1. Config not updating?**
- Check network connection
- Wait for fetch interval (1 hour) or force close app
- Verify parameters published in Firebase Console

**2. Feature not hiding/showing?**
- Check parameter name matches exactly
- Verify boolean value (true/false)
- Check debug logs for current values

**3. Maintenance mode not working?**
- Verify `maintenance_mode` parameter exists
- Check it's set to `true` (Boolean, not String)
- Restart app to fetch latest config

### Debug Commands
```dart
// Log all current config values
RemoteConfigService().getAllValues().forEach((key, value) {
  print('$key: ${value.asString()}');
});

// Force refresh config (for testing)
await RemoteConfigService().fetchConfig();
```

## Resources

- **Full Guide**: `docs/FIREBASE_REMOTE_CONFIG_GUIDE.md`
- **Code Examples**: `docs/REMOTE_CONFIG_INTEGRATION_EXAMPLES.dart`
- **Firebase Docs**: https://firebase.google.com/docs/remote-config
- **Flutter Package**: https://pub.dev/packages/firebase_remote_config

---

**Status**: ✅ Ready to use!
**Next Action**: Set up parameters in Firebase Console
**Contact**: Check debug logs for detailed information

🎉 Happy configuring!
