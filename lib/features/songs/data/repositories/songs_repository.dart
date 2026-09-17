import '../models/song_model.dart';
import '../remote/songs_api.dart';

class SongsRepository {
  final SongsApi _remote;

  SongsRepository(this._remote);

  /// Fetch all songs
  Future<List<Song>> getSongs() async {
    return await _remote.fetchSongs();
  }

  Future<Song> getSongById(String id) => _remote.fetchSongById(id);
}
