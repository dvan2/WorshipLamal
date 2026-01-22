import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/core/utils/apply_song_filter.dart';
import 'package:worship_lamal/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/presentation/providers/song_filter_provider.dart';
import 'package:worship_lamal/features/songs/presentation/providers/song_provider.dart'; // Import songListProvider

// --- STEP 1: The Independent State Buckets ---

// A. Search Text for the Picker
final pickerSearchProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

// B. Filter Settings for the Picker
final pickerFilterProvider =
    NotifierProvider<SongFilterNotifier, SongFilterState>(() {
      return SongFilterNotifier();
    });

// --- STEP 2: The Logic Provider ---

final pickerFilteredSongsProvider = FutureProvider.autoDispose<List<Song>>((
  ref,
) async {
  // 1. Get the Raw Data (Reused from main provider cache!)
  final allSongs = await ref.watch(songListProvider.future);

  // 2. Watch the PICKER specific inputs
  final query = ref.watch(pickerSearchProvider).toLowerCase();
  final filters = ref.watch(pickerFilterProvider);

  Set<String> favoriteIds = {};
  if (filters.showFavoritesOnly) {
    final favorites = await ref.watch(favoritesListProvider.future);
    favoriteIds = favorites.map((f) => f.songId).toSet();
  }

  // 3. Use the shared helper logic
  return applyFilterAndSort(
    allSongs: allSongs,
    query: query,
    filters: filters,
    favoriteIds: favoriteIds,
  );
});
