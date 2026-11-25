import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/data/repositories/songs_repository.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockSongsApi mockApi;
  late SongsRepository repository;

  setUp(() {
    mockApi = MockSongsApi();
    repository = SongsRepository(mockApi);
  });

  // -------------------------------------------------------------------------
  group('SongsRepository.getSongs', () {
    test('returns list from API on happy path', () async {
      final songs = [tSong(), tSong(id: 'song-2', title: 'Holy Spirit')];
      when(() => mockApi.fetchSongs()).thenAnswer((_) async => songs);

      final result = await repository.getSongs();

      expect(result, songs);
      verify(() => mockApi.fetchSongs()).called(1);
    });

    test('returns empty list when API returns empty list', () async {
      when(() => mockApi.fetchSongs()).thenAnswer((_) async => []);

      final result = await repository.getSongs();

      expect(result, isEmpty);
    });

    test('propagates exception thrown by API', () async {
      when(() => mockApi.fetchSongs()).thenThrow(Exception('DB error'));

      expect(
        () => repository.getSongs(),
        throwsA(isA<Exception>().having(
          (e) => e.toString(),
          'message',
          contains('DB error'),
        )),
      );
    });
  });

  // -------------------------------------------------------------------------
  group('SongsRepository.getSongById', () {
    test('returns single song from API on happy path', () async {
      final song = tSong(id: 'song-42', title: 'Reckless Love');
      when(() => mockApi.fetchSongById('song-42'))
          .thenAnswer((_) async => song);

      final result = await repository.getSongById('song-42');

      expect(result.id, 'song-42');
      expect(result.title, 'Reckless Love');
      verify(() => mockApi.fetchSongById('song-42')).called(1);
    });

    test('propagates StateError (Supabase .single() on no rows)', () async {
      when(() => mockApi.fetchSongById(any()))
          .thenThrow(StateError('no element'));

      expect(
        () => repository.getSongById('nonexistent'),
        throwsA(isA<StateError>()),
      );
    });

    test('propagates generic exception from API', () async {
      when(() => mockApi.fetchSongById(any()))
          .thenThrow(Exception('network error'));

      expect(
        () => repository.getSongById('song-1'),
        throwsA(isA<Exception>()),
      );
    });

    test('passes the correct id to the API', () async {
      when(() => mockApi.fetchSongById('the-id'))
          .thenAnswer((_) async => tSong(id: 'the-id'));

      await repository.getSongById('the-id');

      verify(() => mockApi.fetchSongById('the-id')).called(1);
      verifyNever(() => mockApi.fetchSongById('wrong-id'));
    });
  });
}
