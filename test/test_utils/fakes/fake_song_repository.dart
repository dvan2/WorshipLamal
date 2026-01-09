import 'package:worship_lamal/features/profile/presentation/providers/preferences_provider.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/data/song_repository.dart';

class FakeSongRepository implements SongRepository {
  FakeSongRepository({this.songs = const []});

  final List<Song> songs;

  @override
  Future<List<Song>> getSongs() async {
    return songs;
  }

  @override
  Future<Song> getSongById(String id) async {
    return songs.firstWhere(
      (song) => song.id == id,
      orElse: () => throw Exception('Song not found'),
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

// 1. Extend the real Notifier
class MockPreferencesNotifier extends PreferencesNotifier {
  @override
  // The return type must match your real Notifier's state class!
  // (It is likely 'PreferencesState', not 'VocalMode')
  PreferencesState build() {
    // 2. Return the full State Object, not just the enum
    return const PreferencesState(
      vocalMode: VocalMode.original, // Set the default for tests
    );
  }
}
