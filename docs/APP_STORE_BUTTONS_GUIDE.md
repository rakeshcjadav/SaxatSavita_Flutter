# App Store Download Buttons - Usage Guide

## Overview
Reusable download button components for App Store (iOS) and Google Play Store (Android) with multiple styling options.

## Component Location
`lib/components/app_store_buttons.dart`

---

## 1. Standard App Store Buttons (Recommended)

The most common style with black buttons, white text, and store logos.

### Usage
```dart
import 'package:saxatsavita_flutter/components/app_store_buttons.dart';

// Both buttons
AppStoreButtons(
  androidUrl: 'https://play.google.com/store/apps/details?id=YOUR_PACKAGE',
  iosUrl: 'https://apps.apple.com/app/YOUR_APP/idYOUR_APP_ID',
)

// Android only
AppStoreButtons(
  androidUrl: 'https://play.google.com/store/apps/details?id=YOUR_PACKAGE',
)

// iOS only
AppStoreButtons(
  iosUrl: 'https://apps.apple.com/app/YOUR_APP/idYOUR_APP_ID',
)

// Custom button height
AppStoreButtons(
  androidUrl: 'YOUR_URL',
  iosUrl: 'YOUR_URL',
  buttonHeight: 70, // Default is 60
)
```

### Features
- ✅ Professional black buttons with white text
- ✅ Apple and Google Play logos
- ✅ Responsive wrapping on small screens
- ✅ Tap to open app store
- ✅ Customizable button height

---

## 2. Download Badges (Image-based)

Uses official App Store and Google Play badge images.

### Setup
1. Download official badges:
   - **Apple**: https://developer.apple.com/app-store/marketing/guidelines/
   - **Google**: https://play.google.com/intl/en_us/badges/

2. Place images in your project:
   ```
   assets/badges/
   ├── app_store_badge.png
   └── google_play_badge.png
   ```

3. Add to `pubspec.yaml`:
   ```yaml
   flutter:
     assets:
       - assets/badges/
   ```

### Usage
```dart
import 'package:saxatsavita_flutter/components/app_store_buttons.dart';

DownloadBadges(
  androidUrl: 'YOUR_PLAY_STORE_URL',
  iosUrl: 'YOUR_APP_STORE_URL',
)
```

### Features
- ✅ Official store badge images
- ✅ Compliant with store guidelines
- ✅ Automatic fallback to text if image missing
- ✅ Fixed 50px height

---

## 3. Branded Download Buttons

Custom-styled buttons matching your app's branding.

### Usage
```dart
import 'package:saxatsavita_flutter/components/app_store_buttons.dart';

BrandedDownloadButtons(
  androidUrl: 'YOUR_URL',
  iosUrl: 'YOUR_URL',
  backgroundColor: Colors.deepOrange,
  textColor: Colors.white,
)
```

### Features
- ✅ Customizable background color
- ✅ Customizable text color
- ✅ Vertical stacked layout
- ✅ Elevated button style with shadows

---

## Current Implementation

### Marketing Showcase Page
The download buttons are already integrated into the marketing showcase page:

**File:** `lib/pages/marketing_showcase_page.dart`

**Location:** Bottom of each feature slide

**URLs configured:**
- **Android**: `https://play.google.com/store/apps/details?id=com.saxatsavita.app`
- **iOS**: `https://apps.apple.com/app/sakshat-savita/id6738595717`

---

## Customization Examples

### Example 1: Website Landing Page
```dart
Column(
  children: [
    Text(
      'Download Sakshat Savita',
      style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
    ),
    SizedBox(height: 24),
    AppStoreButtons(
      androidUrl: 'YOUR_ANDROID_URL',
      iosUrl: 'YOUR_IOS_URL',
      buttonHeight: 70, // Larger for hero section
    ),
  ],
)
```

### Example 2: Footer Section
```dart
Container(
  padding: EdgeInsets.all(24),
  color: Colors.grey.shade900,
  child: Column(
    children: [
      Text(
        'Available on',
        style: TextStyle(color: Colors.white70),
      ),
      SizedBox(height: 16),
      AppStoreButtons(
        androidUrl: 'YOUR_URL',
        iosUrl: 'YOUR_URL',
        buttonHeight: 50, // Smaller for footer
      ),
    ],
  ),
)
```

### Example 3: Promotional Banner
```dart
Card(
  child: Padding(
    padding: EdgeInsets.all(32),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Transform Your Spiritual Reading'),
              Text('Free on iOS & Android'),
            ],
          ),
        ),
        AppStoreButtons(
          androidUrl: 'YOUR_URL',
          iosUrl: 'YOUR_URL',
        ),
      ],
    ),
  ),
)
```

### Example 4: In-App Promotion (Cross-platform)
```dart
// Show only the platform user is NOT on
import 'dart:io';

Widget buildCrossPlatformPromo() {
  if (Platform.isAndroid) {
    // Android user - show iOS button
    return AppStoreButtons(
      iosUrl: 'YOUR_IOS_URL',
    );
  } else if (Platform.isIOS) {
    // iOS user - show Android button
    return AppStoreButtons(
      androidUrl: 'YOUR_ANDROID_URL',
    );
  }
  // Web or other - show both
  return AppStoreButtons(
    androidUrl: 'YOUR_ANDROID_URL',
    iosUrl: 'YOUR_IOS_URL',
  );
}
```

