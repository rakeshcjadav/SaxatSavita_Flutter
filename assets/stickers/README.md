# Stickers for Quotes Image Generator

This directory contains PNG sticker images that users can add to their quote images.

## Current Stickers

Replace the placeholder files with actual PNG images:

1. **om.png** - Om symbol (ૐ)
2. **lotus.png** - Lotus flower
3. **diya.png** - Diya/lamp
4. **mandala.png** - Mandala pattern
5. **flower.png** - Decorative flower
6. **star.png** - Star decoration
7. **heart.png** - Heart shape
8. **sparkle.png** - Sparkle/shine effect

## Image Requirements

- **Format**: PNG with transparent background
- **Recommended Size**: 512x512 pixels (will be scaled automatically)
- **File Size**: Keep under 100KB each for performance
- **Style**: Should work well on various colored backgrounds

## Adding New Stickers

1. Add your PNG file to this directory
2. Update the `_availableStickers` list in `quotes_image_generator_page.dart`:
   ```dart
   final List<String> _availableStickers = [
     'assets/stickers/om.png',
     'assets/stickers/lotus.png',
     // Add your new sticker here
     'assets/stickers/your_new_sticker.png',
   ];
   ```

## Finding Sticker Images

You can find free PNG stickers from:
- **Flaticon**: https://www.flaticon.com/
- **Icons8**: https://icons8.com/
- **Pngtree**: https://pngtree.com/
- **Freepik**: https://www.freepik.com/

Make sure to check licensing requirements for commercial use.

## Gujarati/Spiritual Themes

Consider adding stickers related to:
- Religious symbols (Om, Swastik, etc.)
- Flowers (Lotus, Marigold, Jasmine)
- Lamps and diyas
- Peacock feathers
- Mandalas
- Stars and decorative elements
- Traditional Indian patterns
