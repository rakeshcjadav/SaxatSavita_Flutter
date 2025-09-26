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
  Brightness _brightness = appSettingsNotifier.value.brightness;
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
        padding: const EdgeInsets.all(0.0),
        child: ListView(
          children: [
            // Font Size
            Card(
              child: ListTile(
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
                      appSettingsNotifier.value = copyAppSettings(
                        appSettingsNotifier.value,
                        fontSize: _fontSize,
                      );
                    });
                  },
                ),
              ),
            ),
            // Line Height
            Card(
              child: ListTile(
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
                      appSettingsNotifier.value = copyAppSettings(
                        appSettingsNotifier.value,
                        lineHeight: _lineHeight,
                      );
                    });
                  },
                ),
              ),
            ),
            // Theme Color
            Card(
              child: ListTile(
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
                      _buildColorOption(Colors.deepPurple),
                    ],
                  ),
                ),
              ),
            ),
            // Theme Variant Selection
            Card(
              child: ListTile(
                title: Text(AppLocalizations.of(context)!.theme_variant),
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
                        appSettingsNotifier.value = copyAppSettings(
                          appSettingsNotifier.value,
                          themeVariant: _themeVariant,
                        );
                      });
                    }
                  },
                ),
              ),
            ),
            // Language Selection
            Card(
              child: ListTile(
                title: Text(AppLocalizations.of(context)!.theme_mode),
                subtitle: RadioGroup<Brightness>(
                  groupValue: _brightness,
                  onChanged: (Brightness? value) {
                    setState(() {
                      _brightness = value!;
                      appSettingsNotifier.value = copyAppSettings(
                        appSettingsNotifier.value,
                        brightness: _brightness,
                      );
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ListTile(
                        title: Text('Light'),
                        leading: Radio<Brightness>(value: Brightness.light),
                      ),
                      const ListTile(
                        title: Text('Dark'),
                        leading: Radio<Brightness>(value: Brightness.dark),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Theme Contrast Level
            Card(
              child: ListTile(
                title: Text(
                  '${AppLocalizations.of(context)!.theme_contrast}: $_themeContrastLevel',
                ),
                subtitle: Slider(
                  min: -1.0,
                  max: 1.0,
                  divisions: 4,
                  value: _themeContrastLevel,
                  label: '${_themeContrastLevel}x',
                  onChanged: (value) {
                    setState(() {
                      _themeContrastLevel = value;
                      appSettingsNotifier.value = copyAppSettings(
                        appSettingsNotifier.value,
                        themeContrastLevel: _themeContrastLevel,
                      );
                    });
                  },
                ),
              ),
            ),
            // Reading Speed
            Card(
              child: ListTile(
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
                      appSettingsNotifier.value = copyAppSettings(
                        appSettingsNotifier.value,
                        readingSpeed: _readingSpeed,
                      );
                    });
                  },
                ),
              ),
            ),
            // Language Selection
            Card(
              child: ListTile(
                title: Text(AppLocalizations.of(context)!.language),
                subtitle: RadioGroup<String>(
                  groupValue: _language,
                  onChanged: (String? value) {
                    setState(() {
                      _language = value!;
                      appSettingsNotifier.value = copyAppSettings(
                        appSettingsNotifier.value,
                        language: _language,
                      );
                    });
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const ListTile(
                        title: Text('ગુજરાતી'),
                        leading: Radio<String>(value: 'gu'),
                      ),
                      const ListTile(
                        title: Text('English'),
                        leading: Radio<String>(value: 'en'),
                      ),
                    ],
                  ),
                ),
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
            appSettingsNotifier.value = copyAppSettings(
              appSettingsNotifier.value,
              themeColor: _themeColor,
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
            color:
                _themeColor == color
                    ? _brightness == Brightness.dark
                        ? Colors.white
                        : Colors.black
                    : Colors.transparent,
            width: 3,
          ),
        ),
      ),
    );
  }
}
