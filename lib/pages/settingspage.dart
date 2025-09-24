import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _fontSize = appSettingsNotifier.value.fontSize;
  Color _themeColor = appSettingsNotifier.value.themeColor;
  double _readingSpeed = appSettingsNotifier.value.readingSpeed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Font Size
            ListTile(
              title: const Text('Font Size'),
              subtitle: Slider(
                min: 12,
                max: 32,
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
                    );
                  });
                },
              ),
            ),
            // Theme Color
            ListTile(
              title: const Text('Theme Color'),
              subtitle: Row(
                children: [
                  _buildColorOption(Colors.blue.shade500),
                  _buildColorOption(Colors.green.shade500),
                  _buildColorOption(Colors.orange.shade500),
                  _buildColorOption(Colors.purple.shade500),
                  _buildColorOption(Colors.brown.shade500),
                ],
              ),
            ),
            // Reading Speed
            ListTile(
              title: const Text('Reading Speed'),
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
                    );
                  });
                },
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
