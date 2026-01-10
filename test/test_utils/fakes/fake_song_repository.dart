import 'package:worship_lamal/features/profile/presentation/providers/preferences_provider.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/data/song_repository.dart';

import 'fixtures.dart';

class FakeSongRepository implements SongRepository {
  final List<Song> _songs;
  FakeSongRepository({List<Song>? songs}) : _songs = songs ?? kTestSongs;

  @override
  Future<List<Song>> getSongs() async {
    return _songs;
  }

  @override
  Future<Song> getSongById(String id) async {
    return _songs.firstWhere(
      (song) => song.id == id,
      orElse: () => throw Exception('Song not found: $id'),
    );
  }
}

class FakeFailingSongRepository implements SongRepository {
  @override
  Future<List<Song>> getSongs() async {
    throw Exception('Failed to load songs');
  }

  @override
  Future<Song> getSongById(String id) async {
    throw Exception('Failed to load song');
  }
}

class MockPreferencesNotifier extends PreferencesNotifier {
  // Allow us to change this from the test
  VocalMode _currentMode = VocalMode.original;

  void setMode(VocalMode mode) {
    _currentMode = mode;
    state = PreferencesState(vocalMode: mode); // Update state immediately
  }

  @override
  PreferencesState build() {
    return PreferencesState(vocalMode: _currentMode);
  }
}
