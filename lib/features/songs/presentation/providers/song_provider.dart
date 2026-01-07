import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/features/songs/presentation/providers/song_filter_provider.dart';
import 'package:worship_lamal/features/songs/data/models/song_sort_option.dart';

import '../../data/models/song_model.dart';
import '../../data/remote/songs_api.dart';
import '../../data/song_repository.dart';
import '../../../../core/config/supabase_config.dart';

// --- DATA LAYER ---
final songsApiProvider = Provider<SongsApi>((ref) {
  return SongsApi(ref.read(supabaseClientProvider));
});

final songRepositoryProvider = Provider<SongRepository>((ref) {
  return SongRepository(ref.read(songsApiProvider));
});

// --- RAW DATA PROVIDER ---
final songListProvider = FutureProvider<List<Song>>((ref) async {
  return ref.read(songRepositoryProvider).getSongs();
});

final songDetailProvider = FutureProvider.family<Song, String>((
  ref,
  songId,
) async {
  return ref.read(songRepositoryProvider).getSongById(songId);
});

// --- STATE ---
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() {
    return '';
  }

  void setQuery(String query) {
    state = query;
  }

  void clear() {
    state = '';
  }
}

// 2. The Provider
final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

// --- LOGIC PROVIDER (Filter + Sort) ---
final filteredSongsProvider = FutureProvider<List<Song>>((ref) async {
  // 1. Watch all inputs
  // usage of .future ensures we get the list without triggering a loading state
  // if the list is already cached.
  final allSongs = await ref.watch(songListProvider.future);

  final query = ref.watch(searchQueryProvider).toLowerCase();
  final filters = ref.watch(songFilterProvider);

  // 2. Apply Filtering
  var filteredList = allSongs.where((song) {
    // A. Text Search
    final matchesText =
        song.title.toLowerCase().contains(query) ||
        song.artistNames.toLowerCase().contains(query);

    if (!matchesText) return false;

    // B. Key Filter
    if (filters.selectedKeys.isNotEmpty) {
      if (!filters.selectedKeys.contains(song.key)) return false;
    }

    // C. BPM Filter
    if (song.bpm != null) {
      if (song.bpm! < filters.bpmRange.start ||
          song.bpm! > filters.bpmRange.end) {
        return false;
      }
    }

    return true;
  }).toList(); // Convert to list so we can sort it

  // 3. Apply Sorting (New Logic)
  switch (filters.sortOption) {
    case SongSortOption.titleAz:
      filteredList.sort((a, b) => a.title.compareTo(b.title));
      break;
    // case SongSortOption.titleZa:
    //   filteredList.sort((a, b) => b.title.compareTo(a.title));
    //   break;
    case SongSortOption.artistAz:
      filteredList.sort((a, b) => a.artistNames.compareTo(b.artistNames));
      break;
    case SongSortOption.newest:
      filteredList.sort((a, b) {
        // Handle Nulls: If date is missing, push to bottom
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      break;
    // case SongSortOption.oldest:
    //   filteredList.sort((a, b) {
    //     // Handle Nulls
    //     if (a.createdAt == null) return 1;
    //     if (b.createdAt == null) return -1;
    //     return a.createdAt!.compareTo(b.createdAt!);
    //   });
    //   break;
  }

  return filteredList;
});
