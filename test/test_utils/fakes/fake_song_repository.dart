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
