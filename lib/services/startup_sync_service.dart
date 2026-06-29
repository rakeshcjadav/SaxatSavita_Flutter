import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:saxatsavita_flutter/services/user_profile_service.dart';
import 'package:saxatsavita_flutter/services/utils.dart';

/// Post-auth data sync that runs off the splash / sign-in critical path.
class StartupSyncService {
  static final StartupSyncService _instance = StartupSyncService._internal();
  factory StartupSyncService() => _instance;
  StartupSyncService._internal();

  static bool _syncInProgress = false;

  /// Runs Firebase user-data sync in the background after navigation.
  static void syncSignedInUserDataInBackground() {
    if (FirebaseAuth.instance.currentUser == null || _syncInProgress) {
      return;
    }

    unawaited(_syncSignedInUserData());
  }

  static Future<void> _syncSignedInUserData() async {
    _syncInProgress = true;
    try {
      if (Utils.enableLegacyDataMigration) {
        await Utils.checkAndPerformMigration();
      }

      await Utils.loadUserdatafromFirebase();
      await UserProfileService().syncFromFirebase();
    } catch (e, stackTrace) {
      debugPrint('Background startup sync failed: $e');
      debugPrint('$stackTrace');
    } finally {
      _syncInProgress = false;
    }
  }
}
