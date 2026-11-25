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
}
