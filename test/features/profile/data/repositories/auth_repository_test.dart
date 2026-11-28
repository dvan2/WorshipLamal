import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/features/profile/data/repositories/auth_repository.dart';

import '../../../../helpers/mocks.dart';

// ---------------------------------------------------------------------------
// Fakes — avoids constructing concrete Supabase response objects
// ---------------------------------------------------------------------------
class FakeUserAttributes extends Fake implements UserAttributes {}

class FakeAuthResponse extends Fake implements AuthResponse {}

class FakeUserResponse extends Fake implements UserResponse {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late AuthRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeUserAttributes());
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();

    when(() => mockClient.auth).thenReturn(mockAuth);
    repository = AuthRepository(mockClient);
  });

  // -------------------------------------------------------------------------
  group('AuthRepository.currentUser', () {
    test('returns user when logged in', () {
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      expect(repository.currentUser, mockUser);
    });

    test('returns null when no user is logged in', () {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(repository.currentUser, isNull);
    });
  });

  // -------------------------------------------------------------------------
  group('AuthRepository.authStateChanges', () {
    test('returns the stream from GoTrueClient', () {
      final stream = Stream<AuthState>.empty();
      when(() => mockAuth.onAuthStateChange).thenAnswer((_) => stream);

      expect(repository.authStateChanges, stream);
    });
  });

  // -------------------------------------------------------------------------
  group('AuthRepository.signIn', () {
    test('delegates to signInWithPassword with correct credentials', () async {
      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => FakeAuthResponse());

      await repository.signIn('user@example.com', 'secret');

      verify(() => mockAuth.signInWithPassword(
            email: 'user@example.com',
            password: 'secret',
          )).called(1);
    });

    test('propagates AuthException on wrong credentials', () {
      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(AuthException('Invalid credentials'));

      expect(
        () => repository.signIn('bad@email.com', 'wrongpass'),
        throwsA(isA<AuthException>()),
      );
    });

    test('propagates generic exception', () {
      when(() => mockAuth.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(Exception('network error'));

      expect(
        () => repository.signIn('user@example.com', 'pass'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('AuthRepository.signUp', () {
    test('delegates to auth.signUp with correct credentials', () async {
      when(() => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) async => FakeAuthResponse());

      await repository.signUp('new@example.com', 'newpass');

      verify(() => mockAuth.signUp(
            email: 'new@example.com',
            password: 'newpass',
          )).called(1);
    });

    test('propagates AuthException (e.g. email already in use)', () {
      when(() => mockAuth.signUp(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenThrow(AuthException('User already registered'));

      expect(
        () => repository.signUp('existing@example.com', 'pass'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('AuthRepository.signOut', () {
    test('delegates to auth.signOut', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await repository.signOut();

      verify(() => mockAuth.signOut()).called(1);
    });

    test('propagates exception from auth.signOut', () {
      when(() => mockAuth.signOut()).thenThrow(Exception('signOut failed'));

      expect(() => repository.signOut(), throwsA(isA<Exception>()));
    });
  });

  // -------------------------------------------------------------------------
  group('AuthRepository.signInAnonymously', () {
    test('delegates to auth.signInAnonymously', () async {
      when(() => mockAuth.signInAnonymously())
          .thenAnswer((_) async => FakeAuthResponse());

      await repository.signInAnonymously();

      verify(() => mockAuth.signInAnonymously()).called(1);
    });

    test('propagates exception from auth.signInAnonymously', () {
      when(() => mockAuth.signInAnonymously())
          .thenThrow(Exception('anon failed'));

      expect(() => repository.signInAnonymously(), throwsA(isA<Exception>()));
    });
  });

  // -------------------------------------------------------------------------
  group('AuthRepository.getGuestDataSummary', () {
    test('returns empty summary when currentUser is null', () async {
      var checkerCalled = false;
      final repoWithChecker = AuthRepository(
        mockClient,
        guestDataChecker: (_) async {
          checkerCalled = true;
          return const GuestDataSummary(hasSetlists: true);
        },
      );
      when(() => mockAuth.currentUser).thenReturn(null);

      final summary = await repoWithChecker.getGuestDataSummary();

      expect(summary.hasAny, isFalse);
      expect(checkerCalled, isFalse);
    });

    test('returns empty summary when currentUser is not anonymous', () async {
      var checkerCalled = false;
      final repoWithChecker = AuthRepository(
        mockClient,
        guestDataChecker: (_) async {
          checkerCalled = true;
          return const GuestDataSummary(hasSetlists: true);
        },
      );
      when(() => mockUser.isAnonymous).thenReturn(false);
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final summary = await repoWithChecker.getGuestDataSummary();

      expect(summary.hasAny, isFalse);
      expect(checkerCalled, isFalse);
    });

    test('returns populated summary for anonymous guest with data', () async {
      final repoWithChecker = AuthRepository(
        mockClient,
        guestDataChecker: (userId) async {
          expect(userId, 'guest-1');
          return const GuestDataSummary(
            hasSetlists: true,
            hasUserKeys: false,
            hasFavorites: true,
          );
        },
      );
      when(() => mockUser.id).thenReturn('guest-1');
      when(() => mockUser.isAnonymous).thenReturn(true);
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final summary = await repoWithChecker.getGuestDataSummary();

      expect(summary.hasSetlists, isTrue);
      expect(summary.hasUserKeys, isFalse);
      expect(summary.hasFavorites, isTrue);
      expect(summary.hasAny, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  group('AuthRepository.upgradeGuestAccount', () {
    test('calls auth.updateUser and was called exactly once', () async {
      when(() => mockAuth.updateUser(any()))
          .thenAnswer((_) async => FakeUserResponse());

      await repository.upgradeGuestAccount('upgrade@example.com', 'newpass');

      verify(() => mockAuth.updateUser(any())).called(1);
    });

    test('passes UserAttributes with correct email and password', () async {
      late UserAttributes capturedAttrs;
      when(() => mockAuth.updateUser(any())).thenAnswer((invocation) async {
        capturedAttrs =
            invocation.positionalArguments.first as UserAttributes;
        return FakeUserResponse();
      });

      await repository.upgradeGuestAccount('upgrade@example.com', 'newpass');

      expect(capturedAttrs.email, 'upgrade@example.com');
      expect(capturedAttrs.password, 'newpass');
    });

    test('propagates AuthException on upgrade failure', () {
      when(() => mockAuth.updateUser(any()))
          .thenThrow(AuthException('upgrade failed'));

      expect(
        () => repository.upgradeGuestAccount('x@x.com', 'pass'),
        throwsA(isA<AuthException>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('AuthRepository.signInWithGoogle', () {
    test('non-guest calls signInWithOAuth and never calls linkIdentity',
        () async {
      var linkCalled = false;
      String? capturedRedirect;
      OAuthProvider? capturedProvider;

      final repo = AuthRepository(
        mockClient,
        redirectUriFn: () => 'https://worship-lamal-f1b1c.web.app',
        linkOAuthFn: (_, {redirectTo}) async {
          linkCalled = true;
          return true;
        },
        signInOAuthFn: (provider, {redirectTo}) async {
          capturedProvider = provider;
          capturedRedirect = redirectTo;
          return true;
        },
      );
      when(() => mockAuth.currentUser).thenReturn(null);

      await repo.signInWithGoogle();

      expect(linkCalled, isFalse);
      expect(capturedProvider, OAuthProvider.google);
      expect(capturedRedirect, 'https://worship-lamal-f1b1c.web.app');
    });

    test('anonymous guest calls linkIdentity first', () async {
      var linkCalled = false;
      var signInCalled = false;
      String? capturedRedirect;

      final repo = AuthRepository(
        mockClient,
        redirectUriFn: () => 'https://worship-lamal-f1b1c.web.app',
        linkOAuthFn: (provider, {redirectTo}) async {
          linkCalled = true;
          capturedRedirect = redirectTo;
          expect(provider, OAuthProvider.google);
          return true;
        },
        signInOAuthFn: (_, {redirectTo}) async {
          signInCalled = true;
          return true;
        },
      );
      when(() => mockUser.isAnonymous).thenReturn(true);
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      await repo.signInWithGoogle();

      expect(linkCalled, isTrue);
      expect(signInCalled, isFalse);
      expect(capturedRedirect, 'https://worship-lamal-f1b1c.web.app');
    });

    test(
        'anonymous guest falls back to signInWithOAuth on identity_already_exists',
        () async {
      var linkCalled = false;
      var signInCalled = false;

      final repo = AuthRepository(
        mockClient,
        redirectUriFn: () => 'https://worship-lamal-f1b1c.web.app',
        linkOAuthFn: (_, {redirectTo}) async {
          linkCalled = true;
          throw const AuthException(
            'Identity is already linked to another user',
            code: AuthRepository.identityAlreadyExistsCode,
          );
        },
        signInOAuthFn: (provider, {redirectTo}) async {
          signInCalled = true;
          expect(provider, OAuthProvider.google);
          expect(redirectTo, 'https://worship-lamal-f1b1c.web.app');
          return true;
        },
      );
      when(() => mockUser.isAnonymous).thenReturn(true);
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      await repo.signInWithGoogle();

      expect(linkCalled, isTrue);
      expect(signInCalled, isTrue);
    });

    test('anonymous guest rethrows non-conflict AuthException', () async {
      var signInCalled = false;

      final repo = AuthRepository(
        mockClient,
        redirectUriFn: () => 'https://worship-lamal-f1b1c.web.app',
        linkOAuthFn: (_, {redirectTo}) async {
          throw const AuthException(
            'Provider is not enabled',
            code: 'provider_disabled',
          );
        },
        signInOAuthFn: (_, {redirectTo}) async {
          signInCalled = true;
          return true;
        },
      );
      when(() => mockUser.isAnonymous).thenReturn(true);
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      await expectLater(
        () => repo.signInWithGoogle(),
        throwsA(isA<AuthException>()),
      );
      expect(signInCalled, isFalse);
    });

    test('forceSignIn: true skips linkIdentity and calls signInWithOAuth',
        () async {
      var linkCalled = false;
      var signInCalled = false;

      final repo = AuthRepository(
        mockClient,
        redirectUriFn: () => 'https://worship-lamal-f1b1c.web.app',
        linkOAuthFn: (_, {redirectTo}) async {
          linkCalled = true;
          return true;
        },
        signInOAuthFn: (provider, {redirectTo}) async {
          signInCalled = true;
          expect(provider, OAuthProvider.google);
          return true;
        },
      );
      when(() => mockUser.isAnonymous).thenReturn(true);
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      await repo.signInWithGoogle(forceSignIn: true);

      expect(linkCalled, isFalse);
      expect(signInCalled, isTrue);
    });

    test('throws AuthException when signInWithOAuth returns false', () async {
      final repo = AuthRepository(
        mockClient,
        redirectUriFn: () => 'https://worship-lamal-f1b1c.web.app',
        signInOAuthFn: (_, {redirectTo}) async => false,
      );
      when(() => mockAuth.currentUser).thenReturn(null);

      await expectLater(
        () => repo.signInWithGoogle(),
        throwsA(isA<AuthException>()),
      );
    });

    test('throws AuthException when linkIdentity returns false', () async {
      var signInCalled = false;
      final repo = AuthRepository(
        mockClient,
        redirectUriFn: () => 'https://worship-lamal-f1b1c.web.app',
        linkOAuthFn: (_, {redirectTo}) async => false,
        signInOAuthFn: (_, {redirectTo}) async {
          signInCalled = true;
          return true;
        },
      );
      when(() => mockUser.isAnonymous).thenReturn(true);
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      await expectLater(
        () => repo.signInWithGoogle(),
        throwsA(isA<AuthException>()),
      );
      expect(signInCalled, isFalse);
    });
  });
}
