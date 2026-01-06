import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

// 1. The State Object (Holds the values)
class SongFilterState {
  final Set<String> selectedKeys;
  final bpmRange;
  final bool isFiltering;

  const SongFilterState({
    this.selectedKeys = const {},
    this.bpmRange = const RangeValues(40, 200), // Default BPM range
    this.isFiltering = false,
  });

  SongFilterState copyWith({Set<String>? selectedKeys, RangeValues? bpmRange}) {
    return SongFilterState(
      selectedKeys: selectedKeys ?? this.selectedKeys,
      bpmRange: bpmRange ?? this.bpmRange,
      // Logic: If range is not default OR keys are not empty, we are filtering
      isFiltering:
          (selectedKeys ?? this.selectedKeys).isNotEmpty ||
          (bpmRange ?? this.bpmRange) != const RangeValues(40, 200),
    );
  }

  // Helper to reset
  factory SongFilterState.initial() => const SongFilterState();
}

// 2. The Notifier (Handles logic)
class SongFilterNotifier extends StateNotifier<SongFilterState> {
  SongFilterNotifier() : super(SongFilterState.initial());

  void setBpmRange(RangeValues range) {
    state = state.copyWith(bpmRange: range);
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
    state = SongFilterState.initial();
  }

  void setFilters({
    required Set<String> selectedKeys,
    required RangeValues bpmRange,
  }) {
    state = state.copyWith(selectedKeys: selectedKeys, bpmRange: bpmRange);
  }
}

// 3. The Provider
final songFilterProvider =
    StateNotifierProvider<SongFilterNotifier, SongFilterState>((ref) {
      return SongFilterNotifier();
    });
