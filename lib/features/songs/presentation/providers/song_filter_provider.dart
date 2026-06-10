import 'dart:async';

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
  final Set<SongType> selectedTypes; // NEW: For Hymn, Praise, Worship
  final Set<String> selectedThemes;
  final RangeValues bpmRange;
  final bool isFiltering;
  final SongSortOption sortOption;
  final bool showFavoritesOnly;

  const SongFilterState({
    this.selectedKeys = const {},
    this.bpmRange = const RangeValues(40, 200), // Default BPM range
    this.selectedTypes = const {}, // NEW
    this.selectedThemes = const {},
    this.isFiltering = false,
    this.sortOption = SongSortOption.newest, //Default
    this.showFavoritesOnly = false,
  });

  SongFilterState copyWith({
    Set<String>? selectedKeys,
    Set<SongType>? selectedTypes,
    Set<String>? selectedThemes,
    RangeValues? bpmRange,
    SongSortOption? sortOption,
    bool? showFavoritesOnly,
  }) {
    final nextKeys = selectedKeys ?? this.selectedKeys;
    final nextTypes = selectedTypes ?? this.selectedTypes;
    final nextThemes = selectedThemes ?? this.selectedThemes;
    final nextBpm = bpmRange ?? this.bpmRange;
    final nextFavs = showFavoritesOnly ?? this.showFavoritesOnly;

    return SongFilterState(
      selectedKeys: nextKeys,
      selectedTypes: nextTypes,
      selectedThemes: nextThemes,
      bpmRange: nextBpm,
      sortOption: sortOption ?? this.sortOption,
      showFavoritesOnly: nextFavs,
      // Logic: If any filter deviates from default, we are filtering.
      isFiltering:
          nextKeys.isNotEmpty ||
          nextTypes.isNotEmpty ||
          nextThemes.isNotEmpty ||
          nextBpm != const RangeValues(40, 200) ||
          nextFavs,
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

  void toggleType(SongType type) {
    final current = Set<SongType>.from(state.selectedTypes);
    current.contains(type) ? current.remove(type) : current.add(type);
    state = state.copyWith(selectedTypes: current);
  }

  void toggleTheme(String theme) {
    final current = Set<String>.from(state.selectedThemes);
    current.contains(theme) ? current.remove(theme) : current.add(theme);
    state = state.copyWith(selectedThemes: current);
  }

  void clearKeyFilter() {
    state = state.copyWith(selectedKeys: {});
  }

  void resetAll() {
    state = const SongFilterState();
  }

  void applyExclusiveFilter({
    SongType? type,
    String? keyName,
    bool favoritesOnly = false,
  }) {
    // We create a brand new state (which resets everything to default)
    // and ONLY inject the specific filter the user tapped on the Dashboard.
    state = SongFilterState(
      selectedTypes: type != null ? {type} : const {},
      selectedKeys: keyName != null ? {keyName} : const {},
      showFavoritesOnly: favoritesOnly,
      // Keeps defaults for BPM, Sorting, etc.
    );
  }

  void setFilters({
    required Set<String> selectedKeys,
    required Set<SongType> selectedTypes,
    required Set<String> selectedThemes,
    required RangeValues bpmRange,
    required SongSortOption sortOption,
    required bool showFavoritesOnly,
  }) {
    state = state.copyWith(
      selectedKeys: selectedKeys,
      selectedTypes: selectedTypes,
      selectedThemes: selectedThemes,
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
  Timer? _debounce;

  @override
  String build() {
    ref.onDispose(() {
      _debounce?.cancel();
    });

    return '';
  }

  void setQuery(String query) {
    // 1. Cancel the existing timer if the user is still actively typing
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    // 2. Start a new timer
    _debounce = Timer(const Duration(milliseconds: 300), () {
      // 3. This code only runs if 300ms pass without another keystroke!
      state = query;
    });
  }

  void clear() {
    // If they hit the "X" button to clear the search, cancel the timer instantly
    _debounce?.cancel();
    state = '';
  }
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() {
  return SearchQueryNotifier();
});

final filteredSongsProvider = Provider<AsyncValue<List<Song>>>((ref) {
  final allSongsAsync = ref.watch(songListProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final filters = ref.watch(songFilterProvider);

  // 1. If the raw database is still downloading, show loading screen
  if (allSongsAsync.isLoading) return const AsyncLoading();
  if (allSongsAsync.hasError) {
    return AsyncError(allSongsAsync.error!, allSongsAsync.stackTrace!);
  }

  // 2. Safe to extract the full list now
  final allSongs = allSongsAsync.value ?? [];

  // 3. Handle Favorites asynchronously if needed
  Set<String> favoriteIds = {};
  if (filters.showFavoritesOnly) {
    final favAsync = ref.watch(favoritesListProvider);
    if (favAsync.isLoading) return const AsyncLoading();
    favoriteIds = (favAsync.value ?? []).map((f) => f.songId).toSet();
  }

  // 4. Handle History asynchronously if needed
  Map<String, DateTime>? historyMap;
  if (filters.sortOption == SongSortOption.recentlyViewed) {
    final historyAsync = ref.watch(historyMapProvider);
    if (historyAsync.isLoading) return const AsyncLoading();
    historyMap = historyAsync.value;
  }

  // 5. Apply the filter INSTANTLY (Synchronously)
  final result = applyFilterAndSort(
    allSongs: allSongs,
    query: query,
    filters: filters,
    favoriteIds: favoriteIds,
    historyMap: historyMap,
  );

  return AsyncData(result);
});

final pickerFilteredSongsProvider = Provider<AsyncValue<List<Song>>>((ref) {
  final allSongsAsync = ref.watch(songListProvider);
  final query = ref.watch(pickerSearchQueryProvider).toLowerCase();
  final filters = ref.watch(pickerFilterProvider);

  if (allSongsAsync.isLoading) return const AsyncLoading();
  if (allSongsAsync.hasError) {
    return AsyncError(allSongsAsync.error!, allSongsAsync.stackTrace!);
  }

  final allSongs = allSongsAsync.value ?? [];

  Set<String> favoriteIds = {};
  if (filters.showFavoritesOnly) {
    final favAsync = ref.watch(favoritesListProvider);
    if (favAsync.isLoading) return const AsyncLoading();
    favoriteIds = (favAsync.value ?? []).map((f) => f.songId).toSet();
  }

  Map<String, DateTime>? historyMap;
  if (filters.sortOption == SongSortOption.recentlyViewed) {
    final historyAsync = ref.watch(historyMapProvider);
    if (historyAsync.isLoading) return const AsyncLoading();
    historyMap = historyAsync.value;
  }

  final result = applyFilterAndSort(
    allSongs: allSongs,
    query: query,
    filters: filters,
    favoriteIds: favoriteIds,
    historyMap: historyMap,
  );

  return AsyncData(result);
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
