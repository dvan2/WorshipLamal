import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/core/services/push_notification_provider.dart';
import 'package:worship_lamal/core/services/push_notification_service.dart';
import 'package:worship_lamal/core/services/push_subscription_repository.dart';
import 'package:worship_lamal/features/profile/presentation/providers/auth_provider.dart';

import '../../helpers/mocks.dart';

class _MockPushService extends Mock implements PushNotificationService {}

class _MockPushSubRepo extends Mock implements PushSubscriptionRepository {}

class _FakeSession extends Fake implements Session {
  @override
  final User user;

  _FakeSession(this.user);
}

void main() {
  late _MockPushService mockService;
  late _MockPushSubRepo mockSubRepo;
  late StreamController<AuthState> authController;

  const testSub = PushSubscriptionData(
    endpoint: 'https://push.example.com/sub/1',
    p256dh: 'p256dh-key',
    auth: 'auth-key',
  );

  setUpAll(() {
    registerFallbackValue(testSub);
  });

  setUp(() {
    mockService = _MockPushService();
    mockSubRepo = _MockPushSubRepo();
    authController = StreamController<AuthState>.broadcast();

    when(() => mockService.isSupported).thenReturn(true);
    when(() => mockService.prepare()).thenAnswer((_) async {});
    when(() => mockService.permissionState).thenReturn('default');
    when(() => mockService.getCurrentSubscription())
        .thenAnswer((_) async => testSub);
    when(() => mockSubRepo.saveSubscription(any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await authController.close();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer.test(
      overrides: [
        pushNotificationServiceProvider.overrideWithValue(mockService),
        pushSubscriptionRepositoryProvider.overrideWithValue(mockSubRepo),
        authStateProvider.overrideWith((ref) => authController.stream),
      ],
    );
    container.listen(pushPermissionProvider, (_, __) {});
    return container;
  }

  group('PushPermissionNotifier', () {
    test('upserts existing subscription when permission is granted and user exists',
        () async {
      when(() => mockService.permissionState).thenReturn('granted');
      final user1 = MockUser();
      when(() => user1.id).thenReturn('user-1');

      final container = makeContainer();
      addTearDown(container.dispose);

      authController.add(
        AuthState(AuthChangeEvent.signedIn, _FakeSession(user1)),
      );
      await pumpEventQueue();
      final state = await container.read(pushPermissionProvider.future);

      expect(state, isTrue);
      verify(() => mockService.getCurrentSubscription()).called(1);
      verify(() => mockSubRepo.saveSubscription(testSub)).called(1);
    });

    test('re-upserts subscription when auth userId changes', () async {
      when(() => mockService.permissionState).thenReturn('granted');
      final user1 = MockUser();
      final user2 = MockUser();
      when(() => user1.id).thenReturn('user-1');
      when(() => user2.id).thenReturn('user-2');

      final container = makeContainer();
      addTearDown(container.dispose);

      authController.add(
        AuthState(AuthChangeEvent.signedIn, _FakeSession(user1)),
      );
      await pumpEventQueue();
      await container.read(pushPermissionProvider.future);

      authController.add(
        AuthState(AuthChangeEvent.signedIn, _FakeSession(user2)),
      );
      await pumpEventQueue();
      await container.read(pushPermissionProvider.future);

      verify(() => mockSubRepo.saveSubscription(testSub)).called(2);
    });

    test('does not fetch or save subscription when permission is default',
        () async {
      when(() => mockService.permissionState).thenReturn('default');
      final user1 = MockUser();
      when(() => user1.id).thenReturn('user-1');

      final container = makeContainer();
      addTearDown(container.dispose);

      authController.add(
        AuthState(AuthChangeEvent.signedIn, _FakeSession(user1)),
      );
      await pumpEventQueue();
      final state = await container.read(pushPermissionProvider.future);

      expect(state, isNull);
      verifyNever(() => mockService.getCurrentSubscription());
      verifyNever(() => mockSubRepo.saveSubscription(any()));
    });
  });
}
