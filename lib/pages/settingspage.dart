import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _fontSize = appSettingsNotifier.value.fontSize;
  double _lineHeight = appSettingsNotifier.value.lineHeight;
  Color _themeColor = appSettingsNotifier.value.themeColor;
  DynamicSchemeVariant _themeVariant = appSettingsNotifier.value.themeVariant;
  double _themeContrastLevel = appSettingsNotifier.value.themeContrastLevel;
  double _readingSpeed = appSettingsNotifier.value.readingSpeed;
  String _language = appSettingsNotifier.value.language;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        context,
        title: AppLocalizations.of(context)!.settings,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Font Size
            ListTile(
              title: Text(
                '${AppLocalizations.of(context)!.font_size}: $_fontSize',
              ),
              subtitle: Slider(
                min: 15,
                max: 25,
                divisions: 10,
                value: _fontSize,
                label: _fontSize.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _fontSize = value;
                    appSettingsNotifier.value = AppSettings(
                      fontSize: _fontSize,
                      themeColor: appSettingsNotifier.value.themeColor,
                      themeVariant: appSettingsNotifier.value.themeVariant,
                      lineHeight: appSettingsNotifier.value.lineHeight,
                      readingSpeed: appSettingsNotifier.value.readingSpeed,
                      language: appSettingsNotifier.value.language,
                      themeContrastLevel:
                          appSettingsNotifier.value.themeContrastLevel,
                    );
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            // Line Height
            ListTile(
              title: Text(
                '${AppLocalizations.of(context)!.line_height}: ${_lineHeight}x',
              ),
              subtitle: Slider(
                min: 1.5,
                max: 3.0,
                divisions: 15,
                value: _lineHeight,
                label: _lineHeight.round().toString(),
                onChanged: (value) {
                  setState(() {
                    _lineHeight = value;
                    appSettingsNotifier.value = AppSettings(
                      fontSize: appSettingsNotifier.value.fontSize,
                      themeColor: appSettingsNotifier.value.themeColor,
                      themeVariant: appSettingsNotifier.value.themeVariant,
                      lineHeight: _lineHeight,
                      readingSpeed: appSettingsNotifier.value.readingSpeed,
                      language: appSettingsNotifier.value.language,
                      themeContrastLevel:
                          appSettingsNotifier.value.themeContrastLevel,
                    );
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            // Theme Color
            ListTile(
              title: Text(AppLocalizations.of(context)!.theme_color),
              subtitle: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildColorOption(Colors.indigo),
                    _buildColorOption(Colors.blue),
                    _buildColorOption(Colors.yellow),
                    _buildColorOption(Colors.orange),
                    _buildColorOption(Colors.deepOrange),
                    _buildColorOption(Colors.teal),
                    _buildColorOption(Colors.pink),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Theme Variant Selection
            ListTile(
              title: Text('Theme Variant'),
              subtitle: DropdownButton<DynamicSchemeVariant>(
                value: appSettingsNotifier.value.themeVariant,
                items:
                    DynamicSchemeVariant.values.map((variant) {
                      return DropdownMenuItem(
                        value: variant,
                        child: Text(
                          variant.toString().split('.').last.toUpperCase(),
                        ),
                      );
                    }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _themeVariant = value;
                      appSettingsNotifier.value = AppSettings(
                        fontSize: appSettingsNotifier.value.fontSize,
                        lineHeight: appSettingsNotifier.value.lineHeight,
                        themeColor: appSettingsNotifier.value.themeColor,
                        themeVariant: _themeVariant,
                        readingSpeed: appSettingsNotifier.value.readingSpeed,
                        language: appSettingsNotifier.value.language,
                        themeContrastLevel:
                            appSettingsNotifier.value.themeContrastLevel,
                      );
                    });
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            // Theme Contrast Level
            ListTile(
              title: Text(
                '${AppLocalizations.of(context)!.theme_contrast}: $_themeContrastLevel',
              ),
              subtitle: Slider(
                min: -1.0,
                max: 1.0,
                divisions: 10,
                value: _themeContrastLevel,
                label: '${_themeContrastLevel}x',
                onChanged: (value) {
                  setState(() {
                    _themeContrastLevel = value;
                    appSettingsNotifier.value = AppSettings(
                      fontSize: appSettingsNotifier.value.fontSize,
                      lineHeight: appSettingsNotifier.value.lineHeight,
                      themeColor: appSettingsNotifier.value.themeColor,
                      themeVariant: appSettingsNotifier.value.themeVariant,
                      readingSpeed: appSettingsNotifier.value.readingSpeed,
                      language: appSettingsNotifier.value.language,
                      themeContrastLevel: _themeContrastLevel,
                    );
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            // Reading Speed
            ListTile(
              title: Text(
                '${AppLocalizations.of(context)!.reading_speed}: $_readingSpeed ${AppLocalizations.of(context)!.words_per_minute}',
              ),
              subtitle: Slider(
                min: 50,
                max: 300.0,
                divisions: 25,
                value: _readingSpeed,
                label: '$_readingSpeed',
                onChanged: (value) {
                  setState(() {
                    _readingSpeed = value;
                    appSettingsNotifier.value = AppSettings(
                      fontSize: appSettingsNotifier.value.fontSize,
                      lineHeight: appSettingsNotifier.value.lineHeight,
                      themeColor: appSettingsNotifier.value.themeColor,
                      themeVariant: appSettingsNotifier.value.themeVariant,
                      readingSpeed: _readingSpeed,
                      language: appSettingsNotifier.value.language,
                      themeContrastLevel:
                          appSettingsNotifier.value.themeContrastLevel,
                    );
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
            // Language Selection
            ListTile(
              title: Text(AppLocalizations.of(context)!.language),
              subtitle: Row(
                children: [
                  Radio<String>(
                    value: 'gu',
                    groupValue: _language,
                    onChanged: (value) {
                      setState(() {
                        _language = value!;
                        appSettingsNotifier.value = AppSettings(
                          fontSize: appSettingsNotifier.value.fontSize,
                          lineHeight: appSettingsNotifier.value.lineHeight,
                          themeColor: appSettingsNotifier.value.themeColor,
                          themeVariant: appSettingsNotifier.value.themeVariant,
                          readingSpeed: appSettingsNotifier.value.readingSpeed,
                          language: _language,
                          themeContrastLevel:
                              appSettingsNotifier.value.themeContrastLevel,
                        );
                      });
                    },
                  ),
                  const Text('Gujarati'),
                  Radio<String>(
                    value: 'en',
                    groupValue: _language,
                    onChanged: (value) {
                      setState(() {
                        _language = value!;
                        appSettingsNotifier.value = AppSettings(
                          fontSize: appSettingsNotifier.value.fontSize,
                          lineHeight: appSettingsNotifier.value.lineHeight,
                          themeColor: appSettingsNotifier.value.themeColor,
                          themeVariant: appSettingsNotifier.value.themeVariant,
                          readingSpeed: appSettingsNotifier.value.readingSpeed,
                          language: _language,
                          themeContrastLevel:
                              appSettingsNotifier.value.themeContrastLevel,
                        );
                      });
                    },
                  ),
                  const Text('English'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorOption(Color color) {
    return GestureDetector(
      onTap:
          () => setState(() {
            _themeColor = color;
            appSettingsNotifier.value = AppSettings(
              fontSize: appSettingsNotifier.value.fontSize,
              lineHeight: appSettingsNotifier.value.lineHeight,
              themeColor: _themeColor,
              themeVariant: appSettingsNotifier.value.themeVariant,
              readingSpeed: appSettingsNotifier.value.readingSpeed,
              language: appSettingsNotifier.value.language,
              themeContrastLevel: appSettingsNotifier.value.themeContrastLevel,
            );
          }),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: _themeColor == color ? Colors.black : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}
