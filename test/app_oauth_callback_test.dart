import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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
  group('stripOAuthParams & cleanedOAuthRelativeLocation', () {
    test(
        'removes code, state, and OAuth error params while preserving app params',
        () {
      final uri = Uri.parse(
        'https://worship-lamal-f1b1c.web.app/setlist/abc?auto_follow=true&code=pkce-123&state=xyz&error=server_error&error_code=identity_already_exists&error_description=already+linked',
      );
      final cleaned = stripOAuthParams(uri);
      expect(cleaned.queryParameters, {'auto_follow': 'true'});
      expect(cleaned.hasFragment, isFalse);
      expect(
        cleanedOAuthRelativeLocation(uri),
        '/setlist/abc?auto_follow=true',
      );
    });

    test('removes OAuth params from fragment and returns root when empty', () {
      final uri = Uri.parse(
        'https://worship-lamal-f1b1c.web.app/#error=access_denied&error_code=identity_already_exists&error_description=fail',
      );
      final cleaned = stripOAuthParams(uri);
      expect(cleaned.hasQuery, isFalse);
      expect(cleaned.hasFragment, isFalse);
      expect(cleanedOAuthRelativeLocation(uri), '/');
    });

    test('returns null from cleanedOAuthRelativeLocation when no OAuth params',
        () {
      final uri = Uri.parse(
        'https://worship-lamal-f1b1c.web.app/song/1?setlistId=s1',
      );
      expect(cleanedOAuthRelativeLocation(uri), isNull);
    });
  });

  group('AuthCallbackHost OAuth callback & dialog', () {
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
      required void Function(String location) onSyncRoute,
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
          onSyncRoute: onSyncRoute,
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
        'Cancel scrubs URL, syncs route to /, dismisses dialog, and prevents re-prompt loop',
        (tester) async {
      var scrubCount = 0;
      String? syncedRoute;
      final navKey = GlobalKey<NavigatorState>();
      final errorUri = Uri.parse(
        'https://worship-lamal-f1b1c.web.app/?error=server_error&error_code=identity_already_exists',
      );

      await tester.pumpWidget(
        buildHarness(
          initialUri: errorUri,
          onScrubUrl: () => scrubCount++,
          onSyncRoute: (loc) => syncedRoute = loc,
          navKey: navKey,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Account Already Linked'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Account Already Linked'), findsNothing);
      expect(scrubCount, 1);
      expect(syncedRoute, '/');
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
        'Switch Account scrubs URL and calls signInWithGoogle(forceSignIn: true) even if URL scrub throws or push hangs',
        (tester) async {
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
          onScrubUrl: () => throw StateError('history.replaceState failed'),
          onSyncRoute: (_) {},
          navKey: navKey,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Account Already Linked'), findsOneWidget);

      await tester.tap(find.text('Switch Account'));
      await tester.pump();
      await tester.pump();

      verify(
        () => mockAuthRepo.signInWithGoogle(
          redirectTo: null,
          forceSignIn: true,
        ),
      ).called(1);

      // Let the 300ms timeout in _cleanupPushSubscriptionBestEffort settle cleanly.
      await tester.pump(const Duration(milliseconds: 350));
    });

    testWidgets(
        'signedIn event scrubs leftover PKCE code/state and syncs route to /',
        (tester) async {
      var scrubCount = 0;
      String? syncedRoute;
      final navKey = GlobalKey<NavigatorState>();
      final pkceUri = Uri.parse(
        'https://worship-lamal-f1b1c.web.app/?code=pkce-abc&state=xyz',
      );

      await tester.pumpWidget(
        buildHarness(
          initialUri: pkceUri,
          onScrubUrl: () => scrubCount++,
          onSyncRoute: (loc) => syncedRoute = loc,
          navKey: navKey,
        ),
      );
      await tester.pumpAndSettle();

      authStreamController.add(const AuthState(AuthChangeEvent.signedIn, null));
      await tester.pumpAndSettle();

      expect(scrubCount, 1);
      expect(syncedRoute, '/');
    });
  });
}
