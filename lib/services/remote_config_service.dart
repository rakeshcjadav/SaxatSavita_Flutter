import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Service to manage Firebase Remote Config
/// Allows dynamic configuration updates without app releases
class RemoteConfigService {
  static final RemoteConfigService _instance = RemoteConfigService._internal();
  factory RemoteConfigService() => _instance;
  RemoteConfigService._internal();

  FirebaseRemoteConfig? _remoteConfig;
  bool _initialized = false;

  /// Initialize Remote Config with default values
  Future<void> initialize() async {
    try {
      _remoteConfig = FirebaseRemoteConfig.instance;

      // Set config settings
      await _remoteConfig!.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval:
              kDebugMode
                  ? const Duration(seconds: 10)
                  : const Duration(hours: 1), // Fetch at most once per hour
        ),
      );

      // Set default values
      await _remoteConfig!.setDefaults({
        // App behavior
        'maintenance_mode': false,
        'maintenance_message':
            'App is under maintenance. Please try again later.',
        'force_update_required': false,
        'minimum_supported_version': '2.0.0',
        'latest_version': '2.15.0',
        'update_message':
            'A new version is available. Please update for the best experience.',

        // Feature flags
        'enable_search': true,
        'enable_notes': true,
        'enable_quotes': true,
        'enable_reading_history': true,
        'enable_reading_plans': true,
        'enable_auto_scroll': true,
        'enable_bookmarks': true,
        'enable_favorites': true,
        'enable_social_sharing': true,
        'enable_new_kiran_content_rendering': false,

        // UI customization
        'show_welcome_screen': true,
        'default_theme_color': '#B8572A',
        'default_font_size': 18.0,
        'default_line_height': 2.0,
        'default_reading_speed': 150, // words per minute
        // Content
        'featured_kiran_part': 1,
        'featured_kiran_index': 1,
        'announcement_title': '',
        'announcement_message': '',
        'announcement_enabled': false,

        // Analytics
        'enable_analytics': true,
        'enable_crashlytics': true,

        // Remote content URLs (for dynamic content updates)
        'info_content_url': '',
        'meanings_data_url': '',

        // A/B Testing
        'use_custom_html_widget':
            true, // Toggle between HtmlToTextSpan and CustomHtmlWidget
      });

      // Fetch and activate
      await _remoteConfig!.fetchAndActivate();

