import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';

class InAppUpdateService {
  static final InAppUpdateService _instance = InAppUpdateService._internal();
  factory InAppUpdateService() => _instance;
  InAppUpdateService._internal();

  /// Check for available updates
  Future<void> checkForUpdate(
    BuildContext context, {
    bool isManualCheck = false,
  }) async {
    try {
      if (Platform.isAndroid) {
        await _checkAndroidUpdate(context, isManualCheck: isManualCheck);
      } else if (Platform.isIOS) {
        await _checkIOSUpdate(context, isManualCheck: isManualCheck);
      }
    } catch (e) {
      debugPrint('Error checking for updates: $e');
      if (isManualCheck && context.mounted) {
        _handleUpdateError(context, e);
      }
    }
  }

  /// Check for Android updates using Google Play In-App Updates
  Future<void> _checkAndroidUpdate(
    BuildContext context, {
    bool isManualCheck = false,
  }) async {
    if (kDebugMode) return;
    try {
      final updateInfo = await InAppUpdate.checkForUpdate();

      if (updateInfo.updateAvailability == UpdateAvailability.updateAvailable) {
        if (context.mounted) {
          await _showUpdateDialog(
            context,
            updateInfo,
            isManualCheck: isManualCheck,
          );
        }
      } else if (isManualCheck && context.mounted) {
        _showNoUpdateDialog(context);
      }
    } catch (e) {
      debugPrint('Android update check failed: $e');
      debugPrint(
        'Manual check: $isManualCheck, Context mounted: ${context.mounted}',
      );
      if (isManualCheck && context.mounted) {
        _handleUpdateError(context, e);
      } else if (!isManualCheck) {
        debugPrint(
          'Automatic check failed - suppressing error dialog to avoid interrupting user',
        );
      }
    }
  }

  /// Check for iOS updates by directing to App Store
  Future<void> _checkIOSUpdate(
    BuildContext context, {
    bool isManualCheck = false,
  }) async {
    try {
      // For iOS, we can't check programmatically, so we show an option to visit App Store
      if (isManualCheck && context.mounted) {
        await _showIOSUpdateDialog(context);
      }
    } catch (e) {
      debugPrint('iOS update check failed: $e');
      if (isManualCheck && context.mounted) {
        _showErrorDialog(context, e.toString());
      }
    }
  }

