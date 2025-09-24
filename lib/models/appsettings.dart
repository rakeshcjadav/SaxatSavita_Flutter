import 'package:flutter/material.dart';

class AppSettings {
  double fontSize;
  Color themeColor;
  double themeContrastLevel;
  double readingSpeed;
  String language;

  AppSettings({
    required this.fontSize,
    required this.themeColor,
    required this.themeContrastLevel,
    required this.readingSpeed,
    required this.language,
  });
}

ValueNotifier<AppSettings> appSettingsNotifier = ValueNotifier<AppSettings>(
  AppSettings(
    fontSize: 16,
    themeColor: Colors.brown,
    themeContrastLevel: 1.0,
    readingSpeed: 1.0,
    language: 'gu',
  ),
);
