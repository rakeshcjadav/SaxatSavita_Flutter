import 'package:flutter/material.dart';

class AppSettings {
  double fontSize;
  Color themeColor;
  double readingSpeed;
  String language;

  AppSettings({
    required this.fontSize,
    required this.themeColor,
    required this.readingSpeed,
    required this.language,
  });
}

ValueNotifier<AppSettings> appSettingsNotifier = ValueNotifier<AppSettings>(
  AppSettings(
    fontSize: 16,
    themeColor: Colors.brown,
    readingSpeed: 1.0,
    language: 'gu',
  ),
);
