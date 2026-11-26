import 'push_notification_platform.dart';
import 'push_notification_platform_stub.dart'
    if (dart.library.js_interop) 'push_notification_platform_web.dart';

export 'push_notification_platform.dart'
    show PushNotificationPlatform, PushSubscriptionData;

/// Service for managing browser Web Push permission and subscriptions.
class PushNotificationService {
  final String vapidPublicKey;
  final PushNotificationPlatform _platform;

  PushNotificationService({
    required this.vapidPublicKey,
    PushNotificationPlatform? platform,
  }) : _platform = platform ?? createPushNotificationPlatform();

  /// Whether a VAPID public key is configured.
  bool get hasVapidKey => vapidPublicKey.isNotEmpty;

  /// Whether Web Push is supported in the current environment.
  bool get isSupported => _platform.isSupported && hasVapidKey;

  /// Whether the app is running in PWA `standalone` display mode.
  bool get isStandalone => _platform.isStandalone;

  /// Whether the current browser is iOS Safari.
  bool get isIosSafari => _platform.isIosSafari;

  /// Whether iOS requires installing the PWA before push can be enabled.
  ///
  /// Checked independently of [isSupported] because real iOS Safari omits
  /// `window.PushManager` and `window.Notification` until installed to Home Screen.
  bool get needsIosHomeScreenInstall => hasVapidKey && isIosSafari && !isStandalone;

  /// Current `Notification.permission` state: `'granted'`, `'denied'`, or `'default'`.
  String get permissionState => _platform.permissionState;

  /// Pre-warms the `/push-scope/` service worker registration.
  Future<void> prepare() => _platform.prepare();

  /// Requests permission and subscribes to Web Push.
  ///
  /// Returns `null` if unsupported, denied, or if `vapidPublicKey` is empty.
  Future<PushSubscriptionData?> requestAndSubscribe() async {
    if (!isSupported) return null;
    if (needsIosHomeScreenInstall) return null;
    return _platform.subscribe(vapidPublicKey);
  }
}
