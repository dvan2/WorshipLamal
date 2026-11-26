import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/core/services/push_notification_provider.dart';
import 'package:worship_lamal/core/services/push_notification_service.dart';
import 'package:worship_lamal/core/services/push_subscription_repository.dart';
import 'package:worship_lamal/features/profile/presentation/profile_tab.dart';
import 'package:worship_lamal/features/profile/presentation/providers/auth_provider.dart';
import 'package:worship_lamal/features/profile/presentation/providers/preferences_provider.dart';

import '../../../helpers/mocks.dart';

class _MockPushService extends Mock implements PushNotificationService {}

class _MockPushSubRepo extends Mock implements PushSubscriptionRepository {}

class _FakeSession extends Fake implements Session {
  @override
  final User user;

  _FakeSession(this.user);
}

class _TestPreferencesNotifier extends PreferencesNotifier {
  @override
  PreferencesState build() => const PreferencesState(isLoading: false);
}

void main() {
  late MockAuthRepository mockAuthRepo;
  late _MockPushService mockPushService;
  late _MockPushSubRepo mockPushSubRepo;
  late StreamController<AuthState> authController;

  const testSub = PushSubscriptionData(
    endpoint: 'https://push.example.com/sub/1',
    p256dh: 'p256dh',
    auth: 'auth',
  );

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    mockPushService = _MockPushService();
    mockPushSubRepo = _MockPushSubRepo();
    authController = StreamController<AuthState>.broadcast();

    when(() => mockAuthRepo.currentUser).thenReturn(null);
    when(() => mockPushService.getCurrentSubscription())
        .thenAnswer((_) async => null);
  });

  tearDown(() async {
    await authController.close();
  });

  Future<void> pumpProfileTab(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          authStateProvider.overrideWith((ref) => authController.stream),
          pushNotificationServiceProvider.overrideWithValue(mockPushService),
          pushSubscriptionRepositoryProvider.overrideWithValue(mockPushSubRepo),
          preferencesProvider.overrideWith(_TestPreferencesNotifier.new),
          packageInfoProvider.overrideWith(
            (ref) async => PackageInfo(
              appName: 'Worship Lamal',
              packageName: 'com.example.worship_lamal',
              version: '1.5.0',
              buildNumber: '12',
            ),
          ),
        ],
        child: const MaterialApp(home: ProfileTab()),
      ),
    );
    await tester.pump();
  }

  group('ProfileTab', () {
    testWidgets('shows offline/signed-out fallback when user is null', (
      tester,
    ) async {
      when(() => mockAuthRepo.signInAnonymously()).thenAnswer((_) async {});

      await pumpProfileTab(tester);

      expect(find.text('Not Signed In'), findsOneWidget);
      expect(find.text('Retry Guest Session'), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);

      await tester.tap(find.text('Retry Guest Session'));
      await tester.pump();

      verify(() => mockAuthRepo.signInAnonymously()).called(1);
    });

    testWidgets('reactively rebuilds when authStateProvider emits new user', (
      tester,
    ) async {
      final guestUser = MockUser();
      when(() => guestUser.isAnonymous).thenReturn(true);
      when(() => mockAuthRepo.currentUser).thenReturn(guestUser);

      await pumpProfileTab(tester);
      expect(find.text('Guest Account'), findsOneWidget);

      final signedInUser = MockUser();
      when(() => signedInUser.isAnonymous).thenReturn(false);
      when(() => signedInUser.email).thenReturn('leader@church.org');

      authController.add(
        AuthState(AuthChangeEvent.signedIn, _FakeSession(signedInUser)),
      );
      await tester.pumpAndSettle();

      expect(find.text('leader@church.org'), findsOneWidget);
      expect(find.text('Sign Out'), findsOneWidget);
    });

    testWidgets(
        'Sign Out deletes push subscription BEFORE signOut and creates guest session',
        (tester) async {
      final signedInUser = MockUser();
      when(() => signedInUser.isAnonymous).thenReturn(false);
      when(() => signedInUser.email).thenReturn('leader@church.org');
      when(() => mockAuthRepo.currentUser).thenReturn(signedInUser);

      final callOrder = <String>[];
      when(() => mockPushService.getCurrentSubscription())
          .thenAnswer((_) async => testSub);
      when(() => mockPushSubRepo.deleteSubscription(testSub.endpoint))
          .thenAnswer((_) async {
        callOrder.add('deleteSubscription');
      });
      when(() => mockAuthRepo.signOut()).thenAnswer((_) async {
        callOrder.add('signOut');
      });
      when(() => mockAuthRepo.signInAnonymously()).thenAnswer((_) async {
        callOrder.add('signInAnonymously');
      });

      await pumpProfileTab(tester);

      await tester.tap(find.text('Sign Out'));
      await tester.pumpAndSettle();

      expect(callOrder, [
        'deleteSubscription',
        'signOut',
        'signInAnonymously',
      ]);
      verify(() => mockPushSubRepo.deleteSubscription(testSub.endpoint))
          .called(1);
    });
  });
}
