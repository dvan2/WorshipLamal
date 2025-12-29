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
  Future<Setlist> getSetlistById(String id) async {
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
  }) async {
    return await _remote.addSongToSetlist(
      setlistId: setlistId,
      songId: songId,
      order: order,
    );
  }
}
