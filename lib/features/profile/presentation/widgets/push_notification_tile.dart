import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/core/services/push_notification_provider.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';

/// Profile settings tile for enabling Web Push setlist notifications.
class PushNotificationTile extends ConsumerWidget {
  /// Optional section header (e.g. divider + title) rendered only when the
  /// tile itself is visible.
  final Widget? header;

  const PushNotificationTile({super.key, this.header});

  Widget _withHeader(Widget tile) {
    if (header == null) return tile;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [header!, tile],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kIsWeb) return const SizedBox.shrink();

    final service = ref.watch(pushNotificationServiceProvider);

    // Check iOS non-standalone before isSupported, because real iOS Safari
    // does not expose PushManager/Notification until added to Home Screen.
    if (service.needsIosHomeScreenInstall) {
      return _withHeader(
        const ListTile(
          leading: Icon(Icons.install_mobile, color: AppColors.primary),
          title: Text('Setlist Notifications'),
          subtitle: Text(
            'Tap Share → "Add to Home Screen" in Safari to enable push alerts.',
          ),
        ),
      );
    }

    if (!service.isSupported) return const SizedBox.shrink();

    final permissionAsync = ref.watch(pushPermissionProvider);
    return permissionAsync.when(
      loading: () => _withHeader(
        const ListTile(
          leading: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          title: Text('Setlist Notifications'),
          subtitle: Text('Checking notification status...'),
        ),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (granted) {
        if (granted == true) {
          return _withHeader(
            const ListTile(
              leading: Icon(Icons.notifications_active, color: AppColors.success),
              title: Text('Setlist Notifications'),
              subtitle: Text('Enabled for shared setlist updates'),
            ),
          );
        }

        if (granted == false) {
          return _withHeader(
            const ListTile(
              leading: Icon(Icons.notifications_off_outlined, color: Colors.grey),
              title: Text('Setlist Notifications Blocked'),
              subtitle: Text('Allow notifications in browser settings to enable'),
            ),
          );
        }

        return _withHeader(
          ListTile(
            leading: const Icon(
              Icons.notifications_outlined,
              color: AppColors.primary,
            ),
            title: const Text('Setlist Notifications'),
            subtitle: const Text('Get alerted when shared setlists are updated'),
            trailing: FilledButton.tonal(
              onPressed: () {
                ref
                    .read(pushPermissionProvider.notifier)
                    .enableNotifications();
              },
              child: const Text('Enable'),
            ),
          ),
        );
      },
    );
  }
}
