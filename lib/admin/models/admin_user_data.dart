class AdminUserData {
  final String userId;
  final String email;
  final String displayName;
  final String signInProvider;
  final DateTime? createdAt;
  final DateTime? lastActivityDate;
  final int totalReadings;
  final int totalBookmarks;
  final Map<String, dynamic> appSettings;
  final List<Map<String, dynamic>> bookUserInfo;
  final List<Map<String, dynamic>> kiranUserInfo;
  final List<Map<String, dynamic>> readingHistory;
  final List<Map<String, dynamic>> readingPlans;
  final Map<String, dynamic> userProfile;

  AdminUserData({
    required this.userId,
    required this.email,
    required this.displayName,
    required this.signInProvider,
    this.createdAt,
    this.lastActivityDate,
    required this.totalReadings,
    required this.totalBookmarks,
    required this.appSettings,
    required this.bookUserInfo,
    required this.kiranUserInfo,
    required this.readingHistory,
    required this.readingPlans,
    required this.userProfile,
  });

  factory AdminUserData.fromFirestore({
    required String userId,
    required Map<String, dynamic> userData,
    required Map<String, dynamic> appSettings,
    required List<Map<String, dynamic>> bookUserInfo,
    required List<Map<String, dynamic>> kiranUserInfo,
    required List<Map<String, dynamic>> readingHistory,
    required List<Map<String, dynamic>> readingPlans,
    required Map<String, dynamic> userProfile,
  }) {
    // Calculate total readings from reading history
    final totalReadings = readingHistory.length;

    // Calculate total bookmarks from kiran user info
    final totalBookmarks =
        kiranUserInfo.where((kiran) => kiran['isBookmarked'] == true).length;

    // Parse dates safely
    DateTime? parseTimestamp(dynamic timestamp) {
      if (timestamp == null) return null;
      if (timestamp is DateTime) return timestamp;
      if (timestamp.runtimeType.toString() == 'Timestamp') {
        return timestamp.toDate();
      }
      return null;
    }

    return AdminUserData(
      userId: userId,
      email: userData['email'] ?? '',
      displayName: userData['displayName'] ?? '',
      signInProvider: _extractSignInProvider(userData['providerData']),
      createdAt: parseTimestamp(userData['metadata']?['creationTime']),
      lastActivityDate: parseTimestamp(userData['metadata']?['lastSignInTime']),
      totalReadings: totalReadings,
      totalBookmarks: totalBookmarks,
      appSettings: appSettings,
      bookUserInfo: bookUserInfo,
      kiranUserInfo: kiranUserInfo,
      readingHistory: readingHistory,
      readingPlans: readingPlans,
      userProfile: userProfile,
    );
  }

  static String _extractSignInProvider(dynamic providerData) {
    if (providerData is List && providerData.isNotEmpty) {
      final provider = providerData[0]['providerId'] ?? '';
      switch (provider) {
        case 'google.com':
          return 'Google';
        case 'apple.com':
          return 'Apple';
        case 'password':
          return 'Email';
        default:
          return provider.isEmpty ? 'Unknown' : provider;
      }
    }
    return 'Unknown';
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'signInProvider': signInProvider,
      'createdAt': createdAt?.toIso8601String(),
      'lastActivityDate': lastActivityDate?.toIso8601String(),
      'totalReadings': totalReadings,
      'totalBookmarks': totalBookmarks,
      'appSettings': appSettings,
      'bookUserInfo': bookUserInfo,
      'kiranUserInfo': kiranUserInfo,
      'readingHistory': readingHistory,
      'readingPlans': readingPlans,
      'userProfile': userProfile,
    };
  }

  // Helper methods for analytics
  int get bookPartsRead {
    return bookUserInfo.where((part) => part['isCompleted'] == true).length;
  }

  int get bookPartsInProgress {
    return bookUserInfo
        .where(
          (part) =>
              part['currentKiranIndex'] != null &&
              part['currentKiranIndex'] > 0 &&
              part['isCompleted'] != true,
        )
        .length;
  }

  double get overallProgress {
    if (bookUserInfo.isEmpty) return 0.0;

    final totalProgress = bookUserInfo.fold<double>(0.0, (sum, part) {
      final currentKiran = part['currentKiranIndex'] ?? 0;
      final totalKirans = part['totalKirans'] ?? 1;
      return sum + (currentKiran / totalKirans);
    });

    return totalProgress / bookUserInfo.length;
  }

  DateTime? get lastReadingDate {
    if (readingHistory.isEmpty) return null;

    DateTime? latest;
    for (final reading in readingHistory) {
      final dateRead = reading['dateRead'];
      if (dateRead != null) {
        DateTime? parsedDate;
        if (dateRead is DateTime) {
          parsedDate = dateRead;
        } else if (dateRead.runtimeType.toString() == 'Timestamp') {
          parsedDate = dateRead.toDate();
        }

        if (parsedDate != null &&
            (latest == null || parsedDate.isAfter(latest))) {
          latest = parsedDate;
        }
      }
    }

    return latest;
  }

  List<String> get favoriteBookParts {
    return bookUserInfo
        .where((part) => part['isFavorite'] == true)
        .map((part) => 'Part ${part['partNumber']}')
        .toList();
  }

  int get streakDays {
    // Calculate reading streak from reading history
    if (readingHistory.isEmpty) return 0;

    // Sort reading history by date (newest first)
    final sortedReadings = List<Map<String, dynamic>>.from(readingHistory);
    sortedReadings.sort((a, b) {
      final aDate = _parseReadingDate(a['dateRead']);
      final bDate = _parseReadingDate(b['dateRead']);
      if (aDate == null && bDate == null) return 0;
      if (aDate == null) return 1;
      if (bDate == null) return -1;
      return bDate.compareTo(aDate);
    });

    int streak = 0;
    DateTime? lastDate;
    final today = DateTime.now();

    for (final reading in sortedReadings) {
      final readDate = _parseReadingDate(reading['dateRead']);
      if (readDate == null) continue;

      // Normalize to date only (ignore time)
      final readDateOnly = DateTime(
        readDate.year,
        readDate.month,
        readDate.day,
      );
      final todayOnly = DateTime(today.year, today.month, today.day);

      if (lastDate == null) {
        // First reading - check if it's today or yesterday
        final daysDiff = todayOnly.difference(readDateOnly).inDays;
        if (daysDiff <= 1) {
          streak = 1;
          lastDate = readDateOnly;
        } else {
          break; // Reading too old to start streak
        }
      } else {
        // Check if this reading is consecutive
        final daysDiff = lastDate.difference(readDateOnly).inDays;
        if (daysDiff == 1) {
          streak++;
          lastDate = readDateOnly;
        } else {
          break; // Gap in readings
        }
      }
    }

    return streak;
  }

  DateTime? _parseReadingDate(dynamic dateValue) {
    if (dateValue == null) return null;
    if (dateValue is DateTime) return dateValue;
    if (dateValue.runtimeType.toString() == 'Timestamp') {
      return dateValue.toDate();
    }
    return null;
  }
}
