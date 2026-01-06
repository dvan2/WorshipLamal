import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Ensure this path matches your project structure
import 'package:worship_lamal/features/songs/data/models/song_sort_option.dart';

// 1. STATE OBJECT
class SongFilterState {
  final Set<String> selectedKeys;
  final RangeValues bpmRange;
  final bool isFiltering;
  final SongSortOption sortOption;

  const SongFilterState({
    this.selectedKeys = const {},
    this.bpmRange = const RangeValues(40, 200), // Default BPM range
    this.isFiltering = false,
    this.sortOption = SongSortOption.newest,
  });

  SongFilterState copyWith({
    Set<String>? selectedKeys,
    RangeValues? bpmRange,
    SongSortOption? sortOption,
  }) {
    return SongFilterState(
      selectedKeys: selectedKeys ?? this.selectedKeys,
      bpmRange: bpmRange ?? this.bpmRange,
      sortOption: sortOption ?? this.sortOption,
      // Logic: If range is not default OR keys are not empty, we are filtering.
      isFiltering:
          (selectedKeys ?? this.selectedKeys).isNotEmpty ||
          (bpmRange ?? this.bpmRange) != const RangeValues(40, 200),
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
  }) {
    state = state.copyWith(
      selectedKeys: selectedKeys,
      bpmRange: bpmRange,
      sortOption: sortOption,
    );
  }
}

// 3. PROVIDER
final songFilterProvider =
    NotifierProvider<SongFilterNotifier, SongFilterState>(() {
      return SongFilterNotifier();
    });
