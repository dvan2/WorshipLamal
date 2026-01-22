import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/core/utils/apply_song_filter.dart';
import 'package:worship_lamal/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/data/models/song_sort_option.dart';
import 'package:worship_lamal/features/songs/presentation/providers/history_provider.dart';
import 'package:worship_lamal/features/songs/presentation/providers/song_provider.dart';

// 1. STATE OBJECT
class SongFilterState {
  final Set<String> selectedKeys;
  final RangeValues bpmRange;
  final bool isFiltering;
  final SongSortOption sortOption;
  final bool showFavoritesOnly;

  const SongFilterState({
    this.selectedKeys = const {},
    this.bpmRange = const RangeValues(40, 200), // Default BPM range
    this.isFiltering = false,
    this.sortOption = SongSortOption.newest, //Default
    this.showFavoritesOnly = false,
  });

  SongFilterState copyWith({
    Set<String>? selectedKeys,
    RangeValues? bpmRange,
    SongSortOption? sortOption,
    bool? showFavoritesOnly,
  }) {
    return SongFilterState(
      selectedKeys: selectedKeys ?? this.selectedKeys,
      bpmRange: bpmRange ?? this.bpmRange,
      sortOption: sortOption ?? this.sortOption,
      showFavoritesOnly: showFavoritesOnly ?? this.showFavoritesOnly,
      // Logic: If range is not default OR keys are not empty, we are filtering.
      isFiltering:
          (selectedKeys ?? this.selectedKeys).isNotEmpty ||
          (bpmRange ?? this.bpmRange) != const RangeValues(40, 200) ||
          (showFavoritesOnly ?? this.showFavoritesOnly),
    );
  }
}

class SongFilterNotifier extends Notifier<SongFilterState> {
  @override
  SongFilterState build() {
    return const SongFilterState(); // Initial State
  }

  void setBpmRange(RangeValues range) {
    state = state.copyWith(bpmRange: range);
  }

  void setSortOption(SongSortOption option) {
    state = state.copyWith(sortOption: option);
  }

  void toggleFavoritesFilter() {
    state = state.copyWith(showFavoritesOnly: !state.showFavoritesOnly);
  }

  void toggleKey(String key) {
    final current = Set<String>.from(state.selectedKeys);
    if (current.contains(key)) {
      current.remove(key);
    } else {
      current.add(key);
    }
    state = state.copyWith(selectedKeys: current);
  }

  void clearKeyFilter() {
    state = state.copyWith(selectedKeys: {});
  }

  void resetAll() {
    state = const SongFilterState();
  }

  // Batch update (useful for the "Show Results" button)
  void setFilters({
    required Set<String> selectedKeys,
    required RangeValues bpmRange,
    required SongSortOption sortOption,
    required bool showFavoritesOnly,
  }) {
    state = state.copyWith(
      selectedKeys: selectedKeys,
      bpmRange: bpmRange,
      sortOption: sortOption,
      showFavoritesOnly: showFavoritesOnly,
    );
  }
}

final songFilterProvider =
    NotifierProvider<SongFilterNotifier, SongFilterState>(() {
      return SongFilterNotifier();
    });

final pickerSearchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  () {
    return SearchQueryNotifier();
  },
);

final pickerFilterProvider =
    NotifierProvider<SongFilterNotifier, SongFilterState>(() {
      return SongFilterNotifier();
    });

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

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

final filteredSongsProvider = FutureProvider<List<Song>>((ref) async {
  final allSongs = await ref.watch(songListProvider.future);

  final query = ref.watch(searchQueryProvider).toLowerCase();
  final filters = ref.watch(songFilterProvider);

  Set<String> favoriteIds = {};
  if (filters.showFavoritesOnly) {
    final favorites = await ref.watch(favoritesListProvider.future);
    favoriteIds = favorites.map((f) => f.songId).toSet();
  }

  Map<String, DateTime>? historyMap;
  if (filters.sortOption == SongSortOption.recentlyViewed) {
    historyMap = await ref.watch(historyMapProvider.future);
  }

  return applyFilterAndSort(
    allSongs: allSongs,
    query: query,
    filters: filters,
    favoriteIds: favoriteIds,
    historyMap: historyMap,
  );
});

final pickerFilteredSongsProvider = FutureProvider<List<Song>>((ref) async {
  final allSongs = await ref.watch(songListProvider.future);

  Set<String> favoriteIds = {};
  final filters = ref.watch(pickerFilterProvider);
  final query = ref.watch(pickerSearchQueryProvider);

  if (filters.showFavoritesOnly) {
    final favorites = await ref.watch(favoritesListProvider.future);
    favoriteIds = favorites.map((f) => f.songId).toSet();
  }

  Map<String, DateTime>? historyMap;
  if (filters.sortOption == SongSortOption.recentlyViewed) {
    historyMap = await ref.watch(historyMapProvider.future);
  }

  return applyFilterAndSort(
    allSongs: allSongs,
    query: query,
    filters: filters,
    favoriteIds: favoriteIds,
    historyMap: historyMap,
  );
});

final historyMapProvider = FutureProvider<Map<String, DateTime>>((ref) async {
  final recentSongs = await ref.watch(recentSongsProvider.future);

  final Map<String, DateTime> historyMap = {};
  final now = DateTime.now();

  for (int i = 0; i < recentSongs.length; i++) {
    final s = recentSongs[i];
    // Use real timestamp if available, otherwise fake it based on order
    historyMap[s.id] = s.lastViewedAt ?? now.subtract(Duration(minutes: i));
  }

  return historyMap;
});
