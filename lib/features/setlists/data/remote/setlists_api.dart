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

    final data = response as List<dynamic>;

    return data.map((e) => Setlist.fromMap(e as Map<String, dynamic>)).toList();
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
          .order(
            'sort_order',
            referencedTable: 'setlist_items',
            ascending: true,
          )
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
    String? key_override,
  }) async {
    await _client.from('setlist_items').insert({
      'setlist_id': setlistId,
      'song_id': songId,
      'sort_order': order,
      'key_override': key_override,
    });
  }

  Future<void> addSetlistItems(List<Map<String, dynamic>> items) async {
    // 'insert' accepts a List of Maps for bulk creation
    await _client.from('setlist_items').insert(items);
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

  Future<void> deleteAndNormalize(String itemId, String setlistId) async {
    await _client.rpc(
      'delete_setlist_item_and_normalize',
      params: {'target_item_id': itemId, 'target_setlist_id': setlistId},
    );
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

  Future<List<Setlist>> getFollowedSetlists() async {
    final userId = _client.auth.currentUser!.id;

    final response = await _client
        .from('setlist_subscriptions')
        .select('''
        setlists (
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
        )
      ''')
        .eq('user_id', userId);

    final listData = response as List<dynamic>;

    return listData
        .map((item) {
          // 1. Cast item to Map
          final row = item as Map<String, dynamic>;
          // 2. Extract the nested object
          final setlistData = row['setlists'];

          // 3. Handle potential nulls
          if (setlistData == null) return null;

          // 4. Convert to Setlist
          return Setlist.fromMap(setlistData as Map<String, dynamic>);
        })
        .whereType<Setlist>() // 5. Remove nulls
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
