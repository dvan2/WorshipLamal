// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:worship_lamal/core/utils/apply_song_filter.dart';
// import 'package:worship_lamal/features/favorites/presentation/providers/favorites_provider.dart';
// import 'package:worship_lamal/features/songs/data/models/song_model.dart';
// import 'package:worship_lamal/features/songs/presentation/providers/song_filter_provider.dart';
// import 'package:worship_lamal/features/songs/presentation/providers/song_provider.dart'; // Import songListProvider

// // --- STEP 1: The Independent State Buckets ---

// // A. Search Text for the Picker
// final pickerSearchProvider = NotifierProvider<SearchQueryNotifier, String>(() {
//   return SearchQueryNotifier();
// });

// // B. Filter Settings for the Picker
// final pickerFilterProvider =
//     NotifierProvider<SongFilterNotifier, SongFilterState>(() {
//       return SongFilterNotifier();
//     });

// final pickerFilteredSongsProvider =
//     Provider.autoDispose<AsyncValue<List<Song>>>((ref) {
//       // 1. THE SWITCH: Watch the pre-transposed, personalized list!
//       final allSongsAsync = ref.watch(personalizedSongListProvider);

//       final query = ref.watch(pickerSearchProvider).toLowerCase();
//       final filters = ref.watch(pickerFilterProvider);

//       // Handle Loading/Error states smoothly
//       if (allSongsAsync.isLoading) return const AsyncLoading();
//       if (allSongsAsync.hasError) {
//         return AsyncError(allSongsAsync.error!, allSongsAsync.stackTrace!);
//       }

//       // 2. Extract the hydrated songs
//       final allSongs = allSongsAsync.value ?? [];

//       Set<String> favoriteIds = {};
//       if (filters.showFavoritesOnly) {
//         final favAsync = ref.watch(favoritesListProvider);
//         if (favAsync.isLoading) return const AsyncLoading();
//         favoriteIds = (favAsync.value ?? []).map((f) => f.songId).toSet();
//       }

//       // 3. Filter using the standard, simplified logic
//       final result = applyFilterAndSort(
//         allSongs: allSongs,
//         query: query,
//         filters: filters,
//         favoriteIds: favoriteIds,
//         historyMap:
//             null, // Pickers usually don't need 'Recently Viewed' history
//       );

//       return AsyncData(result);
//     });
