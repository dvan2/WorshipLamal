import 'package:worship_lamal/features/songs/data/models/lyric_line_model.dart';
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

  var filteredList = allSongs
      .where((song) {
        if (filters.selectedKeys.isNotEmpty &&
            !filters.selectedKeys.contains(song.key))
          return false;

        // C. BPM Filter
        if (song.bpm != null) {
          if (song.bpm! < filters.bpmRange.start ||
              song.bpm! > filters.bpmRange.end) {
            return false;
          }
        }

        // D. NEW: Type Filter (Worship, Praise, Hymn)
        if (filters.selectedTypes.isNotEmpty) {
          if (!filters.selectedTypes.contains(song.type)) return false;
        }

        // E. NEW: Theme Filter (Cross, Blood, Joy)
        if (filters.selectedThemes.isNotEmpty) {
          // Check if the song has at least ONE of the selected themes
          bool hasMatchingTheme = song.themes.any(
            (theme) => filters.selectedThemes.contains(theme),
          );

          if (!hasMatchingTheme) return false;
        }

        // F. Favorites Filter
        if (filters.showFavoritesOnly) {
          if (!favoriteIds.contains(song.id)) return false;
        }

        return true;
      })
      .map((song) {
        if (cleanQuery.isEmpty) {
          return song.copyWith(isTitleMatch: true, searchSnippet: null);
        }

        bool matchesTitle =
            song.title.toLowerCase().contains(cleanQuery) ||
            song.artistNames.toLowerCase().contains(cleanQuery);

        LyricLine? matchedLine;
        if (!matchesTitle) {
          try {
            // Find the very first lyric line that contains the search word
            matchedLine = song.lyricLines.firstWhere(
              (line) => line.content.toLowerCase().contains(cleanQuery),
            );
          } catch (_) {
            matchedLine = null; // No lyric match found
          }
        }

        if (!matchesTitle && matchedLine == null) {
          return null;
        }

        return song.copyWith(
          isTitleMatch: matchesTitle,
          searchSnippet: matchedLine?.content.trim(),
        );
      })
      .whereType<Song>()
      .toList();

  filteredList.sort((a, b) {
    // A. Priority Sorting: Force Title matches to the top during an active search
    if (cleanQuery.isNotEmpty) {
      if (a.isTitleMatch && !b.isTitleMatch) return -1; // A moves up
      if (!a.isTitleMatch && b.isTitleMatch) return 1; // B moves up
    }

    switch (filters.sortOption) {
      case SongSortOption.titleAz:
        return a.title.compareTo(b.title);

      case SongSortOption.newest:
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);

      case SongSortOption.recentlyViewed:
        if (historyMap == null || historyMap.isEmpty) {
          return a.title.compareTo(b.title);
        }
        final timeA = historyMap[a.id];
        final timeB = historyMap[b.id];
        if (timeA != null && timeB != null) return timeB.compareTo(timeA);
        if (timeA != null) return -1;
        if (timeB != null) return 1;
        return a.title.compareTo(b.title);
    }
  });

  return filteredList;
}
