import 'push_notification_platform.dart';

/// Non-web stub implementation of [PushNotificationPlatform].
class StubPushNotificationPlatform implements PushNotificationPlatform {
  @override
  bool get isSupported => false;

  @override
  bool get isStandalone => false;

  @override
  bool get isIosSafari => false;

  @override
  String get permissionState => 'denied';

  @override
  Future<void> prepare() async {}

  @override
  Future<PushSubscriptionData?> subscribe(String vapidPublicKey) async => null;

  @override
  Future<PushSubscriptionData?> getSubscription() async => null;
}

PushNotificationPlatform createPushNotificationPlatform() =>
    StubPushNotificationPlatform();
