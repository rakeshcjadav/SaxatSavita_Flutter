import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/helpers/firebase_integration_helper.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/models/bookuserinfo_model.dart';
import 'package:saxatsavita_flutter/models/kiranuserinfo_model.dart';
import 'package:saxatsavita_flutter/models/user_profile_model.dart';
import 'package:saxatsavita_flutter/services/bookservice.dart';
import 'package:saxatsavita_flutter/services/kiranuser_info_migration_service.dart';
import 'package:saxatsavita_flutter/services/kiranuser_service.dart';
import 'package:saxatsavita_flutter/services/reading_history_migration_service.dart';
import 'package:saxatsavita_flutter/services/user_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Utils {
  /// Get subtle background color for each part (theme-aware)
  static Color getPartColor(
    int partNumber,
    BuildContext context, {
    bool forceColorfulStyle = false,
  }) {
    if (!forceColorfulStyle) {
      // If colorful style is disabled, return transparent
      if (!appSettingsNotifier.value.useColorfulPartStyle) {
        return Theme.of(context).colorScheme.surface;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final lightColors = [
      const Color(0xFFE3F2FD), // Light Blue
      const Color(0xFFF3E5F5), // Light Purple
      const Color(0xFFE8F5E9), // Light Green
      const Color(0xFFFFF3E0), // Light Orange
      const Color(0xFFFCE4EC), // Light Pink
    ];

    final darkColors = [
      const Color.fromARGB(255, 9, 12, 43), // Dark Blue
      const Color.fromARGB(255, 29, 8, 56), // Dark Purple
      const Color.fromARGB(255, 7, 37, 9), // Dark Green
      const Color.fromARGB(255, 73, 27, 2), // Dark Orange
      const Color.fromARGB(255, 49, 6, 29), // Dark Pink
    ];

    final colors = isDark ? darkColors : lightColors;
    return colors[(partNumber - 1) % colors.length];
  }

  /// Get accent color for each part (theme-aware)
  static Color getPartAccentColor(
    int partNumber,
    BuildContext context, {
    bool forceColorfulStyle = false,
  }) {
    if (!forceColorfulStyle) {
      // If colorful style is disabled, return the primary color from theme
      if (!appSettingsNotifier.value.useColorfulPartStyle) {
        return Theme.of(context).colorScheme.primary;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final lightColors = [
      const Color(0xFF2196F3), // Blue
      const Color(0xFF9C27B0), // Purple
      const Color(0xFF4CAF50), // Green
      const Color(0xFFFF9800), // Orange
      const Color(0xFFE91E63), // Pink
    ];

    final darkColors = [
      const Color(0xFF64B5F6), // Light Blue
      const Color(0xFFBA68C8), // Light Purple
      const Color(0xFF81C784), // Light Green
      const Color(0xFFFFB74D), // Light Orange
      const Color(0xFFF06292), // Light Pink
    ];

    final colors = isDark ? darkColors : lightColors;
    return colors[(partNumber - 1) % colors.length];
  }

  static Color oppositeColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    final oppositeHue = (hsl.hue + 180.0) % 360.0;
    return hsl.withHue(oppositeHue).toColor();
  }

  static int getEstimatedReadingSeconds(int wordCount) {
    // readingSpeed: words per second
    double readingSpeed = appSettingsNotifier.value.readingSpeed / 60.0;
    final totalSeconds = (wordCount / readingSpeed).round();
    return totalSeconds;
  }

  static String getEstimatedReadingTime(int wordCount) {
    final totalSeconds = getEstimatedReadingSeconds(wordCount);
    final hours = totalSeconds ~/ 3600;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours}h:${minutes % 60}m';
    }
    if (minutes > 0) {
      return '${minutes}m:${seconds}s';
    }
    return '${seconds}s';
  }

  /// Parses a kiran date string of the form 'DD-MM-YY' (ASCII digits,
  /// as stored in [KiranInfo.date] extracted from the JSON book files)
  /// into a [DateTime] at midnight UTC.
  ///
  /// Stored format is 'D-M-YYYY' (4-digit year).  Also accepts the legacy
  /// 'D-M-YY' format: YY >= 50 → 1900 + YY, YY < 50 → 2000 + YY.
  /// Returns null if the string is empty, malformed, or the date is invalid.
  static DateTime? parseKiranDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    final parts = dateStr.split('-');
    if (parts.length != 3) return null;
    final d = int.tryParse(parts[0]);
    final mo = int.tryParse(parts[1]);
    final yy = int.tryParse(parts[2]);
    if (d == null || mo == null || yy == null) return null;
    final int year;
    if (yy >= 100) {
      year = yy; // already a 4-digit year
    } else {
      year = yy >= 50 ? 1900 + yy : 2000 + yy;
    }
    try {
      return DateTime.utc(year, mo, d);
    } catch (_) {
      return null;
    }
  }

  /// Converts ASCII digits 0–9 in [s] to Gujarati numerals ૦–૯.
  static String toGujaratiNumerals(String s) => s
      .replaceAll('0', '૦')
      .replaceAll('1', '૧')
      .replaceAll('2', '૨')
      .replaceAll('3', '૩')
      .replaceAll('4', '૪')
      .replaceAll('5', '૫')
      .replaceAll('6', '૬')
      .replaceAll('7', '૭')
      .replaceAll('8', '૮')
      .replaceAll('9', '૯');

  static bool isBookmarked(KiranUserInfo kiranUserInfo) {
    BookUserInfo bookUserInfo = Bookservice().getBookUserInfo(
      kiranUserInfo.partNumber,
    );
    return bookUserInfo.isKiranBookmarked(kiranUserInfo.kiranIndex);
  }

  static void setBookmark(KiranUserInfo kiranUserInfo) {
    BookUserInfo bookUserInfo = Bookservice().getBookUserInfo(
      kiranUserInfo.partNumber,
    );
    if (bookUserInfo.isKiranBookmarked(kiranUserInfo.kiranIndex)) {
      // Remove bookmark
      bookUserInfo.removeBookmark(kiranUserInfo.kiranIndex);
    } else {
      // Set bookmark
      bookUserInfo.addBookmark(kiranUserInfo.kiranIndex);
    }

    FirebaseIntegrationHelper().onBookUserInfoChanged(bookUserInfo);

    Bookservice().bookUserInfoList = [
      ...?Bookservice().bookUserInfoList?.where(
        (info) => info.partNumber != bookUserInfo.partNumber,
      ),
      bookUserInfo,
    ];

    // Print updated bookmark info
    debugPrint(
      'Bookmark ${bookUserInfo.isKiranBookmarked(kiranUserInfo.kiranIndex) ? "removed from" : "set to"} Kiran ${kiranUserInfo.kiranIndex} for Part ${bookUserInfo.partNumber}',
    );
  }

  static void updateLastOpenedKiran(BookUserInfo bookUserInfo, int kiranIndex) {
    bookUserInfo.updateLastOpenedKiran(kiranIndex);

    FirebaseIntegrationHelper().onBookUserInfoChanged(bookUserInfo);

    Bookservice().bookUserInfoList = [
      ...?Bookservice().bookUserInfoList?.where(
        (info) => info.partNumber != bookUserInfo.partNumber,
      ),
      bookUserInfo,
    ];

    debugPrint(
      'Updated last opened Kiran to $kiranIndex for Part ${bookUserInfo.partNumber}',
    );
  }

  static void updateKiranUserInfo(KiranUserInfo kiranUserInfo) {
    // Update the KiranUserInfo in the service
    final kiranService = KiranUserService();
    final kiranList = kiranService.kiranUserInfoList;
    final index = kiranList.indexWhere(
      (k) => k.kiranIndex == kiranUserInfo.kiranIndex,
    );
    if (index >= 0) {
      kiranList[index] = kiranUserInfo;
      debugPrint('Updated KiranUserInfo for kiran ${kiranUserInfo.kiranIndex}');

      // Sync to Firebase
      KiranUserService().syncSingleToFirebase(kiranUserInfo);
    }

    // Also update BookUserInfo as before
    BookUserInfo bookUserInfo = Bookservice().getBookUserInfo(
      kiranUserInfo.partNumber,
    );
    Bookservice().bookUserInfoList = [
      ...?Bookservice().bookUserInfoList?.where(
        (info) => info.partNumber != bookUserInfo.partNumber,
      ),
      bookUserInfo,
    ];
  }

  static void removeBookmark(KiranUserInfo kiranUserInfo) {
    BookUserInfo bookUserInfo = Bookservice().getBookUserInfo(
      kiranUserInfo.partNumber,
    );
    bookUserInfo.removeBookmark(kiranUserInfo.kiranIndex);

    FirebaseIntegrationHelper().onBookUserInfoChanged(bookUserInfo);

    Bookservice().bookUserInfoList = [
      ...?Bookservice().bookUserInfoList?.where(
        (info) => info.partNumber != bookUserInfo.partNumber,
      ),
      bookUserInfo,
    ];

    debugPrint(
      'Bookmark removed from Kiran ${kiranUserInfo.kiranIndex} for Part ${bookUserInfo.partNumber}',
    );
  }

  static void applyBookmarkToNextKiran(KiranUserInfo kiranUserInfo) {
    BookUserInfo bookUserInfo = Bookservice().getBookUserInfo(
      kiranUserInfo.partNumber,
    );
    final nextKiranIndex = kiranUserInfo.kiranIndex + 1;
    final endKiranIndex = Bookservice().getEndKiranIndex(
      kiranUserInfo.partNumber,
    );

    // First remove the current bookmark if it exists
    if (bookUserInfo.isKiranBookmarked(kiranUserInfo.kiranIndex)) {
      bookUserInfo.removeBookmark(kiranUserInfo.kiranIndex);
    }

    if (nextKiranIndex <= endKiranIndex) {
      // Add bookmark to next Kiran
      bookUserInfo.addBookmark(nextKiranIndex);

      FirebaseIntegrationHelper().onBookUserInfoChanged(bookUserInfo);
      Bookservice().bookUserInfoList = [
        ...?Bookservice().bookUserInfoList?.where(
          (info) => info.partNumber != bookUserInfo.partNumber,
        ),
        bookUserInfo,
      ];
      debugPrint(
        'Bookmark moved to next Kiran $nextKiranIndex for Part ${bookUserInfo.partNumber}',
      );
    } else {
      // If it's the last Kiran, just remove the bookmark (already done above)
      FirebaseIntegrationHelper().onBookUserInfoChanged(bookUserInfo);
      Bookservice().bookUserInfoList = [
        ...?Bookservice().bookUserInfoList?.where(
          (info) => info.partNumber != bookUserInfo.partNumber,
        ),
        bookUserInfo,
      ];
      debugPrint(
        'Bookmark removed as it was the last Kiran in Part ${bookUserInfo.partNumber}',
      );
    }
  }

  static Future<void> loadUserdatafromFirebase({
    bool includeReadingHistory = false,
  }) async {
    // Check if user is already logged in
    if (FirebaseAuth.instance.currentUser != null) {
      // Load data from Firebase (excluding reading history by default)
      await FirebaseIntegrationHelper().loadDataFromFirebase(
        includeReadingHistory: includeReadingHistory,
      );
    }
  }

  /// Load only reading history from Firebase (call this from reading history page)
  static Future<void> loadReadingHistoryFromFirebase() async {
    // Check if user is already logged in
    if (FirebaseAuth.instance.currentUser != null) {
      // Load only reading history from Firebase
      await FirebaseIntegrationHelper().loadReadingHistoryFromFirebase();
    }
  }

  static Future<void> saveUserDetailsToFirebase(
    String displayName,
    String email,
  ) async {
    await FirebaseIntegrationHelper().saveUserDetailsToFirebase(
      displayName,
      email,
    );
  }

  static Future<UserProfile> getUserProfile() async {
    return await UserProfileService().getUserProfile();
  }

  static Future<void> checkAndPerformMigration({
    Function(String message, double progress)? onProgress,
  }) async {
    debugPrint('Checking and performing data migration if needed...');
    onProgress?.call('Migrating reading history...', 0.25);
    await ReadingHistoryMigrationService().autoMigrateCurrentUser();
    debugPrint('Finished migrating reading history.');
    onProgress?.call('Migrating kiran progress...', 0.75);
    await KiranUserInfoMigrationService().autoMigrateCurrentUser();
    debugPrint('Finished migrating Kiran user info.');
    onProgress?.call('Migration complete', 1.0);
  }

  // Apple Sign-In user data cache management
  // This is crucial because Apple only provides user info on FIRST sign-in

  static const String _appleUserCacheKey = 'apple_user_cache';

  // Cache Apple user data securely for subsequent sign-ins
  static Future<void> cacheAppleUserData({
    required String userIdentifier,
    required String? email,
    required String? givenName,
    required String? familyName,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final userData = {
      'userIdentifier': userIdentifier,
      'email': email,
      'givenName': givenName,
      'familyName': familyName,
      'cachedAt': DateTime.now().toIso8601String(),
    };

    // Store as JSON string
    final existingCache = prefs.getString(_appleUserCacheKey);
    Map<String, dynamic> cache = {};

    if (existingCache != null) {
      try {
        cache = json.decode(existingCache) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('Error parsing existing Apple user cache: $e');
      }
    }

    cache[userIdentifier] = userData;
    await prefs.setString(_appleUserCacheKey, json.encode(cache));

    debugPrint('Cached Apple user data for: $userIdentifier');
    debugPrint('Cached data: $userData');
  }

  // Retrieve cached Apple user data for subsequent sign-ins
  static Future<Map<String, dynamic>?> getCachedAppleUserData(
    String userIdentifier,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final cacheString = prefs.getString(_appleUserCacheKey);

    if (cacheString == null) return null;

    try {
      final cache = json.decode(cacheString) as Map<String, dynamic>;
      final userData = cache[userIdentifier] as Map<String, dynamic>?;

      if (userData != null) {
        debugPrint('Retrieved cached Apple user data for: $userIdentifier');
        debugPrint('Cached data: $userData');
        return userData;
      }
    } catch (e) {
      debugPrint('Error retrieving cached Apple user data: $e');
    }

    return null;
  }

  // Clear cached Apple user data (useful for testing or user logout)
  static Future<void> clearAppleUserCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_appleUserCacheKey);
    debugPrint('Cleared Apple user cache');
  }

  // Debug method to show cached Apple user data
  static Future<void> debugAppleUserCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cacheString = prefs.getString(_appleUserCacheKey);

    if (cacheString != null) {
      try {
        final cache = json.decode(cacheString) as Map<String, dynamic>;
        debugPrint('=== Apple User Cache Contents ===');
        cache.forEach((key, value) {
          debugPrint('User ID: $key');
          debugPrint('Data: $value');
          debugPrint('---');
        });
      } catch (e) {
        debugPrint('Error reading Apple user cache: $e');
      }
    } else {
      debugPrint('Apple user cache is empty');
    }
  }

  static void showLoginWarningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.login_required),
            content: Text(AppLocalizations.of(context)!.login_to_sync_progress),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pushNamed(context, '/login');
                },
                child: Text(AppLocalizations.of(context)!.login),
              ),
            ],
          ),
    );
  }

  static Future<bool> shouldNavigateToProfile() async {
    try {
      final profileService = UserProfileService();
      final profile = await profileService.getUserProfile();

      // Check if profile has essential information (name fields)
      if (profile.firstName.isNotEmpty && profile.lastName.isNotEmpty) {
        debugPrint('User has complete profile - going to HomePage');
        return false; // Has profile, go to HomePage
      } else {
        debugPrint('User profile incomplete - going to Profile Page');
        return true; // No or incomplete profile, go to Profile Page
      }
    } catch (e) {
      debugPrint(
        'Error checking profile, assuming new user - going to Profile Page: $e',
      );
      return true; // Error or no profile, go to Profile Page for setup
    }
  }
}
