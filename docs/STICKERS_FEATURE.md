# Stickers Feature - Quotes Image Generator

## Overview

The stickers feature allows users to add decorative PNG images (stickers) to their quote images. Users can position, resize, rotate, and remove stickers to create personalized quote graphics.

## User Experience

### Adding Stickers

1. Open the Quotes Image Generator page
2. Navigate to the "Stickers" tab in the customization section
3. Tap any sticker from the grid to add it to your quote image
4. The sticker will appear in the center of the image

### Managing Stickers

Each sticker has three control handles:

- **Red X (Top Right)**: Remove the sticker
- **Blue Rotate (Bottom Left)**: Drag to rotate the sticker
- **Orange Resize (Bottom Right)**: Drag to resize the sticker

### Moving Stickers

- Tap and drag anywhere on the sticker to move it
- The sticker will stay within the image bounds

## Technical Implementation

### Data Structure

```dart
class StickerData {
  String assetPath;      // Path to the PNG asset
  Offset position;       // X, Y position on the image
  double size;          // Width/height (stickers are square)
  double rotation;      // Rotation angle in radians
}
```

### Key Components

1. **Sticker State**: `List<StickerData> _stickers` stores all active stickers
2. **Sticker Tab**: Grid view of available stickers in customization section
3. **Sticker Overlay**: Positioned widgets in the Stack that overlay the quote image
4. **Gesture Handlers**: Pan gestures for drag, resize, and rotate operations

### File Structure

```
assets/
  stickers/
    om.png
    lotus.png
    diya.png
    mandala.png
    flower.png
    star.png
    heart.png
    sparkle.png
    README.md
```

## Adding New Stickers

### Step 1: Add PNG File

Place your PNG file in `assets/stickers/`. Recommended specifications:
- Format: PNG with transparency
- Size: 512x512 pixels
- File size: < 100KB

### Step 2: Update Sticker List

In `quotes_image_generator_page.dart`, add your sticker to the `_availableStickers` list:

```dart
final List<String> _availableStickers = [
  'assets/stickers/om.png',
  'assets/stickers/lotus.png',
  // ... existing stickers
  'assets/stickers/your_new_sticker.png',  // Add here
];
```

### Step 3: Rebuild

Run `flutter pub get` and rebuild the app.

## Feature Capabilities

### Current Features ✅

- Add multiple stickers to a quote
- Drag to reposition stickers
- Resize stickers (30px to 150px)
- Rotate stickers freely
- Remove individual stickers
- Stickers are saved in the final image export
- Stickers work with all quote templates

### Sticker Controls

| Control | Icon | Color | Function |
|---------|------|-------|----------|
| Remove | ❌ | Red | Delete the sticker |
| Resize | ⤢ | Orange | Scale up/down |
| Rotate | ↻ | Blue | Rotate clockwise/counter-clockwise |
| Move | (drag sticker) | - | Reposition anywhere |

### Constraints

- **Size limits**: 30px (minimum) to 150px (maximum)
- **Boundary**: Stickers cannot be dragged outside image bounds
- **Layer order**: Stickers appear above quote text
- **Number**: No limit on sticker count

## Best Practices

### For Designers

1. **Transparent backgrounds**: Always use PNG with alpha channel
2. **Center-aligned artwork**: Design content centered in canvas
3. **Consistent style**: Match stickers to the spiritual/Gujarati theme
4. **Simple shapes**: Complex designs may not scale well at small sizes

### For Users

1. **Don't overcrowd**: Use 2-4 stickers maximum for best results
2. **Size appropriately**: Smaller stickers (50-80px) work best
3. **Corner placement**: Place decorative elements in corners
4. **Balance**: Distribute stickers evenly for visual harmony

## Performance Considerations

### Optimization

- Stickers are loaded on-demand using `FutureBuilder`
- Fallback icon shown if asset fails to load
- Grid view uses efficient `GridView.builder`
- Image caching handled by Flutter's asset system

### Memory

- Each sticker adds ~10-50KB to memory (depending on PNG size)
- No practical limit on sticker count in normal usage
- Large images (> 1MB) should be compressed before adding

## Troubleshooting

### Sticker Not Appearing

1. Check file path in `_availableStickers` list
2. Verify PNG file exists in `assets/stickers/`
3. Ensure `pubspec.yaml` includes `- assets/stickers/`
4. Run `flutter pub get` after adding new assets

### Controls Not Working

- Controls require sufficient space around sticker
- Very small stickers (< 40px) may have hard-to-tap controls
- Try resizing sticker larger first

### Sticker Disappears After Rotation

- This shouldn't happen - check for state management issues
- Ensure `setState()` is called after rotation update

## Future Enhancements

