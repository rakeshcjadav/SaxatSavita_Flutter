# iOS Widget Extension Setup Guide

This guide explains how the iOS Widget Extension for Sakshat Savita is configured and how to test it.

## Overview

The iOS widget extension displays the user's reading progress on their home screen, showing:
- Daily reading time progress (completed vs target minutes)
- Number of Kirans read (completed vs target)
- Current reading streak
- Visual progress bar

## Widget Extension Structure

```
ios/
├── Runner/                          # Main app
│   ├── Info.plist                  # Contains saxatsavita:// URL scheme
│   └── Runner.entitlements         # Contains App Groups capability
│
└── SakshatSavitaWidgets/           # Widget Extension
    ├── ReadingProgressWidget.swift # Main widget implementation
    ├── SakshatSavitaWidgetsBundle.swift # Widget bundle registration
    ├── WidgetConfiguration.swift   # Configuration documentation
    ├── Info.plist                  # Widget extension metadata
    └── Assets.xcassets/            # Widget assets
```

## Configuration Details

### 1. App Groups

Both the main app and widget extension share data via App Groups:
- **App Group ID**: `group.com.saxatsavita.flutter.widgets`
- **Configured in**: 
  - `ios/Runner/Runner.entitlements`
  - `ios/SakshatSavitaWidgetsExtension.entitlements`

### 2. URL Scheme

The widget uses deep linking to open the app when tapped:
- **URL Scheme**: `saxatsavita://`
- **Widget Action**: `saxatsavita://widget/viewProgress`
- **Configured in**: `ios/Runner/Info.plist`

### 3. Widget Timeline

- **Refresh Policy**: Every 15 minutes
- **Data Source**: UserDefaults shared suite (`group.com.saxatsavita.flutter.widgets`)
- **Update Trigger**: When the Flutter app calls `HomeWidget.updateWidget()`

## Data Flow

```
Flutter App (home_widget_service.dart)
    ↓
    Saves data to UserDefaults with App Group
    ↓
    Calls HomeWidget.updateWidget()
    ↓
iOS Widget Extension (ReadingProgressWidget.swift)
    ↓
    Reads data from shared UserDefaults
    ↓
    Displays in widget UI
```

## Data Keys

The widget reads the following keys from shared UserDefaults:

| Key | Type | Description |
|-----|------|-------------|
| `daily_target_minutes` | Int | Target reading time in minutes |
| `completed_minutes` | Int | Completed reading time in minutes |
| `target_kirans` | Int | Target number of Kirans to read |
| `completed_kirans` | Int | Number of Kirans completed |
| `progress_percentage` | Double | Overall progress percentage (0-100) |
| `streak_days` | String | Reading streak (e.g., "7 days") |

## Testing the Widget

### Prerequisites
- Xcode 15.0 or later
- iOS 16.0 or later device/simulator
- Valid Apple Developer account for signing

### Steps to Test

1. **Build the App in Xcode**
   ```bash
   cd ios
   open Runner.xcworkspace
   ```

2. **Verify Code Signing**
   - Select the `Runner` target
   - Go to "Signing & Capabilities"
   - Ensure automatic signing is enabled
   - Verify "App Groups" capability is present with `group.com.saxatsavita.flutter.widgets`
   - Repeat for `SakshatSavitaWidgetsExtension` target

3. **Build and Run**
   - Select a simulator or device (iOS 16+)
   - Build and run the app
   - The app should launch successfully

4. **Add Widget to Home Screen**
   - Long press on the home screen
   - Tap the "+" button in the top left
   - Search for "Sakshat Savita"
   - You should see "Reading Progress" widget
   - Select it and choose a size (Medium or Large)
   - Tap "Add Widget"

5. **Test Widget Updates**
   - Open the app
   - Read some content to generate progress data
   - Return to home screen
   - Widget should update with current progress

6. **Test Widget Interaction**
   - Tap on the widget
   - App should open to the progress view

### Troubleshooting

#### Widget Not Appearing in Gallery
- Check that both targets (Runner and SakshatSavitaWidgetsExtension) are signed
- Verify bundle ID hierarchy: widget should be `com.saxatsavita.flutter.SakshatSavitaWidgets`
- Rebuild the app completely

#### Widget Shows No Data
- Check App Groups configuration in both targets
- Verify the group ID matches exactly: `group.com.saxatsavita.flutter.widgets`
- Ensure the Flutter app has called `HomeWidget.saveWidgetData()` before updating

#### Widget Not Updating
- Check that the Flutter app is calling `HomeWidget.updateWidget()`
- Verify the widget extension is included in the build
- Try removing and re-adding the widget

#### Signing Errors
- Enable automatic signing in both targets
- Ensure your Apple Developer account is active
- Check that all capabilities are properly synced

## Widget Sizes

The widget supports two sizes:

### Medium (2x2 grid)
- Shows reading time progress
- Shows Kirans progress
- Shows streak
- Compact layout

### Large (4x2 grid)
- Same information as Medium
- More spacious layout
- Better readability

## Customization

### Changing Widget Colors

Edit the gradient colors in `ReadingProgressWidget.swift`:

```swift
LinearGradient(
    gradient: Gradient(colors: [
        Color(red: 0.1, green: 0.14, blue: 0.49),  // Top color
        Color(red: 0.16, green: 0.21, blue: 0.58), // Middle color
        Color(red: 0.22, green: 0.29, blue: 0.67)  // Bottom color
    ]),
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

### Changing Refresh Interval

Edit the timeline policy in `ReadingProgressWidget.swift`:

```swift
// Current: Refresh every 15 minutes
let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
let timeline = Timeline(entries: entries, policy: .after(refreshDate))
```

### Adding New Data Fields

1. Save data in Flutter (`home_widget_service.dart`):
   ```dart
   await HomeWidget.saveWidgetData<String>('new_field', value);
   ```

2. Read in Swift (`ReadingProgressWidget.swift`):
   ```swift
   let newField = userDefaults?.string(forKey: "new_field") ?? "default"
   ```

3. Add to entry struct and display in UI

## Distribution

When distributing to App Store:

1. Ensure both targets are included in the build
2. Test on real devices, not just simulator
3. Create widget preview screenshots
4. Update app description to mention widget feature
5. Verify all capabilities are properly configured in App Store Connect

## References

- [WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [home_widget Flutter Package](https://pub.dev/packages/home_widget)
- [App Groups Documentation](https://developer.apple.com/documentation/security/keychain_services/keychain_items/sharing_access_to_keychain_items_among_a_collection_of_apps)
