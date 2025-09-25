import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';

class Utils {
  static Color oppositeColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    final oppositeHue = (hsl.hue + 180.0) % 360.0;
    return hsl.withHue(oppositeHue).toColor();
  }

  static String getEstimatedReadingTime(int wordCount) {
    // readingSpeed: words per second
    double readingSpeed = appSettingsNotifier.value.readingSpeed / 60.0;
    final totalSeconds = (wordCount / readingSpeed).round();
    final hours = totalSeconds ~/ 3600;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours}h:${minutes % 60}m';
    }
    if (minutes > 0) {
      return '${minutes}m:${seconds}s';
    }
    return '${seconds}s';
  }
}
