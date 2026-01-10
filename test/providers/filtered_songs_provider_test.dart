import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/data/models/song_sort_option.dart';
import 'package:worship_lamal/features/songs/presentation/providers/song_filter_provider.dart';
import 'package:worship_lamal/features/songs/presentation/providers/song_provider.dart';

Artist makeArtist(String name) => Artist(id: 'id_$name', name: name);

final kMockSongs = [
  Song(
    id: '1',
    title: 'Amazing Grace',
    // FIX: Create real Artist objects instead of strings
    artists: [makeArtist('Hymn')],
    key: 'G',
    bpm: 80,
    createdAt: DateTime(2023, 1, 1),
    lyricLines: const [],
  ),
  Song(
    id: '2',
    title: 'Cornerstone',
    artists: [makeArtist('Hillsong')],
    key: 'C',
    bpm: 72,
    createdAt: DateTime(2023, 5, 1),
    lyricLines: const [],
  ),
  Song(
    id: '3',
    title: 'Way Maker',
    artists: [makeArtist('Sinach')],
    key: 'E',
    bpm: 68,
    createdAt: DateTime(2022, 12, 1),
    lyricLines: const [],
  ),
  Song(
    id: '4',
    title: 'Zebra Song',
    artists: [makeArtist('Zoo Band')],
    key: 'G',
    bpm: 120,
    createdAt: DateTime(2020, 1, 1),
    lyricLines: const [],
  ),
];

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer(
      overrides: [
        // CRITICAL: We override the "Raw Data" provider to return our fake list
        // so we don't hit the API or Supabase.
        songListProvider.overrideWith((ref) => kMockSongs),
      ],
    );
  });

  tearDown(() => container.dispose());

  group('FilteredSongsProvider Integration', () {
    test('Search: finds songs by title (Case Insensitive)', () async {
      // Act: Set search query
      container.read(searchQueryProvider.notifier).setQuery('amazing');

      // Assert
      final result = await container.read(filteredSongsProvider.future);
      expect(result.length, 1);
      expect(result.first.title, 'Amazing Grace');
    });

    test('Filter: returns only songs with matching Key', () async {
      // Act: Toggle Key 'C'
      container.read(songFilterProvider.notifier).toggleKey('C');

      // Assert
      final result = await container.read(filteredSongsProvider.future);
      expect(result.length, 1);
      expect(result.first.title, 'Cornerstone');
    });

    test('Filter: excludes songs outside BPM range', () async {
      // Act: Set BPM Range to 100-200 (Only Zebra Song is 120)
      container
          .read(songFilterProvider.notifier)
          .setBpmRange(const RangeValues(100, 200));

      // Assert
      final result = await container.read(filteredSongsProvider.future);
      expect(result.length, 1);
      expect(result.first.title, 'Zebra Song');
    });

    test('Sort: orders by Title A-Z', () async {
      // Act
      container
          .read(songFilterProvider.notifier)
          .setSortOption(SongSortOption.titleAz);

      // Assert
      final result = await container.read(filteredSongsProvider.future);
      expect(result.first.title, 'Amazing Grace');
      expect(result.last.title, 'Zebra Song');
    });

    test('Sort: orders by Newest First (Date)', () async {
      // Act
      container
          .read(songFilterProvider.notifier)
          .setSortOption(SongSortOption.newest);

      // Assert
      final result = await container.read(filteredSongsProvider.future);
      expect(
        result.first.title,
        'Cornerstone',
        reason: "Cornerstone is May 2023 (Newest)",
      );
      expect(result.last.title, 'Zebra Song', reason: "Zebra is 2020 (Oldest)");
    });
  });
}
