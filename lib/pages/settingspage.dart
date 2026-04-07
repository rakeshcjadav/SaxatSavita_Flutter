import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:saxatsavita_flutter/auth/pages/google_sign_in_page.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/debug_only/debug_migration_with_user_id.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/helpers/firebase_integration_helper.dart';
import 'package:saxatsavita_flutter/services/first_time_user_service.dart';
import 'package:saxatsavita_flutter/services/firebase_sync_service.dart';
import 'package:saxatsavita_flutter/services/cache_service.dart';
import 'package:saxatsavita_flutter/services/in_app_review_service.dart';
import 'package:saxatsavita_flutter/services/in_app_update_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:saxatsavita_flutter/pages/welcome_screen.dart';

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
  late bool _keepScreenOn;
  late bool _showEdgeNavButtons;
  late double _edgePadding;
  late bool _useColorfulPartStyle;
  late bool _ttsEnabled;
  late double _ttsSpeechRate;
  String? _ttsVoice; // "name|locale"

  // Available TTS voices loaded from the device
  List<Map<String, String>> _availableVoices = [];
  bool _voicesLoaded = false;

  // TTS voice preview
  FlutterTts? _previewTts;
  bool _isPreviewPlaying = false;

  // Track saving state
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadOriginalSettings();
  }

  @override
  void dispose() {
    _previewTts?.stop();
    super.dispose();
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
    _keepScreenOn = _originalSettings.keepScreenOn;
    _showEdgeNavButtons = _originalSettings.showEdgeNavButtons;
    _edgePadding = _originalSettings.edgePadding;
    _useColorfulPartStyle = _originalSettings.useColorfulPartStyle;
    _ttsEnabled = _originalSettings.ttsEnabled;
    _ttsSpeechRate = _originalSettings.ttsSpeechRate;
    _ttsVoice = _originalSettings.ttsVoice;
  }

  void _revertChanges() {
    appSettingsNotifier.value = _originalSettings;
  }

  // ── TTS voice helpers ────────────────────────────────────────────────────

  /// Maps BCP-47 locale codes to human-readable language+region names.
  static const Map<String, String> _localeNames = {
    'ar': 'Arabic',
    'bn': 'Bengali',
    'bn-BD': 'Bengali (Bangladesh)',
    'gu-IN': 'Gujarati (India)',
    'hi-IN': 'Hindi (India)',
    'mr-IN': 'Marathi (India)',
    'bn-IN': 'Bengali (India)',
    'ta-IN': 'Tamil (India)',
    'te-IN': 'Telugu (India)',
    'kn-IN': 'Kannada (India)',
    'ml-IN': 'Malayalam (India)',
    'pa-IN': 'Punjabi (India)',
    'ur-PK': 'Urdu (Pakistan)',
    'en-IN': 'English (India)',
    'en-US': 'English (US)',
    'en-GB': 'English (UK)',
    'en-AU': 'English (Australia)',
    'en-CA': 'English (Canada)',
    'fr-FR': 'French (France)',
    'fr-CA': 'French (Canada)',
    'de-DE': 'German (Germany)',
    'es-ES': 'Spanish (Spain)',
    'es-US': 'Spanish (US)',
    'it-IT': 'Italian',
    'pt-BR': 'Portuguese (Brazil)',
    'pt-PT': 'Portuguese (Portugal)',
    'ru-RU': 'Russian',
    'zh-CN': 'Chinese (Simplified)',
    'zh-TW': 'Chinese (Traditional)',
    'ja-JP': 'Japanese',
    'ko-KR': 'Korean',
    'ar-XA': 'Arabic',
    'nl-NL': 'Dutch',
    'pl-PL': 'Polish',
    'sv-SE': 'Swedish',
    'nb-NO': 'Norwegian',
    'da-DK': 'Danish',
    'fi-FI': 'Finnish',
    'tr-TR': 'Turkish',
    'cs-CZ': 'Czech',
    'sk-SK': 'Slovak',
    'ro-RO': 'Romanian',
    'hu-HU': 'Hungarian',
    'uk-UA': 'Ukrainian',
  };

  static String _localeDisplayName(String locale) {
    final norm = locale.replaceAll('_', '-');
    if (_localeNames.containsKey(norm)) return _localeNames[norm]!;
    // Try just the language code
    final lang = norm.split('-').first;
    final langMatch =
        _localeNames.entries
            .where((e) => e.key.startsWith('$lang-'))
            .map((e) => e.value.split(' (').first)
            .firstOrNull;
    return langMatch ?? norm;
  }

  /// Builds a user-friendly display name from raw TTS voice data.
  /// • iOS:     "com.apple.voice.compact.en-US.Samantha" → "Samantha" / "Samantha · Enhanced"
  /// • Android: "en-us-x-sfg-local"                     → "Gujarati (India) · Standard"
  static String _buildVoiceDisplayName(
    String name,
    String locale,
    int quality, {
    int gender = 0,
  }) {
    // gender: 0=unspecified, 1=male, 2=female (iOS AVSpeechSynthesisVoiceGender)
    final genderSuffix = gender == 1 ? ' ♂' : (gender == 2 ? ' ♀' : '');

    String? personalName;

    // iOS / macOS reverse-domain names: com.apple.ttsbundle.Samantha-compact
    // or com.apple.voice.compact.en-US.Samantha
    if (name.contains('.')) {
      final segments = name.split('.');
      // Last dot-segment that is a clean word (no hyphens) is the personal name
      for (final seg in segments.reversed) {
        if (seg.isNotEmpty && RegExp(r'^[A-Za-z]+$').hasMatch(seg)) {
          personalName = seg;
          break;
        }
      }
    }

    if (personalName != null) {
      // iOS quality: 1 = default, 2 = enhanced/premium
      if (quality >= 2) return '$personalName$genderSuffix · Enhanced';
      return '$personalName$genderSuffix';
    }

    // Android / other: voice name conveys no useful info to most users,
    // but Google TTS names follow: {lang}-{region}-x-{code}-{local|network}
    // Extract the variant code to differentiate voices in the same locale.
    String? variantLabel;
    final xMatch = RegExp(r'-x-([^-]+)-').firstMatch(name.toLowerCase());
    if (xMatch != null) {
      final code = xMatch.group(1)!;
      // Strip the language prefix (e.g. 'gu' from 'gud') to get the variant letter(s)
      final localeLang = locale.split('-').first.toLowerCase();
      String variant =
          code.startsWith(localeLang)
              ? code.substring(localeLang.length)
              : code;
      if (variant.isNotEmpty) {
        variantLabel = 'Voice ${variant.toUpperCase()}';
      }
    }

    String qualityLabel;
    if (quality >= 500) {
      qualityLabel = 'Premium';
    } else if (quality >= 400) {
      qualityLabel = 'Enhanced';
    } else {
      qualityLabel = 'Standard';
    }

    final base = variantLabel ?? _localeDisplayName(locale);
    return '$base$genderSuffix · $qualityLabel';
  }

  Future<void> _previewSelectedVoice() async {
    if (_isPreviewPlaying) {
      await _previewTts?.stop();
      if (mounted) setState(() => _isPreviewPlaying = false);
      return;
    }
    _previewTts ??= FlutterTts();
    await _previewTts!.setLanguage('gu-IN');
    await _previewTts!.setSpeechRate(_ttsSpeechRate);
    if (_ttsVoice != null) {
      final parts = _ttsVoice!.split('|');
      if (parts.length == 2) {
        await _previewTts!.setVoice({'name': parts[0], 'locale': parts[1]});
      }
    }
    _previewTts!.setCompletionHandler(() {
      if (mounted) setState(() => _isPreviewPlaying = false);
    });
    _previewTts!.setErrorHandler((_) {
      if (mounted) setState(() => _isPreviewPlaying = false);
    });
    if (mounted) setState(() => _isPreviewPlaying = true);
    await _previewTts!.speak('નમસ્તે, આ મારો અવાજ છે.');
  }

  Future<void> _loadTtsVoices() async {
    if (_voicesLoaded) return;
    try {
      final tts = FlutterTts();
      // Setting a language first ensures iOS returns the full voice list.
      await tts.setLanguage('gu-IN');
      final raw = await tts.getVoices;
      debugPrint('TTS raw voices count: ${(raw as List?)?.length ?? 0}');
      if (raw == null || (raw as List).isEmpty) {
        if (mounted) setState(() => _voicesLoaded = true);
        return;
      }

      final allVoices = (raw as List).cast<Map>();
      debugPrint('First voice keys: ${allVoices.first.keys.toList()}');
      debugPrint('First voice: ${allVoices.first}');

      final allGujaratiVoices =
          allVoices
              .where(
                (v) => (v['locale']?.toString() ?? '').toLowerCase().startsWith(
                  'gu',
                ),
              )
              .toList();
      debugPrint('Gujarati voices count: ${allGujaratiVoices.length}');

      // If no Gujarati voices found, fall back to Indian English voices.
      final candidateVoices =
          allGujaratiVoices.isNotEmpty
              ? allGujaratiVoices
              : allVoices
                  .where(
                    (v) =>
                        (v['locale']?.toString() ?? '').toLowerCase() ==
                            'en-in' ||
                        (v['locale']?.toString() ?? '').toLowerCase() ==
                            'en_in',
                  )
                  .toList();
      debugPrint(
        'Candidate voices count after fallback: ${candidateVoices.length}',
      );

      // Prefer installed offline voices; fall back to all candidate voices
      // (iOS Simulator returns all voices as notInstalled).
      final installedOffline =
          candidateVoices
              .where(
                (v) =>
                    v['networkConnectionRequired'] != true &&
                    v['notInstalled'] != true,
              )
              .toList();
      final source =
          installedOffline.isNotEmpty ? installedOffline : candidateVoices;

      final voices =
          source
              .map(
                (v) => {
                  'name': v['name']?.toString() ?? '',
                  'locale': v['locale']?.toString() ?? '',
                  'quality': (v['quality'] ?? 300).toString(),
                  'gender': (v['gender'] ?? 0).toString(),
                },
              )
              .where((v) => v['name']!.isNotEmpty)
              .toList();

      // Build display names and handle duplicates by appending index
      final displayNameCount = <String, int>{};
      for (final v in voices) {
        final dn = _buildVoiceDisplayName(
          v['name']!,
          v['locale']!,
          int.tryParse(v['quality']!) ?? 300,
          gender: int.tryParse(v['gender']!) ?? 0,
        );
        displayNameCount[dn] = (displayNameCount[dn] ?? 0) + 1;
        v['displayName'] = dn;
      }
      // For duplicates, suffix a counter
      final seenCount = <String, int>{};
      for (final v in voices) {
        final dn = v['displayName']!;
        if (displayNameCount[dn]! > 1) {
          seenCount[dn] = (seenCount[dn] ?? 0) + 1;
          v['displayName'] = '$dn ${seenCount[dn]}';
        }
      }

      voices.sort((a, b) {
        final la = _localeDisplayName(a['locale']!);
        final lb = _localeDisplayName(b['locale']!);
        final c = la.compareTo(lb);
        if (c != 0) return c;
        return a['displayName']!.compareTo(b['displayName']!);
      });

      if (mounted) {
        setState(() {
          _availableVoices = voices;
          _voicesLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading TTS voices: $e');
      if (mounted) setState(() => _voicesLoaded = true);
    }
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
    _keepScreenOn = _originalSettings.keepScreenOn;
    _showEdgeNavButtons = _originalSettings.showEdgeNavButtons;
    _edgePadding = _originalSettings.edgePadding;
    _useColorfulPartStyle = _originalSettings.useColorfulPartStyle;
    _ttsEnabled = _originalSettings.ttsEnabled;
    _ttsSpeechRate = _originalSettings.ttsSpeechRate;
    _ttsVoice = _originalSettings.ttsVoice;
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
        _originalSettings.language != current.language ||
        _originalSettings.keepScreenOn != current.keepScreenOn ||
        _originalSettings.showEdgeNavButtons != current.showEdgeNavButtons ||
        _originalSettings.edgePadding != current.edgePadding ||
        _originalSettings.useColorfulPartStyle !=
            current.useColorfulPartStyle ||
        _originalSettings.ttsEnabled != current.ttsEnabled ||
        _originalSettings.ttsSpeechRate != current.ttsSpeechRate ||
        _originalSettings.ttsVoice != current.ttsVoice;
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
      keepScreenOn: _keepScreenOn,
      showEdgeNavButtons: _showEdgeNavButtons,
      edgePadding: _edgePadding,
      useColorfulPartStyle: _useColorfulPartStyle,
      ttsEnabled: _ttsEnabled,
      ttsSpeechRate: _ttsSpeechRate,
      ttsVoice: _ttsVoice,
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

  Future<void> _confirmAndDeleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.confirm),
            content: Text(
              AppLocalizations.of(context)!.confirm_delete_account_message,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppLocalizations.of(context)!.delete),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _performAccountDeletion();
    }
  }

  Future<void> _performAccountDeletion() async {
    setState(() {
      _isSaving = true;
    });

    final firebaseService = FirebaseSyncService();
    final cacheService = CacheService();

    bool deleted = false;
    // Likely requires recent login. Prompt user to reauthenticate.
    final reauthCredential = await _promptReauthentication();
    if (reauthCredential == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.delete_account_requires_relogin,
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      setState(() {
        _isSaving = false;
      });
      return;
    }

    deleted = await firebaseService.deleteAccount(
      reauthCredential: reauthCredential,
    );
    if (!deleted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.delete_account_failed),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isSaving = false;
      });
      return;
    }

    // Clear local cache and navigate to welcome screen
    try {
      await cacheService.clearAllLocalCache();
    } catch (e) {
      debugPrint('Warning: failed to clear cache after account deletion: $e');
    }

    if (mounted) {
      // Navigate to Google Sign-In page and remove all previous routes
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const GoogleSignInPage()),
        (route) => false,
      );
    }

    setState(() {
      _isSaving = false;
    });
  }

  /// Prompt the user to reauthenticate using available providers (Google / Apple)
  /// Returns an [AuthCredential] on success, or null if canceled/failed.
  Future<AuthCredential?> _promptReauthentication() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    // Determine the provider based on user's sign-in method
    final providerData = user.providerData;
    String? provider;
    for (final userInfo in providerData) {
      if (userInfo.providerId == 'google.com') {
        provider = 'google';
        break;
      } else if (userInfo.providerId == 'apple.com') {
        provider = 'apple';
        break;
      }
    }

    if (provider == null) {
      // Fallback to opening sign-in screen
      return _fallbackReauthentication();
    }

    return provider == 'google'
        ? _reauthenticateWithGoogle()
        : _reauthenticateWithApple();
  }

  Future<AuthCredential?> _reauthenticateWithGoogle() async {
    try {
      // Use the same Google Sign-In method as your app
      final googleUser = await GoogleSignIn.instance.authenticate();

      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      debugPrint('Google reauthentication credential obtained');
      return credential;
    } catch (e) {
      debugPrint('Error during Google reauthentication: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google reauthentication failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<AuthCredential?> _reauthenticateWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      debugPrint('Apple reauthentication credential obtained');
      return oauthCredential;
    } catch (e) {
      debugPrint('Error during Apple reauthentication: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Apple reauthentication failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<AuthCredential?> _fallbackReauthentication() async {
    final openSignin = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Re-authentication required'),
            content: const Text(
              'For security reasons, deleting your account requires recent authentication. Please sign out and sign back in using your preferred method, then retry account deletion.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Open Sign-In'),
              ),
            ],
          ),
    );

    if (openSignin != true) return null;

    // Navigate to the sign-in page
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const WelcomeScreen()));
    return null;
  }

  List<Widget> _buildAccountSection() {
    if (kIsWeb || FirebaseAuth.instance.currentUser == null) return [];
    return <Widget>[
      // Account & Privacy Section
      _buildSectionHeader(
        context,
        AppLocalizations.of(context)!.account_and_privacy,
        Icons.lock,
      ),

      const SizedBox(height: 8),

      Card(
        child: ListTile(
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          title: Text(AppLocalizations.of(context)!.delete_account),
          subtitle: Column(
            children: [
              Text(AppLocalizations.of(context)!.delete_account_description),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: _confirmAndDeleteAccount,
                child: Text(
                  AppLocalizations.of(context)!.delete_account_button,
                ),
              ),
            ],
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildTextSettingsSection() {
    return <Widget>[
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

      // Edge Padding Setting
      Card(
        child: ListTile(
          leading: const Icon(Icons.border_horizontal),
          title: Text(
            '${AppLocalizations.of(context)!.edgePadding}: ${_edgePadding.toStringAsFixed(0)} px',
          ),
          subtitle: SizedBox(
            width: 200,
            child: Slider(
              value: _edgePadding,
              min: 0.0,
              max: 16.0,
              divisions: 8,
              label: _edgePadding.toStringAsFixed(0),
              onChanged: (double value) {
                setState(() {
                  _edgePadding = value;
                  _updateHasUnsavedChanges();
                });
              },
            ),
          ),
        ),
      ),

      // Keep Screen On Setting
      Card(
        child: SwitchListTile(
          secondary: const Icon(Icons.screen_lock_portrait),
          title: Text(AppLocalizations.of(context)!.keepScreenOn),
          subtitle: Text(AppLocalizations.of(context)!.keepScreenOnDescription),
          value: _keepScreenOn,
          onChanged: (bool value) {
            setState(() {
              _keepScreenOn = value;
              _updateHasUnsavedChanges();
            });
          },
        ),
      ),

      // Show Edge Navigation Buttons Setting
      Card(
        child: SwitchListTile(
          secondary: const Icon(Icons.touch_app),
          title: Text(AppLocalizations.of(context)!.showEdgeNavButtons),
          subtitle: Text(
            AppLocalizations.of(context)!.showEdgeNavButtonsDescription,
          ),
          value: _showEdgeNavButtons,
          onChanged: (bool value) {
            setState(() {
              _showEdgeNavButtons = value;
              _updateHasUnsavedChanges();
            });
          },
        ),
      ),
    ];
  }

  List<Widget> _buildTtsSettingsSection() {
    // TTS is not supported on iOS — return nothing
    if (Platform.isIOS) return [];

    return [
      _buildSectionHeader(
        context,
        AppLocalizations.of(context)!.ttsSettings,
        Icons.record_voice_over_outlined,
      ),
      const SizedBox(height: 8),

      // Enable / disable TTS
      Card(
        child: SwitchListTile(
          secondary: const Icon(Icons.record_voice_over_outlined),
          title: Text(AppLocalizations.of(context)!.ttsEnabled),
          subtitle: Text(AppLocalizations.of(context)!.ttsEnabledDescription),
          value: _ttsEnabled,
          onChanged: (bool value) {
            setState(() {
              _ttsEnabled = value;
              _updateHasUnsavedChanges();
            });
            if (value) _loadTtsVoices();
          },
        ),
      ),

      // Speech Rate (only visible when TTS is enabled)
      if (_ttsEnabled)
        Card(
          child: ListTile(
            leading: const Icon(Icons.speed_outlined),
            title: Text(
              '${AppLocalizations.of(context)!.ttsSpeechRate}: ${(_ttsSpeechRate * 10).round() / 10}x',
            ),
            subtitle: Slider(
              min: 0.1,
              max: 1.0,
              divisions: 9,
              value: _ttsSpeechRate,
              label: '${(_ttsSpeechRate * 10).round() / 10}x',
              onChanged: (value) {
                setState(() {
                  _ttsSpeechRate = value;
                });
                _updateHasUnsavedChanges();
              },
            ),
          ),
        ),

      // Voice picker (only visible when TTS is enabled)
      if (_ttsEnabled)
        Card(
          child: ListTile(
            leading: const Icon(Icons.mic_none_outlined),
            title: Text(AppLocalizations.of(context)!.ttsVoice),
            trailing:
                _voicesLoaded
                    ? IconButton(
                      icon: Icon(
                        _isPreviewPlaying
                            ? Icons.stop_circle_outlined
                            : Icons.play_circle_outline,
                      ),
                      tooltip: 'Preview voice',
                      onPressed: _previewSelectedVoice,
                    )
                    : null,
            subtitle:
                _voicesLoaded
                    ? DropdownButton<String?>(
                      isExpanded: true,
                      value:
                          _availableVoices.any(
                                (v) =>
                                    '${v['name']}|${v['locale']}' == _ttsVoice,
                              )
                              ? _ttsVoice
                              : null,
                      underline: const SizedBox.shrink(),
                      items: [
                        DropdownMenuItem<String?>(
                          value: null,
                          child: Text(
                            AppLocalizations.of(context)!.ttsVoiceDefault,
                          ),
                        ),
                        ..._availableVoices.map((v) {
                          final key = '${v['name']}|${v['locale']}';
                          final display =
                              v['displayName']!.isNotEmpty
                                  ? v['displayName']!
                                  : v['name']!;
                          return DropdownMenuItem<String?>(
                            value: key,
                            child: Text(
                              display,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          );
                        }),
                      ],
                      onChanged: (value) {
                        setState(() => _ttsVoice = value);
                        _updateHasUnsavedChanges();
                      },
                    )
                    : TextButton.icon(
                      onPressed: _loadTtsVoices,
                      icon: const Icon(Icons.refresh),
                      label: Text(AppLocalizations.of(context)!.ttsVoice),
                    ),
          ),
        ),
    ];
  }

  List<Widget> _buildThemeSettingsSection() {
    return <Widget>[
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
                      Text(AppLocalizations.of(context)!.light_mode_option),
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
                      Text(AppLocalizations.of(context)!.dark_mode_option),
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
          title: Text(AppLocalizations.of(context)!.theme_variant),
          subtitle: DropdownButton<DynamicSchemeVariant>(
            value: appSettingsNotifier.value.themeVariant,
            isExpanded: true,
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

      // Colorful Part Style Setting
      Card(
        child: SwitchListTile(
          secondary: const Icon(Icons.palette),
          title: Text(AppLocalizations.of(context)!.useColorfulPartStyle),
          subtitle: Text(
            AppLocalizations.of(context)!.useColorfulPartStyleDescription,
          ),
          value: _useColorfulPartStyle,
          onChanged: (bool value) {
            setState(() {
              _useColorfulPartStyle = value;
              _updateHasUnsavedChanges();
            });
          },
        ),
      ),
    ];
  }

  List<Widget> _buildLanguageSettingsSection() {
    return <Widget>[
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
                      Text(AppLocalizations.of(context)!.language_gujarati),
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
                      Text(AppLocalizations.of(context)!.language_english),
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
    ];
  }

  List<Widget> _buildAppSettingsSection() {
    return <Widget>[
      // App Settings Section
      _buildSectionHeader(
        context,
        AppLocalizations.of(context)!.app_settings,
        Icons.settings_applications,
      ),
      const SizedBox(height: 8),

      // Version Information
      Card(
        child: ListTile(
          leading: const Icon(Icons.info_outline),
          title: Text(AppLocalizations.of(context)!.app_version),
          subtitle: FutureBuilder<String>(
            future: InAppUpdateService().getCurrentVersion(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text(snapshot.data!);
              }
              return Text(AppLocalizations.of(context)!.loading);
            },
          ),
        ),
      ),

      // Check for Updates
      Card(
        child: ListTile(
          leading: const Icon(Icons.system_update),
          title: Text(AppLocalizations.of(context)!.checkForUpdates),
          subtitle: Text(
            AppLocalizations.of(context)!.checkForUpdatesDescription,
          ),
          onTap: () async {
            await InAppUpdateService().checkForUpdate(
              context,
              isManualCheck: true,
            );
          },
        ),
      ),
    ];
  }

  List<Widget> _buildDebugSection() {
    return <Widget>[
      // Debug Section (only show in debug mode)
      if (kDebugMode) ...[
        const SizedBox(height: 24),
        _buildSectionHeader(context, 'Debug Options', Icons.bug_report),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.restart_alt),
            title: const Text('Reset Welcome Screen'),
            subtitle: const Text('Show welcome screen on next app launch'),
            onTap: _resetWelcomeScreen,
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.error_outline),
            title: const Text('Test Update Error Dialog'),
            subtitle: const Text(
              'Test the enhanced error handling for updates',
            ),
            onTap: () {
              InAppUpdateService().testErrorDialog(context);
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.error_outline),
            title: const Text('Test In-App review'),
            subtitle: const Text('Test the in-app review prompt dialog'),
            onTap: () {
              InAppReviewService().forcePromptForReview();
            },
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.sync_problem),
            title: const Text('Debug Migration Issues'),
            subtitle: const Text('Test migration with any user ID'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DebugMigrationWithUserIdPage(),
                ),
              );
            },
          ),
        ),
      ],
    ];
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
                    // Text Settings Section
                    ..._buildTextSettingsSection(),
                    const SizedBox(height: 24),
                    // Text-to-Speech Section
                    ..._buildTtsSettingsSection(),
                    const SizedBox(height: 24),
                    // Theme & Appearance Section
                    ..._buildThemeSettingsSection(),
                    const SizedBox(height: 24),
                    // Language & Localization Section
                    ..._buildLanguageSettingsSection(),

                    const SizedBox(height: 24),
                    // App Settings Section
                    ..._buildAppSettingsSection(),

                    const SizedBox(height: 24),
                    ..._buildAccountSection(),
                    // Debug Section
                    ..._buildDebugSection(),
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
