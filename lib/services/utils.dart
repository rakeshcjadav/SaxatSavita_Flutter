import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/helpers/firebase_integration_helper.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/models/bookuserinfo_model.dart';
import 'package:saxatsavita_flutter/models/kiranuserinfo_model.dart';
import 'package:saxatsavita_flutter/services/appdataservice.dart';
import 'package:saxatsavita_flutter/services/bookservice.dart';
import 'package:saxatsavita_flutter/services/kiranuser_info_migration_service.dart';
import 'package:saxatsavita_flutter/services/kiranuser_service.dart';
import 'package:saxatsavita_flutter/services/reading_history_migration_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Utils {
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

  static Future<void> loadUserdatafromFirebase() async {
    // Check if user is already logged in
    if (FirebaseAuth.instance.currentUser != null) {
      // Load data from Firebase
      await FirebaseIntegrationHelper().loadDataFromFirebase();
    }
  }

  static Future<void> saveUserDetailsToFirebase() async {
    await FirebaseIntegrationHelper().saveUserDetailsToFirebase();
  }

  static Future<void> saveAppleUserDetailsToFirebase(
    String displayName,
    String email,
  ) async {
    await FirebaseIntegrationHelper().saveAppleUserDetailsToFirebase(
      displayName,
      email,
    );
  }

  static Future<Map<String, String>> getUserInfoSummary() async {
    return await AppDataService().getUserInfoSummary();
  }

  static Future<void> checkAndPerformMigration() async {
    debugPrint('Checking and performing data migration if needed...');
    await ReadingHistoryMigrationService().autoMigrateCurrentUser();
    debugPrint('Finished migrating reading history.');
    await KiranUserInfoMigrationService().autoMigrateCurrentUser();
    debugPrint('Finished migrating Kiran user info.');
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
}
