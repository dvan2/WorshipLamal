import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/presentation/providers/song_provider.dart';

import '../test_utils/fakes/fake_song_repository.dart';
import '../test_utils/fakes/fixtures.dart';

void main() {
  test('songListProvider returns songs', () async {
    final container = ProviderContainer(
      overrides: [
        songRepositoryProvider.overrideWithValue(
          FakeSongRepository(songs: [fakeSong]),
        ),
      ],
    );

    addTearDown(container.dispose);

    final songs = await container.read(songListProvider.future);

    expect(songs.length, 1);
    expect(songs.first.title, 'Fake Song');
  });

  test('songListProvider emits error when repository throws', () async {
    final container = ProviderContainer(
      overrides: [
        songRepositoryProvider.overrideWithValue(FakeFailingSongRepository()),
      ],
    );

    addTearDown(container.dispose);

    final result = await container
        .read(songListProvider.future)
        .catchError((e) => e);

    expect(result, isA<Exception>());
  });
}
