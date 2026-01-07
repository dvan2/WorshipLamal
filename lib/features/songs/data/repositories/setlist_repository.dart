import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/features/songs/data/remote/setlists_api.dart';
import '../models/setlist_model.dart';

class SetlistRepository {
  final SetlistsApi _remote;

  SetlistRepository(this._remote);

  Future<List<Setlist>> getSetlists() async {
    return await _remote.fetchSetlists();
  }

  /// Fetch a single setlist by ID
  Future<Setlist?> getSetlistById(String id) async {
    return await _remote.fetchSetlistById(id);
  }

  /// Create a new setlist
  Future<String> createSetlist(String title) async {
    // We can get the current user ID here or pass it from the UI
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      throw Exception('User must be logged in to create a setlist');
    }

    return await _remote.createSetlist(title, userId);
  }

  /// Add song to setlist
  Future<void> addSong({
    required String setlistId,
    required String songId,
    required int order,
    String? keyOverride,
  }) async {
    return await _remote.addSongToSetlist(
      setlistId: setlistId,
      songId: songId,
      order: order,
      key_override: keyOverride,
    );
  }

  Future<void> updateKeyOverride(String itemId, String newKey) async {
    await _remote.updateKeyOverride(itemId, newKey);
  }

  Future<void> removeSong(String itemId) async {
    await _remote.deleteSetlistItem(itemId);
  }

  Future<void> reorderSetlistItems(
    String setlistId,
    List<SetlistItem> items,
  ) async {
    final updates = items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      return {
        'id': item.id, // The row to update
        'setlist_id': setlistId, // <--- FIX: Use the actual setlistId parameter
        'song_id': item.songId,
        'sort_order': index,
      };
    }).toList();

    await _remote.updateSetlistOrder(updates);
  }

  Future<void> followSetlist(String setlistId) async {
    await _remote.followSetlist(setlistId);
  }

  Future<void> unfollowSetlist(String setlistId) async {
    await _remote.unfollowSetlist(setlistId);
  }

  /// Helper to check if a specific setlist is already being followed.
  /// This is useful for the UI (showing "Follow" vs "Unfollow" button).
  Future<bool> isFollowing(String setlistId) async {
    final followedLists = await _remote.getFollowedSetlists();
    return followedLists.any((s) => s.id == setlistId);
  }

  Future<List<Setlist>> getFollowedSetlists() async {
    return await _remote.getFollowedSetlists();
  }

  Future<void> updateSetlistPublicStatus(
    String setlistId,
    bool isPublic,
  ) async {
    await _remote.updateSetlistPublicStatus(setlistId, isPublic);
  }
}
