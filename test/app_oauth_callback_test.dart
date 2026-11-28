import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/app.dart';
import 'package:worship_lamal/core/services/push_notification_provider.dart';
import 'package:worship_lamal/core/services/push_notification_service.dart';
import 'package:worship_lamal/core/services/push_subscription_repository.dart';
import 'package:worship_lamal/core/utils/web_url_cleaner.dart';
import 'package:worship_lamal/features/profile/profile_feature.dart';

import 'helpers/mocks.dart';

class _MockPushNotificationService extends Mock
    implements PushNotificationService {}

class _MockPushSubscriptionRepository extends Mock
    implements PushSubscriptionRepository {}

void main() {
  group('stripOAuthErrorParams', () {
    test('removes OAuth error params from query while preserving other params',
        () {
      final uri = Uri.parse(
        'https://worship-lamal-f1b1c.web.app/?foo=bar&error=server_error&error_code=identity_already_exists&error_description=already+linked',
      );
      final cleaned = stripOAuthErrorParams(uri);
      expect(cleaned.queryParameters, {'foo': 'bar'});
      expect(cleaned.hasFragment, isFalse);
    });

    test('removes OAuth error params from fragment', () {
      final uri = Uri.parse(
        'https://worship-lamal-f1b1c.web.app/#error=access_denied&error_code=identity_already_exists&error_description=fail',
      );
      final cleaned = stripOAuthErrorParams(uri);
      expect(cleaned.hasQuery, isFalse);
      expect(cleaned.hasFragment, isFalse);
    });
  });

  group('AuthCallbackHost OAuth identity_already_exists dialog', () {
    late MockAuthRepository mockAuthRepo;
    late _MockPushNotificationService mockPushService;
    late _MockPushSubscriptionRepository mockPushRepo;
    late StreamController<AuthState> authStreamController;

    setUp(() {
      mockAuthRepo = MockAuthRepository();
      mockPushService = _MockPushNotificationService();
      mockPushRepo = _MockPushSubscriptionRepository();
      authStreamController = StreamController<AuthState>.broadcast();

      when(() => mockAuthRepo.authStateChanges)
          .thenAnswer((_) => authStreamController.stream);
      when(
        () => mockAuthRepo.signInWithGoogle(
          redirectTo: any(named: 'redirectTo'),
          forceSignIn: any(named: 'forceSignIn'),
        ),
      ).thenAnswer((_) async {});
    });

    tearDown(() async {
      await authStreamController.close();
    });

    Widget buildHarness({
      required Uri initialUri,
      required VoidCallback onScrubUrl,
      required GlobalKey<NavigatorState> navKey,
    }) {
      return ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
          pushNotificationServiceProvider.overrideWithValue(mockPushService),
          pushSubscriptionRepositoryProvider.overrideWithValue(mockPushRepo),
        ],
        child: AuthCallbackHost(
          initialUri: initialUri,
          onScrubUrl: onScrubUrl,
          isWebOverride: true,
          navigatorKey: navKey,
          child: MaterialApp(
            navigatorKey: navKey,
            home: const Scaffold(body: Text('Home')),
          ),
        ),
      );
    }

    testWidgets(
        'Cancel scrubs URL error, dismisses dialog, and prevents re-prompt loop',
        (tester) async {
      var scrubCount = 0;
      final navKey = GlobalKey<NavigatorState>();
      final errorUri = Uri.parse(
        'https://worship-lamal-f1b1c.web.app/?error=server_error&error_code=identity_already_exists',
      );

      await tester.pumpWidget(
        buildHarness(
          initialUri: errorUri,
          onScrubUrl: () => scrubCount++,
          navKey: navKey,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Account Already Linked'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Account Already Linked'), findsNothing);
      expect(scrubCount, 1);
      verifyNever(
        () => mockAuthRepo.signInWithGoogle(
          redirectTo: any(named: 'redirectTo'),
          forceSignIn: any(named: 'forceSignIn'),
        ),
      );

      // Even if authStateProvider emits the same error again, dialog must not loop.
      authStreamController.addError(
        const AuthException(
          'Identity is already linked',
          code: AuthRepository.identityAlreadyExistsCode,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Account Already Linked'), findsNothing);
    });

    testWidgets(
        'Switch Account scrubs URL and calls signInWithGoogle(forceSignIn: true) without blocking on push cleanup',
        (tester) async {
      var scrubCount = 0;
      final navKey = GlobalKey<NavigatorState>();
      final hangingPushCompleter = Completer<PushSubscriptionData?>();
      when(() => mockPushService.getCurrentSubscription())
          .thenAnswer((_) => hangingPushCompleter.future);

      final errorUri = Uri.parse(
        'https://worship-lamal-f1b1c.web.app/#error_code=identity_already_exists',
      );

      await tester.pumpWidget(
        buildHarness(
          initialUri: errorUri,
          onScrubUrl: () => scrubCount++,
          navKey: navKey,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Account Already Linked'), findsOneWidget);

      await tester.tap(find.text('Switch Account'));
      await tester.pump();
      await tester.pump();

      expect(scrubCount, 1);
      verify(
        () => mockAuthRepo.signInWithGoogle(
          redirectTo: null,
          forceSignIn: true,
        ),
      ).called(1);

      // Let the 300ms timeout in _cleanupPushSubscriptionBestEffort settle cleanly.
      await tester.pump(const Duration(milliseconds: 350));
    });
  });
}
