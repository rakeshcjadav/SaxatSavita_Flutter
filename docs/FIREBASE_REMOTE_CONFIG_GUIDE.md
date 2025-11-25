# Firebase Remote Config Integration Guide

## Overview
Firebase Remote Config allows you to dynamically change your app's behavior and appearance without publishing an app update. This is perfect for A/B testing, feature flags, and emergency updates.

## Setup Complete ✅

The following has been implemented in your project:

### 1. Dependencies Added
- `firebase_remote_config: ^6.0.2` added to `pubspec.yaml`

### 2. Service Created
- `lib/services/remote_config_service.dart` - Main service for Remote Config
- `lib/components/remote_config_widgets.dart` - Helper widgets for common use cases

### 3. Initialization
Remote Config is automatically initialized in `main.dart` on app startup.

## Configuration in Firebase Console

### Step 1: Access Remote Config
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `saxat-savita-crashanalytics`
3. Navigate to **Remote Config** in the left sidebar

### Step 2: Add Parameters
Click "Add parameter" for each configuration value you want to manage remotely.

### Default Parameters Available

#### App Behavior
- `maintenance_mode` (Boolean) - Enable maintenance mode
- `maintenance_message` (String) - Message shown during maintenance
- `force_update_required` (Boolean) - Force users to update
- `minimum_supported_version` (String) - Minimum version (e.g., "2.0.0")
- `latest_version` (String) - Latest available version
- `update_message` (String) - Update prompt message

#### Feature Flags
- `enable_search` (Boolean) - Enable/disable search functionality
- `enable_notes` (Boolean) - Enable/disable notes feature
- `enable_quotes` (Boolean) - Enable/disable quotes feature
- `enable_reading_history` (Boolean) - Enable/disable reading history
- `enable_reading_plans` (Boolean) - Enable/disable reading plans
- `enable_auto_scroll` (Boolean) - Enable/disable auto-scroll
- `enable_bookmarks` (Boolean) - Enable/disable bookmarks
- `enable_favorites` (Boolean) - Enable/disable favorites
- `enable_social_sharing` (Boolean) - Enable/disable social sharing

#### UI Customization
- `show_welcome_screen` (Boolean) - Show welcome screen to new users
- `default_theme_color` (String) - Default theme color (hex: "#B8572A")
- `default_font_size` (Number) - Default font size (18.0)
- `default_line_height` (Number) - Default line height (2.0)
- `default_reading_speed` (Number) - Reading speed in WPM (150)

#### Content
- `featured_kiran_part` (Number) - Featured Kiran part number
- `featured_kiran_index` (Number) - Featured Kiran index
- `announcement_title` (String) - Announcement title
- `announcement_message` (String) - Announcement message
- `announcement_enabled` (Boolean) - Show/hide announcement

#### Analytics
- `enable_analytics` (Boolean) - Enable Firebase Analytics
- `enable_crashlytics` (Boolean) - Enable Crashlytics

#### A/B Testing
- `use_custom_html_widget` (Boolean) - Toggle HTML rendering implementation

## Usage Examples

### 1. Check Feature Flags
```dart
import 'package:saxatsavita_flutter/services/remote_config_service.dart';

final remoteConfig = RemoteConfigService();

// Check if a feature is enabled
if (remoteConfig.enableSearch) {
  // Show search button
}

if (remoteConfig.enableNotes) {
  // Show notes feature
}
```

### 2. Show Maintenance Mode
```dart
// In your main app or splash screen
import 'package:saxatsavita_flutter/components/remote_config_widgets.dart';

@override
Widget build(BuildContext context) {
  final remoteConfig = RemoteConfigService();
  
  if (remoteConfig.isMaintenanceMode) {
    return MaintenanceModeScreen();
  }
  
  return YourNormalApp();
}
```

### 3. Show Announcements
```dart
// In your home page or any screen
import 'package:saxatsavita_flutter/components/remote_config_widgets.dart';

@override
Widget build(BuildContext context) {
  return Column(
    children: [
      AnnouncementBanner(), // Automatically shows/hides based on config
      // ... rest of your UI
    ],
  );
}
```

### 4. Conditional Features
```dart
// Hide/show features based on remote config
ConditionalFeature(
  featureKey: 'enable_quotes',
  child: ElevatedButton(
    onPressed: () => openQuotesPage(),
    child: Text('Create Quote'),
  ),
  fallback: SizedBox.shrink(), // Optional: what to show if disabled
)
```

### 5. Check for Updates
```dart
// In your splash screen or home page
class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> 
    with RemoteConfigVersionCheck {
  
  @override
  void initState() {
    super.initState();
    // Check for updates on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAppVersion(context);
    });
  }
  
  // ... rest of your widget
}
```

### 6. A/B Testing
```dart
final remoteConfig = RemoteConfigService();

// Toggle between implementations
if (remoteConfig.useCustomHtmlWidget) {
  return CustomHtmlWidget(htmlContent: content);
} else {
  return HtmlToTextSpan.convertToWidgets(content, ...);
}
```

