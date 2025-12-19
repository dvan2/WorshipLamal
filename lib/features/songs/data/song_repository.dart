import 'models/song_model.dart';
import 'remote/songs_api.dart';

class SongRepository {
  final SongsApi _remote;

  SongRepository(this._remote);

  /// Fetch all songs
  Future<List<Song>> getSongs() async {
    return await _remote.fetchSongs();
  }

  /// Fetch a single song by ID
  Future<Song> getSongById(String id) async {
    final songs = await getSongs();
    return songs.firstWhere(
      (song) => song.id == id,
      orElse: () => throw Exception('Song not found'),
    );
  }
}
