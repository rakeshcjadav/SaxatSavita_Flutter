import 'package:flutter/material.dart';

class AppSettings {
  double fontSize;
  double appFontSize;
  double lineHeight;
  Color themeColor;
  DynamicSchemeVariant themeVariant = DynamicSchemeVariant.neutral;
  Brightness brightness = Brightness.light;
  double themeContrastLevel;
  double readingSpeed;
  String language;
  bool keepScreenOn;
  bool showEdgeNavButtons;
  double edgePadding;
  bool useColorfulPartStyle;
  bool ttsEnabled;
  double ttsSpeechRate;
  String? ttsVoice; // stored as "name|locale"

  static const double maxAppFontSize = 25.0;
  static const double minAppFontSize = 15.0;

  AppSettings({
    required this.fontSize,
    required double appFontSize,
    required this.lineHeight,
    required this.themeColor,
    required this.themeVariant,
    required this.brightness,
    required this.themeContrastLevel,
    required this.readingSpeed,
    required this.language,
    required this.keepScreenOn,
    required this.showEdgeNavButtons,
    required this.edgePadding,
    required this.useColorfulPartStyle,
    required this.ttsEnabled,
    required this.ttsSpeechRate,
    this.ttsVoice,
  }) : appFontSize = appFontSize
           .clamp(minAppFontSize, maxAppFontSize)
           .toDouble();

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    try {
      return AppSettings(
        fontSize: _readDouble(json['fontSize'], 18.0),
        appFontSize: _parseAppFontSize(json),
        lineHeight: _readDouble(json['lineHeight'], 2.0),
        themeColor: Color(
          json['themeColor'] is num
              ? (json['themeColor'] as num).toInt()
              : Colors.deepOrange.toARGB32(),
        ),
        themeVariant: _parseThemeVariant(json['themeVariant']),
        brightness:
            json['brightness'] == 'dark' ? Brightness.dark : Brightness.light,
        themeContrastLevel: _readDouble(json['themeContrastLevel'], 0.5),
        readingSpeed: _readDouble(json['readingSpeed'], 200.0),
        language:
            json['language'] is String ? json['language'] as String : 'gu',
        keepScreenOn: json['keepScreenOn'] == true,
        showEdgeNavButtons: json['showEdgeNavButtons'] != false,
        edgePadding: _readDouble(json['edgePadding'], 16.0),
        useColorfulPartStyle: json['useColorfulPartStyle'] == true,
        ttsEnabled: json['ttsEnabled'] == true,
        ttsSpeechRate: _readDouble(json['ttsSpeechRate'], 0.5),
        ttsVoice: json['ttsVoice'] is String ? json['ttsVoice'] as String : null,
      );
    } catch (e) {
      debugPrint('AppSettings.fromJson failed, using defaults: $e');
      return copyAppSettings(appSettingsDefault);
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'fontSize': fontSize,
      'appFontSize': appFontSize,
      'lineHeight': lineHeight,
      'themeColor': themeColor.value,
      'themeVariant': themeVariant.name,
      'brightness': brightness.name,
      'themeContrastLevel': themeContrastLevel,
      'readingSpeed': readingSpeed,
      'language': language,
      'keepScreenOn': keepScreenOn,
      'showEdgeNavButtons': showEdgeNavButtons,
      'edgePadding': edgePadding,
      'useColorfulPartStyle': useColorfulPartStyle,
      'ttsEnabled': ttsEnabled,
      'ttsSpeechRate': ttsSpeechRate,
      'ttsVoice': ttsVoice,
    };
  }

  static double _readDouble(dynamic value, double fallback) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static double _parseAppFontSize(Map<String, dynamic> json) {
    if (json.containsKey('appFontSize') && json['appFontSize'] != null) {
      return _readDouble(json['appFontSize'], 18.0);
    }
    return _readDouble(json['fontSize'], 18.0);
  }

  static DynamicSchemeVariant _parseThemeVariant(dynamic variant) {
    if (variant is! String) {
      return DynamicSchemeVariant.tonalSpot;
    }
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
    appFontSize: 18,
    lineHeight: 2.0,
    themeColor: Colors.deepOrange,
    themeVariant: DynamicSchemeVariant.tonalSpot,
    brightness: Brightness.light,
    themeContrastLevel: 0.5,
    readingSpeed: 200.0,
    language: 'gu',
    keepScreenOn: false,
    showEdgeNavButtons: false,
    edgePadding: 0.0,
    useColorfulPartStyle: false,
    ttsEnabled: false,
    ttsSpeechRate: 0.5,
  ),
);

AppSettings appSettingsDefault = AppSettings(
  fontSize: 18,
  appFontSize: 18,
  lineHeight: 2.0,
  themeColor: Colors.deepOrange,
  themeVariant: DynamicSchemeVariant.tonalSpot,
  brightness: Brightness.light,
  themeContrastLevel: 0.5,
  readingSpeed: 200.0,
  language: 'gu',
  keepScreenOn: false,
  showEdgeNavButtons: false,
  edgePadding: 0.0,
  useColorfulPartStyle: false,
  ttsEnabled: false,
  ttsSpeechRate: 0.5,
);

AppSettings copyAppSettings(
  AppSettings settings, {
  double? fontSize,
  double? appFontSize,
  double? lineHeight,
  Color? themeColor,
  DynamicSchemeVariant? themeVariant,
  Brightness? brightness,
  double? themeContrastLevel,
  double? readingSpeed,
  String? language,
  bool? keepScreenOn,
  bool? showEdgeNavButtons,
  double? edgePadding,
  bool? useColorfulPartStyle,
  bool? ttsEnabled,
  double? ttsSpeechRate,
  String? ttsVoice,
  bool clearTtsVoice = false,
}) {
  return AppSettings(
    fontSize: fontSize ?? settings.fontSize,
    appFontSize: appFontSize ?? settings.appFontSize,
    lineHeight: lineHeight ?? settings.lineHeight,
    themeColor: themeColor ?? settings.themeColor,
    themeVariant: themeVariant ?? settings.themeVariant,
    brightness: brightness ?? settings.brightness,
    themeContrastLevel: themeContrastLevel ?? settings.themeContrastLevel,
    readingSpeed: readingSpeed ?? settings.readingSpeed,
    language: language ?? settings.language,
    keepScreenOn: keepScreenOn ?? settings.keepScreenOn,
    showEdgeNavButtons: showEdgeNavButtons ?? settings.showEdgeNavButtons,
    edgePadding: edgePadding ?? settings.edgePadding,
    useColorfulPartStyle: useColorfulPartStyle ?? settings.useColorfulPartStyle,
    ttsEnabled: ttsEnabled ?? settings.ttsEnabled,
    ttsSpeechRate: ttsSpeechRate ?? settings.ttsSpeechRate,
    ttsVoice: clearTtsVoice ? null : (ttsVoice ?? settings.ttsVoice),
  );
}
