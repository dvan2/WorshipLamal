import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/setlist_model.dart';

class SetlistsApi {
  final SupabaseClient _client;

  SetlistsApi(this._client);

  /// Fetch all setlists (optionally filter by user_id if needed later)
  Future<List<Setlist>> fetchSetlists() async {
    final response = await _client
        .from('setlists')
        .select('''
        id,
        title,
        is_public,
        created_at,
        setlist_items (
          id,
          sort_order,
          key_override,
          song_id,
          songs (
            id,
            title,
            key,
            bpm,
            song_artists(
              artists(
                id,
                name
              )
            )
          )
        )
      ''')
        .order('created_at', ascending: false);

    return (response as List).map((item) => Setlist.fromMap(item)).toList();
  }

  /// Fetch a single setlist with FULL details (including lyrics)
  Future<Setlist> fetchSetlistById(String id) async {
    final response = await _client
        .from('setlists')
        .select('''
          id,
          title,
          is_public,
          created_at,
          setlist_items (
            id,
            sort_order,
            key_override,
            song_id,
            songs (
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
            )
          )
        ''')
        .eq('id', id)
        .single();

    final setlist = Setlist.fromMap(response);
    // Sort items by the sort_order field locally to be safe
    setlist.items.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return setlist;
  }

  /// Create a new empty setlist
  Future<String> createSetlist(String title, String userId) async {
    final response = await _client
        .from('setlists')
        .insert({'user_id': userId, 'title': title, 'is_public': false})
        .select()
        .single();

    return response['id'];
  }

  /// Add a song to a setlist
  Future<void> addSongToSetlist({
    required String setlistId,
    required String songId,
    required int order,
  }) async {
    await _client.from('setlist_items').insert({
      'setlist_id': setlistId,
      'song_id': songId,
      'sort_order': order,
    });
  }

  Future<void> updateKeyOverride(String itemId, String newKey) async {
    await _client
        .from('setlist_items')
        .update({'key_override': newKey})
        .eq('id', itemId);
  }
}
