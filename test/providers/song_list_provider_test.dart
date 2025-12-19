import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/data/song_repository.dart';
import 'package:worship_lamal/features/songs/presentation/providers/song_provider.dart';

class FakeSongRepository implements SongRepository {
  @override
  Future<List<Song>> getSongs() async {
    return [
      Song(id: '1', title: 'Fake Song', artist: 'Fake Artist', lyricLines: []),
    ];
  }

  @override
  Future<Song> getSongById(String id) async {
    return Song(
      id: id,
      title: 'Fake Song',
      artist: 'Fake Artist',
      lyricLines: [],
    );
  }
}

void main() {
  test('songListProvider returns songs', () async {
    final container = ProviderContainer(
      overrides: [
        songRepositoryProvider.overrideWithValue(FakeSongRepository()),
      ],
    );

    addTearDown(container.dispose);

    final songs = await container.read(songListProvider.future);

    expect(songs.length, 1);
    expect(songs.first.title, 'Fake Song');
  });
}
