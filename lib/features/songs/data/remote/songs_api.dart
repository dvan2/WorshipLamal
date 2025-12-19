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

  // Alternative: If you need to ensure ordering, do it in your model's fromMap
  // or sort after fetching:

  Future<Song> fetchSongByIdWithOrdering(String id) async {
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

    final song = Song.fromMap(response);

    // Sort lyric lines after fetching if needed
    song.lyricLines.sort((a, b) => a.lineNumber.compareTo(b.lineNumber));

    return song;
  }
}
