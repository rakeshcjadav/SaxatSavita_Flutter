# Marketing Showcase Page - Play Store Screenshots Guide

## Overview
The `MarketingShowcasePage` is a dedicated page designed for creating beautiful Play Store screenshots showcasing your app's features. It displays features in a swipeable carousel format with icons, titles, descriptions, and rounded screenshots.

## How to Access

### From Code
Navigate to the page programmatically:
```dart
Navigator.pushNamed(context, '/marketing_showcase');
```

### For Screenshots
1. Run your app on a device or simulator
2. Navigate to `/marketing_showcase` route
3. Each swipe shows a new feature slide
4. Take screenshots of each slide for your Play Store listing

## Taking Screenshots

### On iPad/iOS
1. Run the app: `flutter run -d <device-id>`
2. Navigate to the marketing showcase page
3. Swipe through each feature slide
4. Press **Cmd + S** (Simulator) or **Power + Volume Up** (Device) to capture screenshots
5. Screenshots will be saved to Desktop (Simulator) or Photos (Device)

### On Android
1. Run the app: `flutter run -d <device-id>`
2. Navigate to the marketing showcase page
3. Swipe through each feature slide
4. Press **Power + Volume Down** to capture screenshots
5. Find screenshots in your device's Screenshots folder

### Recommended Screenshot Sizes
- **iOS App Store**: 1290 x 2796 (6.7" iPhone) or 2048 x 2732 (12.9" iPad)
- **Google Play Store**: 1080 x 1920 or higher

## Customizing Feature Slides

The page currently includes 8 feature slides:

1. **Sakshat Savita** - Main spiritual reading feature
2. **Reading Plans** - Custom reading plans with progress tracking
3. **Aashirvachan** - Blessings and teachings
4. **Search** - Search functionality
5. **Notes** - Note-taking capabilities
6. **Bookmarks** - Save favorite passages
7. **Information** - Detailed spiritual information
8. **Feedback** - User feedback feature

### To Add/Edit Feature Slides

Open `lib/pages/marketing_showcase_page.dart` and modify the `features` list:

```dart
FeatureSlide(
  icon: Icons.your_icon,           // Material icon
  iconColor: Colors.yourColor,      // Icon and accent color
  title: 'Feature Title',           // Feature name
  description: 'Feature description that explains what users can do.',
  imagePath: 'assets/res/your_screenshot.webp',  // Path to screenshot
  backgroundColor: Colors.yourColor.shade50,  // Light background
),
```

### Adding Real Screenshots

1. **Take actual app screenshots** of each feature in action
2. **Save them** to `assets/res/` folder (e.g., `screenshot_reading_plan.png`)
3. **Update imagePath** in the feature slide:
   ```dart
   imagePath: 'assets/res/screenshot_reading_plan.png',
   ```
4. **Add to pubspec.yaml** if needed (assets/res/ folder should already be included)

### Placeholder Behavior
If a screenshot image is missing, the page will show a placeholder with:
- The feature icon (faded)
- "Screenshot Placeholder" text
- Colored background matching the feature theme

## Layout Features

### Design Elements
- **Circular Icon Badge**: 120x120 with gradient shadow
- **Large Title**: 32px bold, centered
- **Description**: 18px, gray, up to 4 lines
- **Rounded Screenshot**: 400px height with 24px border radius and shadow
- **Page Indicator**: Dots at bottom showing current slide
- **Smooth PageView**: Swipe horizontally between features

### Colors
Each feature has a unique color theme:
- Orange: Sakshat Savita
- Blue: Reading Plans
- Purple: Aashirvachan
- Green: Search
- Amber: Notes
- Teal: Bookmarks
- Indigo: Information
- Pink: Feedback

## Tips for Best Screenshots

1. **Use Light Mode**: Screenshots typically look better in light theme for store listings
2. **Show Real Data**: Display actual content, not placeholder text
3. **Clean State**: Remove debugging info, test accounts, or Lorem ipsum
4. **Consistent Sizing**: Take all screenshots on the same device for uniform dimensions
5. **Landscape Support**: Consider iPad landscape screenshots for tablet section
6. **Localization**: If targeting multiple languages, take screenshots for each locale

## Updating Descriptions

To change feature descriptions without touching localization files:
- Descriptions are currently hardcoded in English
- For localized versions, replace strings with `loc.your_key`
- Add corresponding keys to `lib/l10n/app_localizations_*.arb`

## Testing

Run on your device to preview:
```bash
flutter run -d <device-id>
```

Then navigate to:
```dart
Navigator.pushNamed(context, '/marketing_showcase');
```

## Store Listing Recommendations

### Google Play Store
- Upload 2-8 screenshots per feature
- Minimum 2 screenshots required
- Max file size: 8 MB per screenshot
- Supported formats: PNG or JPEG

### Apple App Store
- Provide screenshots for each device size you support
- 6.7" iPhone: 1290 x 2796 or 2796 x 1290
- 12.9" iPad: 2048 x 2732 or 2732 x 2048
- Max file size: 500 MB (typically under 1 MB for screenshots)

## Notes

- The page uses existing app icons from `assets/res/z_icon_*.webp`
- All Material Icons are available without additional setup
- PageView provides smooth horizontal scrolling
- Page indicators automatically update based on current slide
- Safe for both iOS and Android without platform-specific code
