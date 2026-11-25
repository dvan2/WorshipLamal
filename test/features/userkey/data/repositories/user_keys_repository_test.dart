import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/features/userkey/data/model/user_key_model.dart';
import 'package:worship_lamal/features/userkey/data/repositories/user_keys_repository.dart';

import '../../../../helpers/mocks.dart';

// ---------------------------------------------------------------------------
// Extra mock for GoTrueClient (needed to stub .currentUser)
// ---------------------------------------------------------------------------
// MockGoTrueClient is already declared in mocks.dart.

void main() {
  late MockUserKeysApi mockApi;
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late UserKeysRepository repository;

  setUp(() {
    mockApi = MockUserKeysApi();
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();

    when(() => mockClient.auth).thenReturn(mockAuth);
    repository = UserKeysRepository(mockApi, mockClient);
  });

  // -------------------------------------------------------------------------
  group('UserKeysRepository.getAllKeys', () {
    test('fetches keys for logged-in user', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('user-1');
      final keys = [
        UserKey(userId: 'user-1', songId: 'song-1', preferredKey: 'Bb'),
      ];
      when(() => mockApi.fetchUserKeys('user-1'))
          .thenAnswer((_) async => keys);

      final result = await repository.getAllKeys();

      expect(result, hasLength(1));
      expect(result.first.preferredKey, 'Bb');
      verify(() => mockApi.fetchUserKeys('user-1')).called(1);
    });

    test('returns empty list when no user is logged in (guest)', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      final result = await repository.getAllKeys();

      expect(result, isEmpty);
      verifyNever(() => mockApi.fetchUserKeys(any()));
    });

    test('returns empty list when API returns empty list', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('user-1');
      when(() => mockApi.fetchUserKeys('user-1')).thenAnswer((_) async => []);

      final result = await repository.getAllKeys();

      expect(result, isEmpty);
    });

    test('propagates exception from API', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('user-1');
      when(() => mockApi.fetchUserKeys('user-1'))
          .thenThrow(Exception('DB error'));

      expect(() => repository.getAllKeys(), throwsA(isA<Exception>()));
    });
  });

  // -------------------------------------------------------------------------
  group('UserKeysRepository.setKey', () {
    test('calls API with userId, songId, and key', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('user-1');
      when(() => mockApi.setUserKey('user-1', 'song-1', 'F#'))
          .thenAnswer((_) async {});

      await repository.setKey('song-1', 'F#');

      verify(() => mockApi.setUserKey('user-1', 'song-1', 'F#')).called(1);
    });

    test('throws Exception when no user is logged in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(
        () => repository.setKey('song-1', 'G'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('User must be logged in'),
        )),
      );
      verifyNever(() => mockApi.setUserKey(any(), any(), any()));
    });

    test('propagates exception from API', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('user-1');
      when(() => mockApi.setUserKey(any(), any(), any()))
          .thenThrow(Exception('upsert failed'));

      expect(
        () => repository.setKey('song-1', 'G'),
        throwsA(isA<Exception>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('UserKeysRepository.revertKey', () {
    test('calls API with userId and songId to delete key', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('user-1');
      when(() => mockApi.deleteUserKey('user-1', 'song-1'))
          .thenAnswer((_) async {});

      await repository.revertKey('song-1');

      verify(() => mockApi.deleteUserKey('user-1', 'song-1')).called(1);
    });

    test('throws Exception when no user is logged in', () async {
      when(() => mockAuth.currentUser).thenReturn(null);

      expect(
        () => repository.revertKey('song-1'),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('User must be logged in'),
        )),
      );
      verifyNever(() => mockApi.deleteUserKey(any(), any()));
    });

    test('propagates exception from API', () async {
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.id).thenReturn('user-1');
      when(() => mockApi.deleteUserKey(any(), any()))
          .thenThrow(Exception('delete failed'));

      expect(
        () => repository.revertKey('song-1'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
