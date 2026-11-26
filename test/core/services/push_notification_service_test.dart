import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:worship_lamal/core/services/push_notification_service.dart';

class _MockPushPlatform extends Mock implements PushNotificationPlatform {}

void main() {
  late _MockPushPlatform mockPlatform;
  late PushNotificationService service;

  const testVapidKey = 'BTestVapidPublicKey123';
  const testSub = PushSubscriptionData(
    endpoint: 'https://push.example.com/sub/1',
    p256dh: 'p256dh-key',
    auth: 'auth-key',
  );

  setUp(() {
    mockPlatform = _MockPushPlatform();
    when(() => mockPlatform.isSupported).thenReturn(true);
    when(() => mockPlatform.isStandalone).thenReturn(true);
    when(() => mockPlatform.isIosSafari).thenReturn(false);
    when(() => mockPlatform.permissionState).thenReturn('default');
    when(() => mockPlatform.prepare()).thenAnswer((_) async {});
    when(() => mockPlatform.subscribe(any())).thenAnswer((_) async => testSub);

    service = PushNotificationService(
      vapidPublicKey: testVapidKey,
      platform: mockPlatform,
    );
  });

  group('PushNotificationService', () {
    test('isSupported is false when vapidPublicKey is empty', () {
      final noKeyService = PushNotificationService(
        vapidPublicKey: '',
        platform: mockPlatform,
      );
      expect(noKeyService.isSupported, isFalse);
    });

    test('isSupported is false when platform is unsupported', () {
      when(() => mockPlatform.isSupported).thenReturn(false);
      expect(service.isSupported, isFalse);
    });

    test('isSupported is true when platform supported and key present', () {
      expect(service.isSupported, isTrue);
    });

    test('needsIosHomeScreenInstall is true on iOS Safari non-standalone', () {
      when(() => mockPlatform.isIosSafari).thenReturn(true);
      when(() => mockPlatform.isStandalone).thenReturn(false);
      expect(service.needsIosHomeScreenInstall, isTrue);
    });

    test(
        'needsIosHomeScreenInstall is true even when platform.isSupported is false',
        () {
      when(() => mockPlatform.isSupported).thenReturn(false);
      when(() => mockPlatform.isIosSafari).thenReturn(true);
      when(() => mockPlatform.isStandalone).thenReturn(false);
      expect(service.needsIosHomeScreenInstall, isTrue);
    });

    test('needsIosHomeScreenInstall is false when vapidPublicKey is empty', () {
      when(() => mockPlatform.isIosSafari).thenReturn(true);
      when(() => mockPlatform.isStandalone).thenReturn(false);
      final noKeyService = PushNotificationService(
        vapidPublicKey: '',
        platform: mockPlatform,
      );
      expect(noKeyService.needsIosHomeScreenInstall, isFalse);
    });

    test('needsIosHomeScreenInstall is false on iOS Safari standalone', () {
      when(() => mockPlatform.isIosSafari).thenReturn(true);
      when(() => mockPlatform.isStandalone).thenReturn(true);
      expect(service.needsIosHomeScreenInstall, isFalse);
    });

    test('requestAndSubscribe delegates to platform.subscribe', () async {
      final result = await service.requestAndSubscribe();
      expect(result, testSub);
      verify(() => mockPlatform.subscribe(testVapidKey)).called(1);
    });

    test('requestAndSubscribe returns null when iOS needs home screen install',
        () async {
      when(() => mockPlatform.isIosSafari).thenReturn(true);
      when(() => mockPlatform.isStandalone).thenReturn(false);

      final result = await service.requestAndSubscribe();
      expect(result, isNull);
      verifyNever(() => mockPlatform.subscribe(any()));
    });

    test('prepare delegates to platform.prepare', () async {
      await service.prepare();
      verify(() => mockPlatform.prepare()).called(1);
    });

    test('permissionState delegates to platform.permissionState', () {
      when(() => mockPlatform.permissionState).thenReturn('granted');
      expect(service.permissionState, 'granted');
    });

    test('requestAndSubscribe returns null when unsupported', () async {
      when(() => mockPlatform.isSupported).thenReturn(false);
      final result = await service.requestAndSubscribe();
      expect(result, isNull);
      verifyNever(() => mockPlatform.subscribe(any()));
    });
  });
}
