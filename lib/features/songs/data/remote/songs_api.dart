import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/song_model.dart';

class SongsApi {
  final SupabaseClient _client;

  SongsApi(this._client);
  Future<List<Song>> fetchSongs() async {
    final response = await _client.from('songs').select('''
        id,
        title,
        key,
        bpm,
        created_at,
        song_artists(
          artists(
            id,
            name
          )
        ),
        lyric_lines (
          id,
          content,
          line_number,
          section_type
        )
      ''');

    return (response as List).map((item) => Song.fromMap(item)).toList();
  }

  Future<Song> fetchSongById(String id) async {
    final response = await _client
        .from('songs')
        .select('''
        id,
        title,
        key,
        bpm,
        song_artists (
          artists (
            id,
            name
          )
        ),
        lyric_lines (
          id,
          content,
          line_number,
          section_type
        )
      ''')
        .eq('id', id)
        .single();

    return Song.fromMap(response);
  }
}
