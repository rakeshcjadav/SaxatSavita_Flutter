import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/models/bookuserinfo_model.dart';
import 'package:saxatsavita_flutter/models/kiranuserinfo_model.dart';
import 'package:saxatsavita_flutter/services/bookservice.dart';

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
}
