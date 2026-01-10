import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worship_lamal/features/songs/data/models/song_sort_option.dart';
import 'package:worship_lamal/features/songs/presentation/providers/song_filter_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  // Helper to access the Notifier
  SongFilterNotifier getNotifier() =>
      container.read(songFilterProvider.notifier);

  // Helper to read current State
  SongFilterState readState() => container.read(songFilterProvider);

  group('SongFilterNotifier Logic', () {
    test('Initial state should have defaults and isFiltering=false', () {
      final state = readState();
      expect(state.bpmRange, const RangeValues(40, 200));
      expect(state.selectedKeys, isEmpty);
      expect(state.isFiltering, false);
    });

    test('isFiltering becomes true when BPM changes', () {
      getNotifier().setBpmRange(const RangeValues(60, 100));

      final state = readState();
      expect(state.bpmRange, const RangeValues(60, 100));
      expect(state.isFiltering, true);
    });

    test('isFiltering becomes true when a Key is selected', () {
      getNotifier().toggleKey('C');

      final state = readState();
      expect(state.selectedKeys, contains('C'));
      expect(state.isFiltering, true);
    });

    test('resetAll reverts everything to default', () {
      // 1. Mess up the state
      final notifier = getNotifier();
      notifier.setBpmRange(const RangeValues(100, 120));
      notifier.toggleKey('G');
      notifier.setSortOption(SongSortOption.titleAz);

      // 2. Act
      notifier.resetAll();

      // 3. Assert
      final state = readState();
      expect(state.isFiltering, false);
      expect(state.selectedKeys, isEmpty);
      expect(state.sortOption, SongSortOption.newest); // Default
    });
  });
}