      _initialized = true;
      debugPrint('✅ Remote Config initialized successfully');
      _logAllValues();
    } catch (e) {
      debugPrint('❌ Error initializing Remote Config: $e');
      _initialized = false;
    }
  }

  /// Fetch latest config values
  Future<bool> fetchConfig() async {
    if (_remoteConfig == null) {
      debugPrint('⚠️ Remote Config not initialized');
      return false;
    }

    try {
      await _remoteConfig!.fetchAndActivate();
      debugPrint('✅ Remote Config fetched and activated');
      return true;
    } catch (e) {
      debugPrint('❌ Error fetching Remote Config: $e');
      return false;
    }
  }

  /// Check if initialized
  bool get isInitialized => _initialized;

  // ===== Getters for specific config values =====

  // App behavior
  bool get isMaintenanceMode =>
      _remoteConfig?.getBool('maintenance_mode') ?? false;
  String get maintenanceMessage =>
      _remoteConfig?.getString('maintenance_message') ??
      'App is under maintenance. Please try again later.';
  bool get forceUpdateRequired =>
      _remoteConfig?.getBool('force_update_required') ?? false;
  String get minimumSupportedVersion =>
      _remoteConfig?.getString('minimum_supported_version') ?? '2.0.0';
  String get latestVersion =>
      _remoteConfig?.getString('latest_version') ?? '2.15.0';
  String get updateMessage =>
      _remoteConfig?.getString('update_message') ??
      'A new version is available. Please update for the best experience.';

  // Feature flags
  bool get enableSearch => _remoteConfig?.getBool('enable_search') ?? true;
  bool get enableNotes => _remoteConfig?.getBool('enable_notes') ?? true;
  bool get enableQuotes => _remoteConfig?.getBool('enable_quotes') ?? true;
  bool get enableReadingHistory =>
      _remoteConfig?.getBool('enable_reading_history') ?? true;
  bool get enableReadingPlans =>
      _remoteConfig?.getBool('enable_reading_plans') ?? true;
  bool get enableAutoScroll =>
      _remoteConfig?.getBool('enable_auto_scroll') ?? true;
  bool get enableBookmarks =>
      _remoteConfig?.getBool('enable_bookmarks') ?? true;
  bool get enableFavorites =>
      _remoteConfig?.getBool('enable_favorites') ?? true;
  bool get enableSocialSharing =>
      _remoteConfig?.getBool('enable_social_sharing') ?? true;

  // UI customization
  bool get showWelcomeScreen =>
      _remoteConfig?.getBool('show_welcome_screen') ?? true;
  String get defaultThemeColor =>
      _remoteConfig?.getString('default_theme_color') ?? '#B8572A';
  double get defaultFontSize =>
      _remoteConfig?.getDouble('default_font_size') ?? 18.0;
  double get defaultLineHeight =>
      _remoteConfig?.getDouble('default_line_height') ?? 2.0;
  int get defaultReadingSpeed =>
      _remoteConfig?.getInt('default_reading_speed') ?? 150;

  // Content
  int get featuredKiranPart =>
      _remoteConfig?.getInt('featured_kiran_part') ?? 1;
  int get featuredKiranIndex =>
      _remoteConfig?.getInt('featured_kiran_index') ?? 1;
  String get announcementTitle =>
      _remoteConfig?.getString('announcement_title') ?? '';
  String get announcementMessage =>
      _remoteConfig?.getString('announcement_message') ?? '';
  bool get announcementEnabled =>
      _remoteConfig?.getBool('announcement_enabled') ?? false;

  // Analytics
  bool get enableAnalytics =>
      _remoteConfig?.getBool('enable_analytics') ?? true;
  bool get enableCrashlytics =>
      _remoteConfig?.getBool('enable_crashlytics') ?? true;

  // Remote content URLs
  String get infoContentUrl =>
      _remoteConfig?.getString('info_content_url') ?? '';
  String get meaningsDataUrl =>
      _remoteConfig?.getString('meanings_data_url') ?? '';

  // A/B Testing
  bool get useCustomHtmlWidget =>
      _remoteConfig?.getBool('use_custom_html_widget') ?? false;

  /// Get a custom string value
  String getString(String key, {String defaultValue = ''}) {
    return _remoteConfig?.getString(key) ?? defaultValue;
  }

  /// Get a custom bool value
  bool getBool(String key, {bool defaultValue = false}) {
    return _remoteConfig?.getBool(key) ?? defaultValue;
  }

  /// Get a custom int value
  int getInt(String key, {int defaultValue = 0}) {
    return _remoteConfig?.getInt(key) ?? defaultValue;
  }

  /// Get a custom double value
  double getDouble(String key, {double defaultValue = 0.0}) {
    return _remoteConfig?.getDouble(key) ?? defaultValue;
  }

  /// Debug: Log all config values
  void _logAllValues() {
    if (_remoteConfig == null) return;

    debugPrint('=== Remote Config Values ===');
    final keys = _remoteConfig!.getAll();
    keys.forEach((key, value) {
      debugPrint('$key: ${value.asString()} (source: ${value.source})');
    });
    debugPrint('===========================');
  }

  /// Get all config keys
  Map<String, RemoteConfigValue> getAllValues() {
    return _remoteConfig?.getAll() ?? {};
  }

  /// Check if a feature is enabled
  bool isFeatureEnabled(String featureKey) {
    return getBool(featureKey, defaultValue: true);
  }

  /// Get theme color as Color object
  Color getThemeColor() {
    try {
      final colorString = defaultThemeColor.replaceAll('#', '');
      return Color(int.parse('FF$colorString', radix: 16));
    } catch (e) {
      debugPrint('Error parsing theme color: $e');
      return const Color(0xFFB8572A); // Default color
    }
  }

  /// Check if app version needs update
  bool needsUpdate(String currentVersion) {
    try {
      final current = _parseVersion(currentVersion);
      final minimum = _parseVersion(minimumSupportedVersion);

      return _compareVersions(current, minimum) < 0;
    } catch (e) {
      debugPrint('Error comparing versions: $e');
      return false;
    }
  }

  /// Check if newer version is available
  bool hasNewerVersion(String currentVersion) {
    try {
      final current = _parseVersion(currentVersion);
      final latest = _parseVersion(latestVersion);

      return _compareVersions(current, latest) < 0;
    } catch (e) {
      debugPrint('Error comparing versions: $e');
      return false;
    }
  }

  List<int> _parseVersion(String version) {
    return version.split('+')[0].split('.').map(int.parse).toList();
  }

  int _compareVersions(List<int> v1, List<int> v2) {
    final length = v1.length > v2.length ? v1.length : v2.length;
    for (int i = 0; i < length; i++) {
      final n1 = i < v1.length ? v1[i] : 0;
      final n2 = i < v2.length ? v2[i] : 0;
      if (n1 != n2) return n1 - n2;
    }
    return 0;
  }
}
