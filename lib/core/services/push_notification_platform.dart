/// Data extracted from a browser `PushSubscription`.
class PushSubscriptionData {
  final String endpoint;
  final String p256dh;
  final String auth;

  const PushSubscriptionData({
    required this.endpoint,
    required this.p256dh,
    required this.auth,
  });

  Map<String, dynamic> toMap() => {
        'endpoint': endpoint,
        'p256dh': p256dh,
        'auth': auth,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PushSubscriptionData &&
          runtimeType == other.runtimeType &&
          endpoint == other.endpoint &&
          p256dh == p256dh &&
          auth == other.auth;

  @override
  int get hashCode => Object.hash(endpoint, p256dh, auth);
}

/// Platform abstraction for Web Push & PWA display-mode detection.
abstract class PushNotificationPlatform {
  /// Whether the current platform supports Web Push.
  bool get isSupported;

  /// Whether the app is running in PWA `standalone` display mode.
  bool get isStandalone;

  /// Whether the current browser is iOS Safari (where push requires standalone).
  bool get isIosSafari;

  /// Current `Notification.permission` state: `'granted'`, `'denied'`, or `'default'`.
  String get permissionState;

  /// Pre-warms the `/push-scope/` service worker registration so that
  /// [subscribe] can invoke `pushManager.subscribe()` as the first `await`
  /// inside a user-gesture handler.
  Future<void> prepare();

  /// Subscribes to Web Push using [vapidPublicKey] against the `/push-scope/`
  /// service worker registration.
  Future<PushSubscriptionData?> subscribe(String vapidPublicKey);
}
