import 'package:worship_lamal/features/songs/data/models/song_model.dart';

// --- SHARED CONSTANTS ---

final fakeArtist = Artist(id: 'artist-1', name: 'Fake Artist');

// --- BASE FIXTURE ---

final fakeSong = Song(
  id: 'song-1',
  title: 'Fake Song',
  artists: [fakeArtist], // Updated to List<Artist>
  lyricLines: const [],
  createdAt: DateTime.now(),
  key: 'G', // Necessary for your controller logic (Transposition)
);

// --- TEST DATA SET ---
// This list covers all IDs used in your unit tests.

final kTestSongs = [
  // 1. Generic Song (used in simple add tests)
  fakeSong.copyWith(id: 'song_1', title: 'Song One'),

  // 2. Transposition Logic Song (Must be Key C)
  fakeSong.copyWith(
    id: 'song_with_key_C',
    title: 'Transposition Test Song',
    key: 'C', // <--- CRITICAL for Female Mode test
    originalKey: 'C',
  ),

  // 3. Batch/Reorder Test Songs
  fakeSong.copyWith(id: 's1', title: 'S1', key: 'A', originalKey: 'A'),
  fakeSong.copyWith(id: 's2', title: 'S2', key: 'A', originalKey: 'A'),
  fakeSong.copyWith(id: 's3', title: 'S3', key: 'A', originalKey: 'A'),

  // 4. Specific songs for generic reorder tests
  fakeSong.copyWith(id: 'song_A', title: 'A', key: 'A', originalKey: 'A'),
  fakeSong.copyWith(id: 'song_B', title: 'B', key: 'A', originalKey: 'A'),
  fakeSong.copyWith(id: 'song_to_delete', title: 'Delete Me'),
];

// --- EXTENSION FOR EASY COPYING ---
// If your Song model doesn't have copyWith yet, add this extension helper
// strictly for testing purposes if you don't want to modify the real model.
extension SongCopyWith on Song {
  Song copyWith({String? id, String? title, String? key, String? originalKey}) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artists: this.artists,
      lyricLines: this.lyricLines,
      createdAt: this.createdAt,
      key: key ?? this.key,
    );
  }
}
