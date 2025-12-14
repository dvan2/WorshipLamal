import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/song_model.dart';

class SongService {
  final _supabase = Supabase.instance.client;

  Future<List<Song>> fetchSongs() async {
    try {
      final response = await _supabase
          .from('songs')
          .select('id, title, artist, lyric_lines(content, line_number)');

      final List<Song> songs = (response as List)
          .map((item) => Song.fromMap(item))
          .toList();

      return songs;
    } catch (e) {
      print("Error fetching songs: $e");
      throw Exception('Failed to load songs from database');
    }
  }
}
