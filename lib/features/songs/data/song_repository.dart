import 'models/song_model.dart';
import 'remote/songs_api.dart';

class SongRepository {
  final SongsApi _remote;

  SongRepository(this._remote);

  /// Fetch all songs
  Future<List<Song>> getSongs() async {
    return await _remote.fetchSongs();
  }

  Future<Song> getSongById(String id) => _remote.fetchSongById(id);
}
