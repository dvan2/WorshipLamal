import 'package:worship_lamal/features/songs/data/models/song_model.dart';

final fakeArtist = Artist(id: 'artist-1', name: 'Fake Artist');

final fakeSong = Song(
  id: 'song-1',
  title: 'Fake Song',
  artists: [fakeArtist],
  lyricLines: const [],
  createdAt: DateTime.now(),
);
