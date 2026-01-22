import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/data/models/song_sort_option.dart';
import 'package:worship_lamal/features/songs/presentation/providers/song_filter_provider.dart';

List<Song> applyFilterAndSort({
  required List<Song> allSongs,
  required String query,
  required SongFilterState filters,
  required Set<String> favoriteIds,
  Map<String, DateTime>? historyMap,
}) {
  // 1. Filtering
  final cleanQuery = query.toLowerCase();

  var filteredList = allSongs.where((song) {
    // A. Text Search
    final matchesText =
        song.title.toLowerCase().contains(cleanQuery) ||
        song.artistNames.toLowerCase().contains(cleanQuery);

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

    if (filters.showFavoritesOnly) {
      if (!favoriteIds.contains(song.id)) return false;
    }
    return true;
  }).toList();

  // 2. Sorting
  switch (filters.sortOption) {
    case SongSortOption.titleAz:
      filteredList.sort((a, b) => a.title.compareTo(b.title));
      break;
    case SongSortOption.artistAz:
      filteredList.sort((a, b) => a.artistNames.compareTo(b.artistNames));
      break;
    case SongSortOption.newest:
      filteredList.sort((a, b) {
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      break;
    case SongSortOption.recentlyViewed:
      if (historyMap == null || historyMap.isEmpty) {
        // Fallback: If no history, just sort A-Z
        filteredList.sort(
          (a, b) => a.title.compareTo(b.title),
        ); // FIX: Use filteredList
      } else {
        filteredList.sort((a, b) {
          // FIX: Use filteredList
          final timeA = historyMap[a.id];
          final timeB = historyMap[b.id];

          if (timeA != null && timeB != null) {
            return timeB.compareTo(timeA); // Newest first
          } else if (timeA != null) {
            return -1; // A floats to top
          } else if (timeB != null) {
            return 1; // B floats to top
          } else {
            return a.title.compareTo(b.title); // Secondary sort for unvisited
          }
        });
      }
      break;
  }

  return filteredList;
}
