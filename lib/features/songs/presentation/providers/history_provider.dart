import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/core/config/supabase_config.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/data/repositories/history_repository.dart';

// 1. Repository Provider
final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return HistoryRepository(client);
});

// 2. Data Provider (The List of Songs)
final recentSongsProvider = FutureProvider<List<Song>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = client.auth.currentUser?.id;
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
    final client = _ref.read(supabaseClientProvider);
    final userId = client.auth.currentUser?.id;
    if (userId == null) {
      return; // Don't log for guests
    }

    try {
      final repo = _ref.read(historyRepositoryProvider);
      await repo.addToHistory(userId, songId);
      _ref.invalidate(recentSongsProvider);
    } catch (e) {
      // Fail silently (logging shouldn't block the user)
    }
  }
}

// 4. Map Provider for fast O(1) timestamp lookups when sorting
final historyMapProvider = FutureProvider<Map<String, DateTime>>((ref) async {
  final recentSongs = await ref.watch(recentSongsProvider.future);

  final Map<String, DateTime> historyMap = {};
  final now = DateTime.now();

  for (int i = 0; i < recentSongs.length; i++) {
    final s = recentSongs[i];
    historyMap[s.id] = s.lastViewedAt ?? now.subtract(Duration(minutes: i));
  }

  return historyMap;
});
