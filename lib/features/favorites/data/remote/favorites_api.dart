import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/features/favorites/data/model/favorite_model.dart';

class FavoritesApi {
  final SupabaseClient _client;

  FavoritesApi(this._client);

  /// Fetch all favorites for a specific user, including full Song details
  Future<List<Favorite>> fetchUserFavorites(String userId) async {
    final response = await _client
        .from('favorites')
        .select('''
          user_id,
          song_id,
          created_at,
          songs (
            id,
            title,
            key,
            bpm,
            created_at,
            song_artists (
              artists (
                id,
                name
              )
            )
          )
        ''')
        .eq('user_id', userId)
        .order('created_at', ascending: false); // Newest on top

    return (response as List).map((item) => Favorite.fromMap(item)).toList();
  }

  /// Add a favorite
  Future<void> addFavorite(String userId, String songId) async {
    await _client.from('favorites').insert({
      'user_id': userId,
      'song_id': songId,
    });
  }

  /// Remove a favorite
  Future<void> removeFavorite(String userId, String songId) async {
    await _client.from('favorites').delete().match({
      'user_id': userId,
      'song_id': songId,
    });
  }
}
