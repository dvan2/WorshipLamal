import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:worship_lamal/features/songs/data/remote/songs_api.dart';
import 'package:worship_lamal/features/songs/data/song_repository.dart';

import '../test_utils/fakes/fixtures.dart'; // Import your fixtures

// 1. Mock the API
class MockSongsApi extends Mock implements SongsApi {}

void main() {
  late SongRepository repository;
  late MockSongsApi mockApi;

  setUp(() {
    mockApi = MockSongsApi();
    repository = SongRepository(mockApi);
  });

  group('SongRepository', () {
    test('getSongs returns list of songs from API', () async {
      // Arrange
      // Note: Check your actual SongsApi method name. I assumed 'fetchSongs'
      when(() => mockApi.fetchSongs()).thenAnswer((_) async => kTestSongs);

      // Act
      final result = await repository.getSongs();

      // Assert
      verify(() => mockApi.fetchSongs()).called(1);
      expect(result, equals(kTestSongs));
    });

    test('getSongById returns specific song from API', () async {
      final expectedSong = kTestSongs.first;
      when(
        () => mockApi.fetchSongById(expectedSong.id),
      ).thenAnswer((_) async => expectedSong);

      // Act
      final result = await repository.getSongById(expectedSong.id);

      // Assert
      verify(() => mockApi.fetchSongById(expectedSong.id)).called(1);
      expect(result, equals(expectedSong));
    });
  });
}
