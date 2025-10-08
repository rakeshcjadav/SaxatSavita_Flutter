import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/helpers/firebase_integration_helper.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/models/bookuserinfo_model.dart';
import 'package:saxatsavita_flutter/models/kiranuserinfo_model.dart';
import 'package:saxatsavita_flutter/services/bookservice.dart';
import 'package:saxatsavita_flutter/services/kiranuser_service.dart';

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
    return kiranUserInfo.kiranIndex == bookUserInfo.bookmarkKiranIndex;
  }

  static void setBookmark(KiranUserInfo kiranUserInfo) {
    BookUserInfo bookUserInfo = Bookservice().getBookUserInfo(
      kiranUserInfo.partNumber,
    );
    if (kiranUserInfo.kiranIndex == bookUserInfo.bookmarkKiranIndex) {
      // Remove bookmark
      //bookUserInfo.bookmarkKiranIndex = -1;
      return;
    } else {
      // Set bookmark
      bookUserInfo.bookmarkKiranIndex = kiranUserInfo.kiranIndex;
      bookUserInfo.updatedAt = DateTime.now();

      FirebaseIntegrationHelper().onBookUserInfoChanged(bookUserInfo);
    }
    Bookservice().bookUserInfoList = [
      ...?Bookservice().bookUserInfoList?.where(
        (info) => info.partNumber != bookUserInfo.partNumber,
      ),
      bookUserInfo,
    ];

    // Print updated bookmark info
    debugPrint(
      'Bookmark set to Kiran ${bookUserInfo.bookmarkKiranIndex} for Part ${bookUserInfo.partNumber}',
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

  static void removeBookmark(KiranUserInfo kiranUserInfo) {}

  static void applyBookmarkToNextKiran(KiranUserInfo kiranUserInfo) {
    BookUserInfo bookUserInfo = Bookservice().getBookUserInfo(
      kiranUserInfo.partNumber,
    );
    final nextKiranIndex = kiranUserInfo.kiranIndex + 1;
    // Assuming you have a method to get total Kirans in the part
    final endKiranIndex = Bookservice().getEndKiranIndex(
      kiranUserInfo.partNumber,
    );
    if (nextKiranIndex <= endKiranIndex) {
      bookUserInfo.bookmarkKiranIndex = nextKiranIndex;
      bookUserInfo.updatedAt = DateTime.now();
      FirebaseIntegrationHelper().onBookUserInfoChanged(bookUserInfo);
      Bookservice().bookUserInfoList = [
        ...?Bookservice().bookUserInfoList?.where(
          (info) => info.partNumber != bookUserInfo.partNumber,
        ),
        bookUserInfo,
      ];
      debugPrint(
        'Bookmark moved to next Kiran ${bookUserInfo.bookmarkKiranIndex} for Part ${bookUserInfo.partNumber}',
      );
    } else {
      // If it's the last Kiran, remove the bookmark
      bookUserInfo.bookmarkKiranIndex = Bookservice().getStartKiranIndex(
        kiranUserInfo.partNumber,
      );
      bookUserInfo.updatedAt = DateTime.now();
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

  static void loadUserdatafromFirebase() async {
    // Check if user is already logged in
    if (FirebaseAuth.instance.currentUser != null) {
      // Load data from Firebase
      await FirebaseIntegrationHelper().loadDataFromFirebase();

      // Setup auto-sync
      //FirebaseIntegrationHelper().setupAutoSync();
    }
  }
}
