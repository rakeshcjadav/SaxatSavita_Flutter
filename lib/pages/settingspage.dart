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
  Color _themeColor = appSettingsNotifier.value.themeColor;
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
              title: Text(AppLocalizations.of(context)!.font_size),
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
                    _buildColorOption(Colors.grey.shade900),
                    _buildColorOption(Colors.brown.shade900),
                    _buildColorOption(Colors.blue.shade900),
                    _buildColorOption(Colors.orange.shade900),
                    _buildColorOption(Colors.purple.shade900),
                    _buildColorOption(Colors.teal.shade900),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Theme Contrast Level
            ListTile(
              title: Text(AppLocalizations.of(context)!.theme_contrast),
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
                      themeColor: appSettingsNotifier.value.themeColor,
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
              title: Text(AppLocalizations.of(context)!.reading_speed),
              subtitle: Slider(
                min: 0.5,
                max: 2.0,
                divisions: 6,
                value: _readingSpeed,
                label: '${_readingSpeed}x',
                onChanged: (value) {
                  setState(() {
                    _readingSpeed = value;
                    appSettingsNotifier.value = AppSettings(
                      fontSize: appSettingsNotifier.value.fontSize,
                      themeColor: appSettingsNotifier.value.themeColor,
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
                          themeColor: appSettingsNotifier.value.themeColor,
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
                          themeColor: appSettingsNotifier.value.themeColor,
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
              themeColor: _themeColor,
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
