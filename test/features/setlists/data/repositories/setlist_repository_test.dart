import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:worship_lamal/features/setlists/data/models/setlist_model.dart';
import 'package:worship_lamal/features/setlists/data/repositories/setlist_repository.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockSetlistsApi mockApi;
  late SetlistRepository repository;

  setUp(() {
    mockApi = MockSetlistsApi();
    repository = SetlistRepository(mockApi);
  });

  // -------------------------------------------------------------------------
  group('SetlistRepository.getSetlists', () {
    test('returns list from API on happy path', () async {
      final setlists = [tSetlist(), tSetlist(id: 'sl-2', title: 'Wednesday')];
      when(() => mockApi.fetchSetlists()).thenAnswer((_) async => setlists);

      final result = await repository.getSetlists();

      expect(result, setlists);
      verify(() => mockApi.fetchSetlists()).called(1);
    });

    test('returns empty list when API returns empty list', () async {
      when(() => mockApi.fetchSetlists()).thenAnswer((_) async => []);

      final result = await repository.getSetlists();

      expect(result, isEmpty);
    });

    test('propagates exception from API', () async {
      when(() => mockApi.fetchSetlists()).thenThrow(Exception('network error'));

      expect(() => repository.getSetlists(), throwsA(isA<Exception>()));
    });
  });

  // -------------------------------------------------------------------------
  group('SetlistRepository.getSetlistById', () {
    test('returns Setlist when API finds it', () async {
      final sl = tSetlist(id: 'sl-99');
      when(() => mockApi.fetchSetlistById('sl-99'))
          .thenAnswer((_) async => sl);

      final result = await repository.getSetlistById('sl-99');

      expect(result?.id, 'sl-99');
      verify(() => mockApi.fetchSetlistById('sl-99')).called(1);
    });

    test('returns null when API returns null (not found)', () async {
      when(() => mockApi.fetchSetlistById(any()))
          .thenAnswer((_) async => null);

      final result = await repository.getSetlistById('nonexistent');

      expect(result, isNull);
    });

    // Note: SetlistsApi.fetchSetlistById swallows exceptions and returns null.
    // At the repository layer we just verify the null-return contract holds.
    test('returns null when API swallows exception (not-found path)', () async {
      when(() => mockApi.fetchSetlistById(any()))
          .thenAnswer((_) async => null);

      final result = await repository.getSetlistById('nonexistent-2');

      expect(result, isNull);
    });
  });

  // -------------------------------------------------------------------------
  group('SetlistRepository.addSong', () {
    test('calls API with all correct parameters', () async {
      when(() => mockApi.addSongToSetlist(
            setlistId: any(named: 'setlistId'),
            songId: any(named: 'songId'),
            order: any(named: 'order'),
            key_override: any(named: 'key_override'),
          )).thenAnswer((_) async {});

      await repository.addSong(
        setlistId: 'sl-1',
        songId: 'song-1',
        order: 3,
        keyOverride: 'Am',
      );

      verify(() => mockApi.addSongToSetlist(
            setlistId: 'sl-1',
            songId: 'song-1',
            order: 3,
            key_override: 'Am',
          )).called(1);
    });

    test('propagates exception from API', () async {
      when(() => mockApi.addSongToSetlist(
            setlistId: any(named: 'setlistId'),
            songId: any(named: 'songId'),
            order: any(named: 'order'),
            key_override: any(named: 'key_override'),
          )).thenThrow(Exception('insert failed'));

      expect(
        () => repository.addSong(
            setlistId: 'sl-1', songId: 'song-1', order: 0),
        throwsA(isA<Exception>()),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('SetlistRepository.removeSong', () {
    test('delegates to deleteAndNormalize with correct parameters', () async {
      when(() => mockApi.deleteAndNormalize(any(), any()))
          .thenAnswer((_) async {});

      await repository.removeSong('sl-1', 'item-1');

      verify(() => mockApi.deleteAndNormalize('item-1', 'sl-1')).called(1);
    });

    test('propagates exception from API', () async {
      when(() => mockApi.deleteAndNormalize(any(), any()))
          .thenThrow(Exception('rpc error'));

      expect(() => repository.removeSong('sl-1', 'item-1'),
          throwsA(isA<Exception>()));
    });
  });

  // -------------------------------------------------------------------------
  group('SetlistRepository.updateKeyOverride', () {
    test('delegates to API with correct parameters', () async {
      when(() => mockApi.updateKeyOverride(any(), any()))
          .thenAnswer((_) async {});

      await repository.updateKeyOverride('item-1', 'F#');

      verify(() => mockApi.updateKeyOverride('item-1', 'F#')).called(1);
    });
  });

  // -------------------------------------------------------------------------
  group('SetlistRepository.followSetlist / unfollowSetlist', () {
    test('follow delegates to API', () async {
      when(() => mockApi.followSetlist(any())).thenAnswer((_) async {});

      await repository.followSetlist('sl-1');

      verify(() => mockApi.followSetlist('sl-1')).called(1);
    });

    test('unfollow delegates to API', () async {
      when(() => mockApi.unfollowSetlist(any())).thenAnswer((_) async {});

      await repository.unfollowSetlist('sl-1');

      verify(() => mockApi.unfollowSetlist('sl-1')).called(1);
    });
  });

  // -------------------------------------------------------------------------
  group('SetlistRepository.isFollowing', () {
    test('returns true when setlist id is in followed list', () async {
      when(() => mockApi.getFollowedSetlists())
          .thenAnswer((_) async => [tSetlist(id: 'sl-5')]);

      final result = await repository.isFollowing('sl-5');

      expect(result, isTrue);
    });

    test('returns false when setlist id is NOT in followed list', () async {
      when(() => mockApi.getFollowedSetlists())
          .thenAnswer((_) async => [tSetlist(id: 'sl-5')]);

      final result = await repository.isFollowing('sl-99');

      expect(result, isFalse);
    });

    test('returns false when followed list is empty', () async {
      when(() => mockApi.getFollowedSetlists()).thenAnswer((_) async => []);

      final result = await repository.isFollowing('sl-1');

      expect(result, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  group('SetlistRepository.reorderSetlistItems', () {
    test('passes correctly ordered update maps to API', () async {
      when(() => mockApi.updateSetlistOrder(any()))
          .thenAnswer((_) async {});

      final items = [
        tSetlistItem(id: 'item-a', sortOrder: 99),
        tSetlistItem(id: 'item-b', sortOrder: 99),
      ];

      await repository.reorderSetlistItems('sl-1', items);

      final captured = verify(
        () => mockApi.updateSetlistOrder(captureAny()),
      ).captured.first as List<Map<String, dynamic>>;

      expect(captured, hasLength(2));
      // After reorder the new indices should be 0 and 1
      expect(captured[0]['id'], 'item-a');
      expect(captured[0]['sort_order'], 0);
      expect(captured[1]['id'], 'item-b');
      expect(captured[1]['sort_order'], 1);
    });
  });

  // -------------------------------------------------------------------------
  group('SetlistRepository.addSongsToSet — empty guard', () {
    test('does nothing and skips API call when rawItems is empty', () async {
      await repository.addSongsToSet([]);

      verifyNever(() => mockApi.fetchSetlistById(any()));
      verifyNever(() => mockApi.addSetlistItems(any()));
    });
  });

  // -------------------------------------------------------------------------
  group('SetlistRepository.deleteSetlist', () {
    test('delegates to API', () async {
      when(() => mockApi.deleteSetlist(any())).thenAnswer((_) async {});

      await repository.deleteSetlist('sl-1');

      verify(() => mockApi.deleteSetlist('sl-1')).called(1);
    });

    test('propagates exception from API', () async {
      when(() => mockApi.deleteSetlist(any()))
          .thenThrow(Exception('delete failed'));

      expect(() => repository.deleteSetlist('sl-1'), throwsA(isA<Exception>()));
    });
  });

  // -------------------------------------------------------------------------
  group('SetlistRepository.renameSetlist', () {
    test('delegates to API with correct parameters', () async {
      when(() => mockApi.renameSetlist(any(), any()))
          .thenAnswer((_) async {});

      await repository.renameSetlist('sl-1', 'New Title');

      verify(() => mockApi.renameSetlist('sl-1', 'New Title')).called(1);
    });
  });
}