---

## URL Configuration

### Finding Your App Store URLs

#### Apple App Store
Format: `https://apps.apple.com/app/APP_NAME/idAPP_ID`

**How to find:**
1. Go to App Store Connect
2. Navigate to your app
3. Copy the App ID from the App Information section
4. Your URL: `https://apps.apple.com/app/sakshat-savita/id6738595717`

**Current Sakshat Savita iOS URL:**
```
https://apps.apple.com/app/sakshat-savita/id6738595717
```

#### Google Play Store
Format: `https://play.google.com/store/apps/details?id=YOUR_PACKAGE_NAME`

**How to find:**
1. Your package name is in `android/app/build.gradle`
2. Look for `applicationId` (e.g., `com.saxatsavita.app`)
3. Your URL: `https://play.google.com/store/apps/details?id=com.saxatsavita.app`

**Current Sakshat Savita Android URL:**
```
https://play.google.com/store/apps/details?id=com.saxatsavita.app
```

---

## Testing

### Test on Simulator/Emulator
Buttons will attempt to open the app store. On simulators without app stores installed, they will fail silently.

### Test on Physical Device
1. Run app on physical iOS or Android device
2. Tap download button
3. Should open respective app store
4. If app is published, should navigate to your app listing

### Test Deep Linking (Optional)
If you want buttons to open the app if already installed:
- Use custom URL scheme: `yourapp://`
- Use universal links (iOS) or app links (Android)

---

## Best Practices

### Do's ✅
- Use official store guidelines for button design
- Test buttons on both platforms
- Provide both Android and iOS options when possible
- Make buttons clearly visible
- Use contrasting colors
- Provide adequate tap target size (min 44x44 pts)

### Don'ts ❌
- Don't use unofficial logos or trademarks
- Don't make buttons too small (< 40px height)
- Don't hide buttons or make them hard to find
- Don't use misleading text
- Don't modify official badge images

---

## Accessibility

All button components include:
- ✅ Semantic buttons (InkWell/ElevatedButton)
- ✅ Clear text labels
- ✅ Sufficient color contrast
- ✅ Minimum touch target sizes

For better accessibility, consider adding:
```dart
Semantics(
  button: true,
  label: 'Download on the App Store',
  child: AppStoreButtons(iosUrl: 'YOUR_URL'),
)
```

---

## Troubleshooting

### Buttons don't open store
**Issue:** url_launcher not configured
**Solution:** 
```yaml
# pubspec.yaml
dependencies:
  url_launcher: ^6.3.2
```

### Buttons show but URLs are wrong
**Issue:** Hardcoded URLs need updating
**Solution:** Update URLs in the component where you use it

### Images don't load (DownloadBadges)
**Issue:** Badge images not in assets
**Solution:**
1. Download official badges
2. Place in `assets/badges/`
3. Update `pubspec.yaml`
4. Run `flutter pub get`

### Buttons look different on web
**Issue:** Web may have different rendering
**Solution:** Test and adjust styles specifically for web if needed

---

## Advanced: Dynamic URLs from Config

For apps that need different URLs per environment:

```dart
class AppConfig {
  static const String androidStoreUrl = String.fromEnvironment(
    'ANDROID_URL',
    defaultValue: 'https://play.google.com/store/apps/details?id=com.saxatsavita.app',
  );
  
  static const String iosStoreUrl = String.fromEnvironment(
    'IOS_URL',
    defaultValue: 'https://apps.apple.com/app/sakshat-savita/id6738595717',
  );
}

// Usage
AppStoreButtons(
  androidUrl: AppConfig.androidStoreUrl,
  iosUrl: AppConfig.iosStoreUrl,
)
```

---

## Marketing Materials

Use these buttons in:
- ✅ Marketing showcase page (already implemented!)
- ✅ Landing pages
- ✅ Email signatures
- ✅ Social media bios
- ✅ Blog posts
- ✅ Press releases
- ✅ Promotional materials
- ✅ In-app cross-promotion

---

## Store Guidelines Compliance

### Apple App Store
- Use official "Download on the App Store" badge
- Don't modify the badge
- Minimum clear space around badge
- Don't use Apple logo separately
- Full guidelines: https://developer.apple.com/app-store/marketing/guidelines/

### Google Play Store
- Use official "Get it on Google Play" badge
- Don't modify colors or design
- Maintain aspect ratio
- Use provided badge images
- Full guidelines: https://play.google.com/intl/en_us/badges/

---

## Quick Reference

| Component | Use Case | Style | Customizable |
|-----------|----------|-------|-------------|
| `AppStoreButtons` | General use | Black buttons | Height |
| `DownloadBadges` | Official look | Badge images | None |
| `BrandedDownloadButtons` | Custom branding | App colors | Colors |

**Most Recommended:** `AppStoreButtons` - Best balance of professional appearance and flexibility.

---

## Need Help?

- Check component file: `lib/components/app_store_buttons.dart`
- See implementation: `lib/pages/marketing_showcase_page.dart`
- url_launcher docs: https://pub.dev/packages/url_launcher
