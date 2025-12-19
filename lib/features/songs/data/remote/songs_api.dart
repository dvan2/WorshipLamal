import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/song_model.dart';

class SongsApi {
  final SupabaseClient _client;

  SongsApi(this._client);

  /// Fetch all songs with lyric lines
  Future<List<Song>> fetchSongs() async {
    final response = await _client
        .from('songs')
        .select('''
          id,
          title,
          artist,
          lyric_lines (
            content,
            line_number
          )
        ''')
        .order('title');

    return (response as List).map((item) => Song.fromMap(item)).toList();
  }

  /// Fetch a single song by ID
  Future<Song> fetchSongById(String id) async {
    final response = await _client
        .from('songs')
        .select('''
          id,
          title,
          artist,
          lyric_lines (
            content,
            line_number
          )
        ''')
        .eq('id', id)
        .single();

    return Song.fromMap(response);
  }
}
