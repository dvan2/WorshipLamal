// Defines filter logic for song picker screen

import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/data/models/song_sort_option.dart';
import 'package:worship_lamal/features/songs/presentation/providers/song_filter_provider.dart';

/// Shared logic to filter and sort a list of songs
List<Song> applySongFilters({
  required List<Song> allSongs,
  required String query,
  required SongFilterState filters,
}) {
  // 1. Apply Filtering
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
  }).toList();

  // 2. Apply Sorting
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
  }

  return filteredList;
}
