import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/services/remote_config_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Widget to show maintenance mode screen
class MaintenanceModeScreen extends StatelessWidget {
  const MaintenanceModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final remoteConfig = RemoteConfigService();

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.build,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Under Maintenance',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                remoteConfig.maintenanceMessage,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  // Try to refresh config
                  final success = await remoteConfig.fetchConfig();
                  if (!success) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Still under maintenance. Please check back later.',
                          ),
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Check Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget to show update required dialog
class UpdateRequiredDialog extends StatelessWidget {
  const UpdateRequiredDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final remoteConfig = RemoteConfigService();

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.system_update, color: Colors.orange),
          SizedBox(width: 8),
          Text('Update Required'),
        ],
      ),
      content: Text(remoteConfig.updateMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Later'),
        ),
        ElevatedButton(
          onPressed: () async {
            // Open app store
            final url =
                Theme.of(context).platform == TargetPlatform.iOS
                    ? 'https://apps.apple.com/app/id6739144754' // Replace with your iOS app ID
                    : 'https://play.google.com/store/apps/details?id=com.astound.SaxatSavita'; // Replace with your Android package name

            if (await canLaunchUrl(Uri.parse(url))) {
              await launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              );
            }
          },
          child: const Text('Update Now'),
        ),
      ],
    );
  }
}

/// Widget to show announcement banner
class AnnouncementBanner extends StatelessWidget {
  const AnnouncementBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final remoteConfig = RemoteConfigService();

    if (!remoteConfig.announcementEnabled ||
        remoteConfig.announcementMessage.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (remoteConfig.announcementTitle.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.campaign,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    remoteConfig.announcementTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Text(
            remoteConfig.announcementMessage,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Widget to conditionally show features based on remote config
class ConditionalFeature extends StatelessWidget {
  final String featureKey;
  final Widget child;
  final Widget? fallback;

  const ConditionalFeature({
    super.key,
    required this.featureKey,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final remoteConfig = RemoteConfigService();

    if (remoteConfig.isFeatureEnabled(featureKey)) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}

/// Mixin to check app version and show update dialog
mixin RemoteConfigVersionCheck<T extends StatefulWidget> on State<T> {
  Future<void> checkAppVersion(BuildContext context) async {
    final remoteConfig = RemoteConfigService();

    // Get current version from package info
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      // Check if update is required
      if (remoteConfig.forceUpdateRequired &&
          remoteConfig.needsUpdate(currentVersion)) {
        if (context.mounted) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const UpdateRequiredDialog(),
          );
        }
      } else if (remoteConfig.hasNewerVersion(currentVersion)) {
        // Show optional update dialog
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (context) => const UpdateRequiredDialog(),
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking app version: $e');
    }
  }
}
