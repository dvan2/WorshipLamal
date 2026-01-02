import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/setlist_model.dart';

class SetlistsApi {
  final SupabaseClient _client;

  SetlistsApi(this._client);

  /// Fetch all setlists (optionally filter by user_id if needed later)
  Future<List<Setlist>> fetchSetlists() async {
    final currentUserId = _client.auth.currentUser?.id;
    if (currentUserId == null) {
      return [];
    }
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
        .eq('user_id', currentUserId)
        .order('created_at', ascending: false);

    return (response as List).map((item) => Setlist.fromMap(item)).toList();
  }

  Future<Setlist?> fetchSetlistById(String id) async {
    try {
      final response = await _client
          .from('setlists')
          .select('''
          *,
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
              )
            )
          )
        ''')
          .eq('id', id)
          .maybeSingle(); // 👈 CHANGE THIS from .single() to .maybeSingle()

      if (response == null) return null; // Handle the empty case!

      return Setlist.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  /// Create a new empty setlist
  Future<String> createSetlist(String title, String userId) async {
    final response = await _client
        .from('setlists')
        .insert({'user_id': userId, 'title': title, 'is_public': false})
        .select('id')
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

  Future<void> deleteSetlistItem(String itemId) async {
    // We delete based on the unique ID of the ROW in setlist_items,
    // not the song_id.
    await _client.from('setlist_items').delete().eq('id', itemId);
  }

  Future<void> updateSetlistOrder(List<Map<String, dynamic>> updates) async {
    // "upsert" will update existing rows if the IDs match
    await _client.from('setlist_items').upsert(updates);
  }

  //Set list follow logics
  // Inside SetlistRepository

  Future<void> followSetlist(String setlistId) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('setlist_subscriptions').insert({
      'user_id': userId,
      'setlist_id': setlistId,
    });
  }

  Future<void> unfollowSetlist(String setlistId) async {
    final userId = _client.auth.currentUser!.id;
    await _client.from('setlist_subscriptions').delete().match({
      'user_id': userId,
      'setlist_id': setlistId,
    });
  }

  /// Fetch lists I am following
  Future<List<Setlist>> getFollowedSetlists() async {
    final userId = _client.auth.currentUser!.id;

    // We join 'setlist_subscriptions' -> 'setlists'
    final response = await _client
        .from('setlist_subscriptions')
        .select('setlists(*)') // Fetch the actual setlist data
        .eq('user_id', userId);

    // Map the nested data structure back to a List<Setlist>
    final data = List<Map<String, dynamic>>.from(response);
    return data
        .map((row) => Setlist.fromMap(row['setlists'] as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateSetlistPublicStatus(
    String setlistId,
    bool isPublic,
  ) async {
    await _client
        .from('setlists')
        .update({'is_public': isPublic})
        .eq('id', setlistId);
  }
}
