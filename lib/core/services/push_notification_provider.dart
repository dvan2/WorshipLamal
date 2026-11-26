import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/core/config/env_config.dart';
import 'package:worship_lamal/core/config/supabase_config.dart';

import 'push_notification_service.dart';
import 'push_subscription_repository.dart';

/// Provides the browser Web Push service.
final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService(vapidPublicKey: EnvConfig.vapidPublicKey);
});

/// Provides the Supabase push subscription repository.
final pushSubscriptionRepositoryProvider =
    Provider<PushSubscriptionRepository>((ref) {
  return PushSubscriptionRepository(ref.watch(supabaseClientProvider));
});

/// Manages Web Push permission & subscription state.
///
/// State values:
/// - `true`: permission granted and subscription active
/// - `false`: permission denied or unsupported
/// - `null`: permission not yet requested (`default`) or unsupported platform
final pushPermissionProvider =
    AsyncNotifierProvider<PushPermissionNotifier, bool?>(
  PushPermissionNotifier.new,
);

class PushPermissionNotifier extends AsyncNotifier<bool?> {
  @override
  Future<bool?> build() async {
    final service = ref.watch(pushNotificationServiceProvider);
    if (!service.isSupported) return null;

    // Pre-warm the /push-scope/ SW registration so pushManager.subscribe()
    // can run as the very first await inside the user-gesture handler.
    await service.prepare();

    return switch (service.permissionState) {
      'granted' => true,
      'denied' => false,
      _ => null,
    };
  }

  /// Requests notification permission and saves the resulting subscription.
  ///
  /// Must be invoked directly from a user-gesture callback (e.g. button tap).
  Future<void> enableNotifications() async {
    final service = ref.read(pushNotificationServiceProvider);
    final repo = ref.read(pushSubscriptionRepositoryProvider);

    state = const AsyncLoading();
    try {
      final sub = await service.requestAndSubscribe();
      if (sub != null) {
        await repo.saveSubscription(sub);
        state = const AsyncData(true);
      } else {
        final current = service.permissionState;
        if (current == 'denied') {
          state = const AsyncData(false);
        } else {
          state = AsyncError(
            StateError('Could not subscribe to push notifications.'),
            StackTrace.current,
          );
        }
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
