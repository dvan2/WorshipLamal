import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/features/favorites/data/model/favorite_model.dart';
import 'package:worship_lamal/features/favorites/data/remote/favorites_api.dart';

class FavoritesRepository {
  final FavoritesApi _api;

  FavoritesRepository(this._api);

  // Helper to get current ID safely
  String get _currentUserId {
    final id = Supabase.instance.client.auth.currentUser?.id;
    if (id == null) {
      throw Exception('User must be logged in to manage favorites');
    }
    return id;
  }

  /// Get the list of favorites
  Future<List<Favorite>> getFavorites() async {
    // If not logged in, return empty list instead of crashing
    final id = Supabase.instance.client.auth.currentUser?.id;
    if (id == null) return [];

    return _api.fetchUserFavorites(id);
  }

  /// Add a song to favorites
  Future<void> addFavorite(String songId) async {
    return _api.addFavorite(_currentUserId, songId);
  }

  /// Remove a song from favorites
  Future<void> removeFavorite(String songId) async {
    return _api.removeFavorite(_currentUserId, songId);
  }
}
