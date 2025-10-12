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

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      fontSize: json['fontSize']?.toDouble() ?? 18.0,
      lineHeight: json['lineHeight']?.toDouble() ?? 2.0,
      themeColor: Color(json['themeColor'] ?? Colors.deepOrange.value),
      themeVariant: _parseThemeVariant(json['themeVariant']),
      brightness:
          json['brightness'] == 'dark' ? Brightness.dark : Brightness.light,
      themeContrastLevel: json['themeContrastLevel']?.toDouble() ?? 0.5,
      readingSpeed: json['readingSpeed']?.toDouble() ?? 300.0,
      language: json['language'] ?? 'gu',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'lineHeight': lineHeight,
      'themeColor': themeColor.value,
      'themeVariant': themeVariant.name,
      'brightness': brightness.name,
      'themeContrastLevel': themeContrastLevel,
      'readingSpeed': readingSpeed,
      'language': language,
    };
  }

  static DynamicSchemeVariant _parseThemeVariant(String? variant) {
    switch (variant) {
      case 'fruitSalad':
        return DynamicSchemeVariant.fruitSalad;
      case 'rainbow':
        return DynamicSchemeVariant.rainbow;
      case 'content':
        return DynamicSchemeVariant.content;
      case 'expressive':
        return DynamicSchemeVariant.expressive;
      case 'vibrant':
        return DynamicSchemeVariant.vibrant;
      case 'neutral':
        return DynamicSchemeVariant.neutral;
      case 'monochrome':
        return DynamicSchemeVariant.monochrome;
      case 'fidelity':
        return DynamicSchemeVariant.fidelity;
      default:
        return DynamicSchemeVariant.tonalSpot;
    }
  }
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

AppSettings appSettingsDefault = AppSettings(
  fontSize: 18,
  lineHeight: 2.0,
  themeColor: Colors.deepOrange,
  themeVariant: DynamicSchemeVariant.tonalSpot,
  brightness: Brightness.light,
  themeContrastLevel: 0.5,
  readingSpeed: 300.0,
  language: 'gu',
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