### Potential Additions

1. **Custom sticker upload**: Allow users to upload their own images
2. **Sticker categories**: Organize stickers by theme (flowers, symbols, etc.)
3. **Layer ordering**: Z-index control to change which sticker appears on top
4. **Flip horizontally/vertically**: Mirror stickers
5. **Opacity control**: Semi-transparent stickers
6. **Lock position**: Prevent accidental movement
7. **Duplicate sticker**: Quick copy of existing sticker
8. **Sticker templates**: Pre-arranged sticker layouts
9. **Search/filter**: Find stickers by keyword
10. **Favorites**: Mark frequently used stickers

### Advanced Features

- **Multi-select**: Move/resize multiple stickers at once
- **Alignment guides**: Snap to center, edges, or other stickers
- **Undo/redo**: Revert sticker operations
- **Save presets**: Remember favorite sticker arrangements
- **Animated stickers**: GIF or Lottie animations (requires significant changes)

## Code Architecture

### Key Methods

```dart
// Add a new sticker at center
void _addSticker(String stickerPath)

// Remove sticker by index
void _removeSticker(int index)

// Check if asset file exists
Future<bool> _checkAssetExists(String path)

// Build stickers tab UI
Widget _buildStickersTab()

// Overlay stickers on quote image (in Stack)
..._stickers.asMap().entries.map((entry) => Positioned(...))
```

### State Management

Stickers use simple `setState()` for immediate UI updates:
- Position changes
- Size adjustments
- Rotation updates
- Add/remove operations

No need for complex state management as stickers are page-local.

## Testing

### Manual Testing Checklist

- [ ] Add sticker from grid
- [ ] Drag sticker to new position
- [ ] Resize sticker larger and smaller
- [ ] Rotate sticker clockwise and counter-clockwise
- [ ] Remove sticker via X button
- [ ] Add multiple stickers simultaneously
- [ ] Export image with stickers (share/download)
- [ ] Stickers persist when changing template
- [ ] Stickers work with all color gradients
- [ ] Boundary constraints prevent stickers leaving image

### Edge Cases

- Adding stickers to very small image sizes (< 300px)
- Adding many stickers (10+)
- Rotating sticker multiple full rotations
- Rapid resize/rotate gestures
- Switching templates with active stickers

## Accessibility

### Current Limitations

- Sticker controls may be difficult for users with motor impairments
- No keyboard/screen reader support for sticker manipulation
- Small touch targets (24x24px controls)

### Improvements Needed

- Larger touch targets (48x48px)
- Keyboard shortcuts for sticker operations
- Voice control integration
- Haptic feedback on sticker interactions
- Alternative text descriptions for stickers

## Localization

### Current State

- "Stickers" tab label is hardcoded in English
- Sticker filenames are not localized

### To Localize

Add to `app_localizations.dart`:

```dart
String get tab_stickers => 'Stickers'; // English
String get tap_sticker_to_add => 'Tap a sticker to add it';
```

Add translations in language files:
- `app_localizations_en.dart`: English
- `app_localizations_gu.dart`: ગુજરાતી (Gujarati)

## Integration with Existing Features

### Compatible Features

- ✅ All quote templates (0-11)
- ✅ All color gradients
- ✅ Font size adjustments
- ✅ Image size adjustments
- ✅ User avatar/name display
- ✅ Share functionality
- ✅ Download/save functionality
- ✅ Predefined quotes

### Sticker Rendering

Stickers are captured in the `RepaintBoundary` along with:
- Background gradient
- Template patterns
- Quote text
- Author attribution
- User info (if enabled)

When sharing or downloading, stickers are part of the final PNG export.

## API Reference

### StickerData Class

```dart
class StickerData {
  String assetPath;   // Required: path to PNG asset
  Offset position;    // Required: X,Y coordinates
  double size;        // Optional: defaults to 60.0
  double rotation;    // Optional: defaults to 0.0 (radians)
}
```

### Adding Stickers Programmatically

```dart
// Add sticker at specific position
_stickers.add(
  StickerData(
    assetPath: 'assets/stickers/om.png',
    position: Offset(100, 100),
    size: 80.0,
    rotation: 0.5,  // ~30 degrees
  ),
);
setState(() {});
```

### Sticker Constraints

```dart
// Size constraints
const double minStickerSize = 30.0;
const double maxStickerSize = 150.0;

// Position constraints (automatic)
// Stickers clamped to: 0 <= x <= imageWidth - stickerSize
//                      0 <= y <= imageHeight - stickerSize
```

## Credits

Feature designed and implemented for Sakshat Savita app.

Sticker placeholders should be replaced with proper spiritual/Gujarati themed PNG images from licensed sources.
