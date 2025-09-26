import 'package:flutter/material.dart';

class AppSettings {
  double fontSize;
  double lineHeight;
  Color themeColor;
  DynamicSchemeVariant themeVariant = DynamicSchemeVariant.neutral;
  Brightness brightness = Brightness.light;
  double themeContrastLevel;
  double readingSpeed;
  String language;

  AppSettings({
    required this.fontSize,
    required this.lineHeight,
    required this.themeColor,
    required this.themeVariant,
    required this.brightness,
    required this.themeContrastLevel,
    required this.readingSpeed,
    required this.language,
  });
}

ValueNotifier<AppSettings> appSettingsNotifier = ValueNotifier<AppSettings>(
  AppSettings(
    fontSize: 18,
    lineHeight: 2.0,
    themeColor: Colors.deepOrange,
    themeVariant: DynamicSchemeVariant.tonalSpot,
    brightness: Brightness.light,
    themeContrastLevel: 0.5,
    readingSpeed: 300.0,
    language: 'gu',
  ),
);

AppSettings copyAppSettings(
  AppSettings settings, {
  double? fontSize,
  double? lineHeight,
  Color? themeColor,
  DynamicSchemeVariant? themeVariant,
  Brightness? brightness,
  double? themeContrastLevel,
  double? readingSpeed,
  String? language,
}) {
  return AppSettings(
    fontSize: fontSize ?? settings.fontSize,
    lineHeight: lineHeight ?? settings.lineHeight,
    themeColor: themeColor ?? settings.themeColor,
    themeVariant: themeVariant ?? settings.themeVariant,
    brightness: brightness ?? settings.brightness,
    themeContrastLevel: themeContrastLevel ?? settings.themeContrastLevel,
    readingSpeed: readingSpeed ?? settings.readingSpeed,
    language: language ?? settings.language,
  );
}
