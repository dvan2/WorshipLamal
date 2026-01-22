import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/data/repositories/history_repository.dart';

// 1. Repository Provider
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return HistoryRepository(Supabase.instance.client);
});

// 2. Data Provider (The List of Songs)
final recentSongsProvider = FutureProvider<List<Song>>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];

  final repo = ref.watch(historyRepositoryProvider);
  return repo.getRecentSongs(userId);
});

// 3. Controller (The Action to Add)
final historyControllerProvider = Provider<HistoryController>((ref) {
  return HistoryController(ref);
});

class HistoryController {
  final Ref _ref;
  HistoryController(this._ref);

  Future<void> logView(String songId) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null)
      return; // Don't log for guests (or handle locally if you want)

    try {
      final repo = _ref.read(historyRepositoryProvider);
      await repo.addToHistory(userId, songId);
      _ref.invalidate(recentSongsProvider);

      // Optional: Invalidate list so "Recently Viewed" tab updates instantly
      // _ref.invalidate(recentSongsProvider);
    } catch (e) {
      // Fail silently (logging shouldn't block the user)
      print('History log failed: $e');
    }
  }
}
