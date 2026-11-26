import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/core/services/push_notification_provider.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';

/// Profile settings tile for enabling Web Push setlist notifications.
class PushNotificationTile extends ConsumerWidget {
  const PushNotificationTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kIsWeb) return const SizedBox.shrink();

    final service = ref.watch(pushNotificationServiceProvider);
    if (!service.isSupported) return const SizedBox.shrink();

    if (service.needsIosHomeScreenInstall) {
      return const ListTile(
        leading: Icon(Icons.install_mobile, color: AppColors.primary),
        title: Text('Setlist Notifications'),
        subtitle: Text(
          'Tap Share → "Add to Home Screen" in Safari to enable push alerts.',
        ),
      );
    }

    final permissionAsync = ref.watch(pushPermissionProvider);
    return permissionAsync.when(
      loading: () => const ListTile(
        leading: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('Setlist Notifications'),
        subtitle: Text('Checking notification status...'),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (granted) {
        if (granted == true) {
          return const ListTile(
            leading: Icon(Icons.notifications_active, color: AppColors.success),
            title: Text('Setlist Notifications'),
            subtitle: Text('Enabled for shared setlist updates'),
          );
        }

        if (granted == false) {
          return const ListTile(
            leading: Icon(Icons.notifications_off_outlined, color: Colors.grey),
            title: Text('Setlist Notifications Blocked'),
            subtitle: Text('Allow notifications in browser settings to enable'),
          );
        }

        return ListTile(
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
        );
      },
    );
  }
}