  /// Show update dialog for Android
  Future<void> _showUpdateDialog(
    BuildContext context,
    AppUpdateInfo updateInfo, {
    bool isManualCheck = false,
  }) async {
    final localizations = AppLocalizations.of(context)!;

    return showDialog<void>(
      context: context,
      barrierDismissible: !updateInfo.immediateUpdateAllowed,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.system_update,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(localizations.updateAvailable),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(localizations.updateAvailableMessage),
              const SizedBox(height: 16),
              if (updateInfo.immediateUpdateAllowed)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.priority_high,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          localizations.criticalUpdateMessage,
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onErrorContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          actions: [
            if (!updateInfo.immediateUpdateAllowed)
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(localizations.later),
              ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _performUpdate(context, updateInfo);
              },
              child: Text(localizations.updateNow),
            ),
          ],
        );
      },
    );
  }

  /// Show iOS update dialog
  Future<void> _showIOSUpdateDialog(BuildContext context) async {
    final localizations = AppLocalizations.of(context)!;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.system_update,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(localizations.checkForUpdates),
            ],
          ),
          content: Text(localizations.iOSUpdateMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _openAppStore();
              },
              child: Text(localizations.openAppStore),
            ),
          ],
        );
      },
    );
  }

  /// Show no update available dialog
  void _showNoUpdateDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(localizations.upToDate),
            ],
          ),
          content: Text(localizations.noUpdateAvailable),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.ok),
            ),
          ],
        );
      },
    );
  }

  /// Handle update errors with specific error messages
  void _handleUpdateError(BuildContext context, dynamic error) {
    debugPrint('_handleUpdateError called with: $error');
    final localizations = AppLocalizations.of(context)!;
    String errorMessage;
    String errorTitle = localizations.error;

    // Handle specific error cases
    String errorString = error.toString().toUpperCase();
    if (errorString.contains('ERROR_APP_NOT_OWNED') ||
        errorString.contains('INSTALL ERROR(-10)') ||
        errorString.contains('APP IS NOT OWNED') ||
        (errorString.contains('TASK_FAILURE') && errorString.contains('-10'))) {
      errorTitle = 'Development Mode';
      errorMessage =
          'In-app updates are only available for apps installed from Google Play Store. '
          'This app appears to be installed in debug/development mode. '
          'To test updates, install the app from Google Play Store or use internal testing.';
    } else if (errorString.contains('TASK_FAILURE')) {
      errorMessage =
          'Update service temporarily unavailable. Please try again later or '
          'check the Google Play Store directly for updates.';
    } else if (errorString.contains('UPDATE_NOT_AVAILABLE')) {
      errorMessage = localizations.noUpdateAvailable;
    } else {
      errorMessage = '${localizations.updateCheckFailed}: ${error.toString()}';
    }

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                (errorString.contains('ERROR_APP_NOT_OWNED') ||
                        errorString.contains('INSTALL ERROR(-10)') ||
                        errorString.contains('APP IS NOT OWNED') ||
                        (errorString.contains('TASK_FAILURE') &&
                            errorString.contains('-10')))
                    ? Icons.info
                    : Icons.error,
                color:
                    (errorString.contains('ERROR_APP_NOT_OWNED') ||
                            errorString.contains('INSTALL ERROR(-10)') ||
                            errorString.contains('APP IS NOT OWNED') ||
                            (errorString.contains('TASK_FAILURE') &&
                                errorString.contains('-10')))
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Text(errorTitle),
            ],
          ),
          content: Text(errorMessage),
          actions: [
            if (errorString.contains('ERROR_APP_NOT_OWNED') ||
                errorString.contains('INSTALL ERROR(-10)') ||
                errorString.contains('APP IS NOT OWNED') ||
                (errorString.contains('TASK_FAILURE') &&
                    errorString.contains('-10')))
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _openPlayStore();
                },
                child: const Text('Open Play Store'),
              ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.ok),
            ),
          ],
        );
      },
    );
  }

  /// Show error dialog (legacy method for backward compatibility)
  void _showErrorDialog(BuildContext context, String error) {
    _handleUpdateError(context, error);
  }

  /// Perform the actual update
  Future<void> _performUpdate(
    BuildContext context,
    AppUpdateInfo updateInfo,
  ) async {
    try {
      if (updateInfo.immediateUpdateAllowed) {
        // Immediate update - app will restart automatically
        await InAppUpdate.performImmediateUpdate();
      } else if (updateInfo.flexibleUpdateAllowed) {
        // Flexible update - user can continue using app while downloading
        await InAppUpdate.startFlexibleUpdate();

        // Listen for download completion
        InAppUpdate.completeFlexibleUpdate().then((_) {
          if (context.mounted) {
            _showFlexibleUpdateCompleteDialog(context);
          }
        });
      }
    } catch (e) {
      debugPrint('Update failed: $e');
      if (context.mounted) {
        _handleUpdateError(context, e);
      }
    }
  }

  /// Show flexible update complete dialog
  void _showFlexibleUpdateCompleteDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.download_done,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(localizations.updateReady),
            ],
          ),
          content: Text(localizations.updateReadyMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(localizations.later),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await InAppUpdate.completeFlexibleUpdate();
              },
              child: Text(localizations.restartNow),
            ),
          ],
        );
      },
    );
  }

  /// Open App Store for iOS
  Future<void> _openAppStore() async {
    // You can find this in App Store Connect after publishing
    const appStoreId = '1444597643'; // Example ID - replace with your actual ID
    final url = 'https://apps.apple.com/app/id$appStoreId';

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch App Store URL: $url');
    }
  }

  /// Open Google Play Store for Android
  Future<void> _openPlayStore() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final packageName = packageInfo.packageName;
      final url = 'https://play.google.com/store/apps/details?id=$packageName';

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch Play Store URL: $url');
      }
    } catch (e) {
      debugPrint('Error opening Play Store: $e');
    }
  }

  /// Check for updates automatically on app start (background check)
  Future<void> checkForUpdateOnAppStart(BuildContext context) async {
    // Only check automatically on Android, and only if app has been running for a while
    if (Platform.isAndroid) {
      await Future.delayed(const Duration(seconds: 3));
      if (context.mounted) {
        await checkForUpdate(context, isManualCheck: false);
      }
    }
  }

  /// Get current app version
  Future<String> getCurrentVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return '${packageInfo.version}+${packageInfo.buildNumber}';
  }

  /// Test error dialog (for debugging purposes)
  void testErrorDialog(BuildContext context) {
    const testError =
        'PlatformException(TASK_FAILURE, -10: Install Error(-10): The app is not owned by any user on this device. An app is "owned" if it has been acquired from Play. (https://developer.android.com/reference/com/google/android/play/core/install/model/InstallErrorCode#ERROR_APP_NOT_OWNED), null, null)';
    _handleUpdateError(context, testError);
  }
}
