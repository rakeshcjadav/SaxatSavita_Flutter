import 'package:flutter/material.dart';

class AppSettings {
  double fontSize;
  double lineHeight;
  Color themeColor;
  DynamicSchemeVariant themeVariant = DynamicSchemeVariant.neutral;
  double themeContrastLevel;
  double readingSpeed;
  String language;

  AppSettings({
    required this.fontSize,
    required this.lineHeight,
    required this.themeColor,
    required this.themeVariant,
    required this.themeContrastLevel,
    required this.readingSpeed,
    required this.language,
  });
}

ValueNotifier<AppSettings> appSettingsNotifier = ValueNotifier<AppSettings>(
  AppSettings(
    fontSize: 16,
    lineHeight: 2.0,
    themeColor: Colors.deepOrange,
    themeVariant: DynamicSchemeVariant.neutral,
    themeContrastLevel: 1.0,
    readingSpeed: 300.0,
    language: 'gu',
  ),
);
