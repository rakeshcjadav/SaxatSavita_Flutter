import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/helpers/firebase_integration_helper.dart';
import 'package:saxatsavita_flutter/services/first_time_user_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Original settings (for comparison and discard functionality)
  late AppSettings _originalSettings;

  // Temporary settings (modified but not yet saved)
  late double _fontSize;
  late double _lineHeight;
  late Color _themeColor;
  late DynamicSchemeVariant _themeVariant;
  late Brightness _brightness;
  late double _themeContrastLevel;
  late double _readingSpeed;
  late String _language;

  // Track saving state
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadOriginalSettings();
  }

  void _loadOriginalSettings() {
    _originalSettings = appSettingsNotifier.value;
    _fontSize = _originalSettings.fontSize;
    _lineHeight = _originalSettings.lineHeight;
    _themeColor = _originalSettings.themeColor;
    _themeVariant = _originalSettings.themeVariant;
    _brightness = _originalSettings.brightness;
    _themeContrastLevel = _originalSettings.themeContrastLevel;
    _readingSpeed = _originalSettings.readingSpeed;
    _language = _originalSettings.language;
  }

  void _revertChanges() {
    appSettingsNotifier.value = _originalSettings;
  }

  Future<void> _resetWelcomeScreen() async {
    try {
      await FirstTimeUserService.resetFirstTimeUser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Welcome screen will show on next app launch'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reset welcome screen: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    _fontSize = _originalSettings.fontSize;
    _lineHeight = _originalSettings.lineHeight;
    _themeColor = _originalSettings.themeColor;
    _themeVariant = _originalSettings.themeVariant;
    _brightness = _originalSettings.brightness;
    _themeContrastLevel = _originalSettings.themeContrastLevel;
    _readingSpeed = _originalSettings.readingSpeed;
    _language = _originalSettings.language;
  }

  bool get _settingsChanged {
    final current = _createCurrentSettings();
    return _originalSettings.fontSize != current.fontSize ||
        _originalSettings.lineHeight != current.lineHeight ||
        _originalSettings.themeColor != current.themeColor ||
        _originalSettings.themeVariant != current.themeVariant ||
        _originalSettings.brightness != current.brightness ||
        _originalSettings.themeContrastLevel != current.themeContrastLevel ||
        _originalSettings.readingSpeed != current.readingSpeed ||
        _originalSettings.language != current.language;
  }

  AppSettings _createCurrentSettings() {
    return AppSettings(
      fontSize: _fontSize,
      lineHeight: _lineHeight,
      themeColor: _themeColor,
      themeVariant: _themeVariant,
      brightness: _brightness,
      themeContrastLevel: _themeContrastLevel,
      readingSpeed: _readingSpeed,
      language: _language,
    );
  }

  void _updateHasUnsavedChanges() {
    setState(() {
      final newSettings = _createCurrentSettings();
      appSettingsNotifier.value = newSettings;
      // This will trigger a rebuild which will update the UI based on _settingsChanged
    });
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
    });

    try {
      final newSettings = _createCurrentSettings();

      // Update global settings
      appSettingsNotifier.value = newSettings;

      // Sync to Firebase
      await FirebaseIntegrationHelper().onAppSettingsChanged(newSettings);

      // Update original settings to reflect saved state
      _originalSettings = newSettings;

      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.settings_saved),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.error_saving_settings}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _discardChanges() {
    setState(() {
      _revertChanges();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.changes_discarded),
        backgroundColor: Colors.orange,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_settingsChanged,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop && _settingsChanged) {
          _showUnsavedChangesDialog();
        }
      },
      child: Scaffold(
        appBar: buildAppBar(
          context,
          title: AppLocalizations.of(context)!.settings,
          extraActions:
              _settingsChanged
                  ? [
                    // Discard button
                    IconButton(
                      onPressed: _discardChanges,
                      icon: const Icon(Icons.refresh),
                      tooltip: AppLocalizations.of(context)!.discard_changes,
                    ),
                    // Save button
                    IconButton(
                      onPressed: _isSaving ? null : _saveSettings,
                      icon:
                          _isSaving
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                              : const Icon(Icons.save),
                      tooltip: AppLocalizations.of(context)!.save_settings,
                    ),
                  ]
                  : null,
        ),
        body: Column(
          children: [
            // Unsaved changes indicator
            if (_settingsChanged)
              Container(
                width: double.infinity,
                color: Theme.of(context).colorScheme.primaryContainer,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.edit,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.you_have_unsaved_changes,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save, size: 16),
                      label: Text(AppLocalizations.of(context)!.save),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView(
                  children: [
                    // Reading Preferences Section
                    _buildSectionHeader(
                      context,
                      AppLocalizations.of(context)!.reading_preferences,
                      Icons.chrome_reader_mode,
                    ),
                    const SizedBox(height: 8),

                    // Font Size
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.text_fields),
                        title: Text(
                          '${AppLocalizations.of(context)!.font_size}: ${_fontSize.round()}',
                        ),
                        subtitle: Slider(
                          min: 15,
                          max: 35,
                          divisions: 20,
                          value: _fontSize,
                          label: _fontSize.round().toString(),
                          onChanged: (value) {
                            setState(() {
                              _fontSize = value;
                            });
                            _updateHasUnsavedChanges();
                          },
                        ),
                      ),
                    ),

                    // Line Height
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.format_line_spacing),
                        title: Text(
                          '${AppLocalizations.of(context)!.line_height}: ${_lineHeight.toStringAsFixed(1)}x',
                        ),
                        subtitle: Slider(
                          min: 1.5,
                          max: 3.0,
                          divisions: 15,
                          value: _lineHeight,
                          label: _lineHeight.toStringAsFixed(1),
                          onChanged: (value) {
                            setState(() {
                              _lineHeight = value;
                            });
                            _updateHasUnsavedChanges();
                          },
                        ),
                      ),
                    ),

                    // Reading Speed
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.speed),
                        title: Text(
                          '${AppLocalizations.of(context)!.reading_speed}: ${_readingSpeed.round()} ${AppLocalizations.of(context)!.words_per_minute}',
                        ),
                        subtitle: Slider(
                          min: 50,
                          max: 300.0,
                          divisions: 25,
                          value: _readingSpeed,
                          label: '${_readingSpeed.round()}',
                          onChanged: (value) {
                            setState(() {
                              _readingSpeed = value;
                            });
                            _updateHasUnsavedChanges();
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Theme & Appearance Section
                    _buildSectionHeader(
                      context,
                      AppLocalizations.of(context)!.theme_appearance,
                      Icons.palette,
                    ),
                    const SizedBox(height: 8),

                    // Theme Color
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.color_lens),
                        title: Text(AppLocalizations.of(context)!.theme_color),
                        subtitle: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildColorOption(Colors.yellow),
                              _buildColorOption(Colors.orange),
                              _buildColorOption(Colors.deepOrange),
                              _buildColorOption(Colors.pink),
                              _buildColorOption(Colors.teal),
                              _buildColorOption(Colors.blue),
                              _buildColorOption(Colors.indigo),
                              _buildColorOption(Colors.deepPurple),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Theme Mode (Light/Dark)
                    Card(
                      child: ListTile(
                        leading: Icon(
                          _brightness == Brightness.light
                              ? Icons.light_mode
                              : Icons.dark_mode,
                        ),
                        title: Text(AppLocalizations.of(context)!.theme_mode),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RadioListTile<Brightness>(
                                title: Row(
                                  children: [
                                    const Icon(Icons.light_mode, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.light_mode_option,
                                    ),
                                  ],
                                ),
                                value: Brightness.light,
                                groupValue: _brightness,
                                onChanged: (Brightness? value) {
                                  setState(() {
                                    _brightness = value!;
                                  });
                                  _updateHasUnsavedChanges();
                                },
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              RadioListTile<Brightness>(
                                title: Row(
                                  children: [
                                    const Icon(Icons.dark_mode, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.dark_mode_option,
                                    ),
                                  ],
                                ),
                                value: Brightness.dark,
                                groupValue: _brightness,
                                onChanged: (Brightness? value) {
                                  setState(() {
                                    _brightness = value!;
                                  });
                                  _updateHasUnsavedChanges();
                                },
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Theme Variant Selection
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.style),
                        title: Text(
                          AppLocalizations.of(context)!.theme_variant,
                        ),
                        subtitle: DropdownButton<DynamicSchemeVariant>(
                          value: appSettingsNotifier.value.themeVariant,
                          isExpanded: true,
                          items:
                              DynamicSchemeVariant.values.map((variant) {
                                return DropdownMenuItem(
                                  value: variant,
                                  child: Text(
                                    variant
                                        .toString()
                                        .split('.')
                                        .last
                                        .toUpperCase(),
                                  ),
                                );
                              }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _themeVariant = value;
                              });
                              _updateHasUnsavedChanges();
                            }
                          },
                        ),
                      ),
                    ),

                    // Theme Contrast Level
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.contrast),
                        title: Text(
                          '${AppLocalizations.of(context)!.theme_contrast}: ${_themeContrastLevel.toStringAsFixed(1)}',
                        ),
                        subtitle: Slider(
                          min: -1.0,
                          max: 1.0,
                          divisions: 4,
                          value: _themeContrastLevel,
                          label: _themeContrastLevel.toStringAsFixed(1),
                          onChanged: (value) {
                            setState(() {
                              _themeContrastLevel = value;
                            });
                            _updateHasUnsavedChanges();
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Language & Localization Section
                    _buildSectionHeader(
                      context,
                      AppLocalizations.of(context)!.language_localization,
                      Icons.language,
                    ),
                    const SizedBox(height: 8),

                    // Language Selection
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.translate),
                        title: Text(AppLocalizations.of(context)!.language),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RadioListTile<String>(
                                title: Row(
                                  children: [
                                    const Icon(Icons.language, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.language_gujarati,
                                    ),
                                  ],
                                ),
                                value: 'gu',
                                groupValue: _language,
                                onChanged: (String? value) {
                                  setState(() {
                                    _language = value!;
                                  });
                                  _updateHasUnsavedChanges();
                                },
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              RadioListTile<String>(
                                title: Row(
                                  children: [
                                    const Icon(Icons.translate, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      AppLocalizations.of(
                                        context,
                                      )!.language_english,
                                    ),
                                  ],
                                ),
                                value: 'en',
                                groupValue: _language,
                                onChanged: (String? value) {
                                  setState(() {
                                    _language = value!;
                                  });
                                  _updateHasUnsavedChanges();
                                },
                                dense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Debug Section (only show in debug mode)
                    if (kDebugMode) ...[
                      const SizedBox(height: 24),
                      _buildSectionHeader(
                        context,
                        'Debug Options',
                        Icons.bug_report,
                      ),
                      const SizedBox(height: 8),
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.restart_alt),
                          title: const Text('Reset Welcome Screen'),
                          subtitle: const Text(
                            'Show welcome screen on next app launch',
                          ),
                          onTap: _resetWelcomeScreen,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnsavedChangesDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.unsaved_changes),
          content: Text(AppLocalizations.of(context)!.unsaved_changes_message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _discardChanges();
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.discard),
            ),
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                navigator.pop();
                await _saveSettings();
                if (mounted) {
                  navigator.pop();
                }
              },
              child: Text(AppLocalizations.of(context)!.save),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.cancel),
            ),
          ],
        );
      },
    );
  }

  Widget _buildColorOption(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _themeColor = color;
        });
        _updateHasUnsavedChanges();
      },
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

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(left: 16),
              height: 1,
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}
