import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';

class HistoryRepository {
  final SupabaseClient _client;

  HistoryRepository(this._client);

  /// Upsert: Adds to history OR updates timestamp if already there
  Future<void> addToHistory(String userId, String songId) async {
    await _client.from('user_song_history').upsert({
      'user_id': userId,
      'song_id': songId,
      'viewed_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Song>> getRecentSongs(String userId) async {
    // 1. Fetch joined data
    // Result looks like:
    // [ { "viewed_at": "...", "songs": { "id": "...", "title": "..." } } ]
    final response = await _client
        .from('user_song_history')
        .select('viewed_at, songs(*, song_artists(artists(*)), lyric_lines(*))')
        // Note: Ensure your select includes all nested relations your Song.fromMap needs
        .eq('user_id', userId)
        .order('viewed_at', ascending: false)
        .limit(20);

    final data = response as List<dynamic>;

    // 2. Map manually
    final result = data.map((row) {
      // A. Extract the nested song object
      final songMap = row['songs'] as Map<String, dynamic>;

      // B. Create the base Song
      final song = Song.fromMap(songMap);

      // C. Extract the timestamp from the history row
      final viewedAt = DateTime.parse(row['viewed_at'] as String);

      // D. Return combined object using copyWith
      return song.copyWith(lastViewedAt: viewedAt);
    }).toList();

    return result;
  }
}
