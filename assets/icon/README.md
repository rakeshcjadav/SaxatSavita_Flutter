# 📱 App Icon Generation Guide

This guide will help you create beautiful app icons for Sakshaat Savita using your spiritual guru image.

## 🎯 Quick Setup

### Step 1: Save Your Image
Save your spiritual guru image (the one you shared) as:
```
assets/icon/source_image.png   # Preferred
assets/icon/source_image.jpg   # Alternative  
assets/icon/source_image.webp  # Modern format (requires ImageMagick)
```

**Requirements:**
- Size: At least 1024x1024 pixels
- Format: PNG (preferred), JPG, or WebP
- Square aspect ratio (1:1)

### Step 2: Generate Icons
```bash
# Install dependencies
flutter pub get

# Run the icon generator script
./scripts/generate_icons.sh

# Generate the actual app icons
dart run flutter_launcher_icons
```

### Step 3: Test
```bash
flutter clean
flutter run
```

## 🖼️ Icon Specifications

### Main App Icon (`app_icon.png`)
- **Size**: 1024x1024 pixels
- **Usage**: Primary app icon for iOS and Android
- **Format**: PNG with transparency support

### Adaptive Icon Foreground (`app_icon_foreground.png`)
- **Size**: 1024x1024 pixels (with 80px safe area)
- **Usage**: Android adaptive icon foreground
- **Background**: Transparent
- **Safe Area**: Content within 864x864 center area

### Adaptive Icon Background
- **Color**: `#FF5722` (Deep Orange - spiritual saffron color)
- **Usage**: Android adaptive icon background
- **Theme**: Matches the spiritual saffron/orange theme

## 🎨 Design Considerations

### Spiritual Theme
- **Colors**: Saffron/orange theme (`#FF5722`)
- **Subject**: Spiritual guru in meditation pose
- **Background**: Golden temple architecture
- **Symbolism**: Divine light and spiritual wisdom

### Technical Aspects
- **Visibility**: High contrast for small sizes
- **Scalability**: Works from 16x16 to 1024x1024
- **Platform Compliance**: Follows iOS and Android guidelines
- **Adaptive Support**: Looks good on various background shapes

## 📁 Generated Files

After running the generation process, you'll have:

```
assets/icon/
├── source_image.png          # Your original image
├── app_icon.png             # Main app icon (1024x1024)
├── app_icon_foreground.png  # Adaptive foreground (1024x1024)
└── preview.html             # Preview of generated icons
```

## 🔧 Configuration

The icon configuration in `pubspec.yaml`:

```yaml
flutter_launcher_icons:
  android: "launcher_icon"
  ios: true
  image_path: "assets/icon/app_icon.png"
  adaptive_icon_background: "#FF5722"
  adaptive_icon_foreground: "assets/icon/app_icon_foreground.png"
  min_sdk_android: 21
```

## 🚀 Platform-Specific Results

### iOS
- **App Icon**: Rounded square with your spiritual guru image
- **Sizes**: Automatically generates all required iOS icon sizes
- **Location**: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

### Android
- **Standard Icon**: Traditional app icon
- **Adaptive Icon**: Modern Android adaptive icon with:
  - Foreground: Your guru image
  - Background: Saffron color
- **Location**: `android/app/src/main/res/mipmap-*/`

## 🎭 Preview

Open `assets/icon/preview.html` in your browser to see how your icons will look on different devices.

## ✨ Tips

1. **High Quality**: Start with the highest quality image possible
2. **Square Format**: Ensure your image is perfectly square
3. **Safe Area**: For adaptive icons, keep important content in the center 80%
4. **Testing**: Test on both light and dark device themes
5. **Branding**: The saffron background reinforces your spiritual app branding

## 🙏 Spiritual Significance

The chosen design elements have deep spiritual meaning:
- **Saffron Color**: Represents renunciation, wisdom, and spiritual knowledge
- **Guru Image**: Central figure representing spiritual guidance
- **Golden Light**: Divine illumination and enlightenment
- **Temple Architecture**: Sacred space and spiritual tradition

---

**May this app icon bring divine blessings and spiritual guidance to all users! 🕉️**