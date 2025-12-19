import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:worship_lamal/features/songs/data/song_repository.dart';
import 'package:worship_lamal/features/songs/data/remote/songs_api.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';

class MockSongsApi extends Mock implements SongsApi {}

void main() {
  late MockSongsApi api;
  late SongRepository repository;

  setUp(() {
    api = MockSongsApi();
    repository = SongRepository(api);
  });

  test('getSongs returns songs from api', () async {
    final fakeSongs = [
      Song(id: '1', title: 'Test Song', artist: 'Test Artist', lyricLines: []),
    ];

    when(() => api.fetchSongs()).thenAnswer((_) async => fakeSongs);

    final result = await repository.getSongs();

    expect(result.length, 1);
    expect(result.first.title, 'Test Song');
    verify(() => api.fetchSongs()).called(1);
  });
}
