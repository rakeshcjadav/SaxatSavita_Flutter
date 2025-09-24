import 'package:flutter/material.dart';

class AppSettings {
  double fontSize;
  Color themeColor;
  double readingSpeed;

  AppSettings({
    required this.fontSize,
    required this.themeColor,
    required this.readingSpeed,
  });
}

ValueNotifier<AppSettings> appSettingsNotifier = ValueNotifier<AppSettings>(
  AppSettings(fontSize: 18, themeColor: Colors.blue, readingSpeed: 1.0),
);