### 7. Get Custom Values
```dart
final remoteConfig = RemoteConfigService();

// Get specific values
String customMessage = remoteConfig.getString('custom_message', defaultValue: 'Hello');
bool customFlag = remoteConfig.getBool('custom_flag', defaultValue: true);
int customNumber = remoteConfig.getInt('custom_number', defaultValue: 42);
double customDouble = remoteConfig.getDouble('custom_double', defaultValue: 3.14);
```

### 8. Refresh Config Manually
```dart
final remoteConfig = RemoteConfigService();

// Fetch latest config from server
await remoteConfig.fetchConfig();
```

## Integration into Existing Pages

### Homepage (Add Announcements)
```dart
// In lib/pages/homepage.dart
import 'package:saxatsavita_flutter/components/remote_config_widgets.dart';

// Add after app bar, before main content:
Column(
  children: [
    AnnouncementBanner(),
    // ... existing content
  ],
)
```

### Settings Page (Feature Toggles)
```dart
// In lib/pages/settingspage.dart
final remoteConfig = RemoteConfigService();

// Only show setting if feature is enabled
if (remoteConfig.enableAutoScroll) {
  SwitchListTile(
    title: Text('Auto Scroll'),
    // ...
  ),
}
```

### Kiran Read Page (Feature Flags)
```dart
// In lib/pages/kiranreadpage.dart
final remoteConfig = RemoteConfigService();

// Conditionally show features
if (remoteConfig.enableBookmarks) {
  // Show bookmark button
}

if (remoteConfig.enableNotes) {
  // Show notes FAB
}

if (remoteConfig.enableAutoScroll) {
  // Show auto-scroll controls
}
```

## Testing Remote Config

### 1. Local Testing (Before Firebase Setup)
The service uses default values, so your app will work without Firebase configuration.

### 2. Firebase Console Testing
1. Add parameters in Firebase Console
2. Click "Publish changes"
3. Wait up to 1 hour for fetch (or force refresh in app)
4. Test different values

### 3. Conditions & Targeting
In Firebase Console, you can create conditions:
- Target specific users or percentages (A/B testing)
- Target specific app versions
- Target specific platforms (Android/iOS)
- Target specific regions

Example: Show announcement only to users in India:
1. Create condition: "Region equals IN"
2. Set parameter value for that condition
3. Publish changes

## Best Practices

### 1. Default Values
Always set sensible defaults in code (already done in `remote_config_service.dart`)

### 2. Fetch Interval
Current setting: Fetch at most once per hour
- Change in `RemoteConfigService.initialize()` if needed
- Use `minimumFetchInterval: Duration.zero` for development only

### 3. Version Comparison
Use semantic versioning (e.g., "2.15.0")
- Service automatically compares versions
- Can force update if below minimum version

### 4. Feature Flags
- Use feature flags for gradual rollouts
- Can quickly disable problematic features
- Test new features with small user percentage

### 5. Announcements
- Keep messages brief and clear
- Use for important updates, events, or notices
- Can be shown/hidden instantly

## Emergency Scenarios

### Scenario 1: Critical Bug Found
```json
{
  "maintenance_mode": true,
  "maintenance_message": "We're fixing a critical issue. Back in 1 hour."
}
```

### Scenario 2: Disable Broken Feature
```json
{
  "enable_auto_scroll": false
}
```

### Scenario 3: Force Update
```json
{
  "force_update_required": true,
  "minimum_supported_version": "2.16.0",
  "update_message": "Critical security update required."
}
```

### Scenario 4: Show Important Announcement
```json
{
  "announcement_enabled": true,
  "announcement_title": "📢 Important Update",
  "announcement_message": "New features available! Update to v2.16 for the best experience."
}
```

## Commands to Run

```bash
# Install dependencies
flutter pub get

# Run the app
flutter run

# Build for production
flutter build apk --release  # Android
flutter build ios --release  # iOS
```

## Monitoring

### Check Config Values (Debug)
The service automatically logs all config values on initialization. Check your debug console:
```
=== Remote Config Values ===
maintenance_mode: false (source: default)
enable_search: true (source: remote)
...
===========================
```

### Firebase Console
Monitor fetch analytics in Firebase Console → Remote Config → Analytics

## Support

For issues or questions:
1. Check Firebase Console for parameter values
2. Verify network connectivity
3. Check debug logs for Remote Config
4. Review default values in `remote_config_service.dart`

## Next Steps

1. ✅ Dependencies installed
2. ✅ Service created and initialized
3. ⏳ **Set up parameters in Firebase Console**
4. ⏳ **Integrate widgets into your pages**
5. ⏳ **Test with different parameter values**
6. ⏳ **Set up conditions for A/B testing**

Happy configuring! 🎉
