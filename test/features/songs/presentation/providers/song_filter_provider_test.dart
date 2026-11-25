import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/data/models/song_sort_option.dart';
import 'package:worship_lamal/features/songs/presentation/providers/song_filter_provider.dart';
import 'package:worship_lamal/features/songs/presentation/providers/song_provider.dart';

import '../../../../helpers/fixtures.dart';

// ---------------------------------------------------------------------------
// Synchronous SearchQueryNotifier for tests — bypasses the 300ms debounce.
// ---------------------------------------------------------------------------
class _SyncSearchNotifier extends SearchQueryNotifier {
  @override
  String build() => '';

  @override
  void setQuery(String query) => state = query;

  void setImmediate(String query) => state = query;
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ProviderContainer _makeContainer({List<Override> overrides = const []}) {
  final container = ProviderContainer.test(
    overrides: [
      // Always substitute the synchronous search notifier so tests don't
      // need to deal with the 300ms debounce timer.
      searchQueryProvider.overrideWith(() => _SyncSearchNotifier()),
      ...overrides,
    ],
  );
  return container;
}

/// Shortcut to set the search query synchronously.
void _setQuery(ProviderContainer container, String query) {
  (container.read(searchQueryProvider.notifier) as _SyncSearchNotifier)
      .setImmediate(query);
}

// ---------------------------------------------------------------------------
// SongFilterState / SongFilterNotifier
// ---------------------------------------------------------------------------

void main() {
  // =========================================================================
  group('SongFilterState.copyWith — isFiltering flag', () {
    test('defaults to isFiltering=false', () {
      const state = SongFilterState();
      expect(state.isFiltering, isFalse);
    });

    test('isFiltering becomes true when a key is added', () {
      const state = SongFilterState();
      final next = state.copyWith(selectedKeys: {'G'});
      expect(next.isFiltering, isTrue);
    });

    test('isFiltering becomes true when a type is added', () {
      const state = SongFilterState();
      final next = state.copyWith(selectedTypes: {SongType.worship});
      expect(next.isFiltering, isTrue);
    });

    test('isFiltering becomes true when a theme is added', () {
      const state = SongFilterState();
      final next = state.copyWith(selectedThemes: {'Grace'});
      expect(next.isFiltering, isTrue);
    });

    test('isFiltering becomes true when BPM range deviates from default', () {
      const state = SongFilterState();
      final next = state.copyWith(bpmRange: const RangeValues(60, 150));
      expect(next.isFiltering, isTrue);
    });

    test('isFiltering becomes true when showFavoritesOnly is true', () {
      const state = SongFilterState();
      final next = state.copyWith(showFavoritesOnly: true);
      expect(next.isFiltering, isTrue);
    });

    test('isFiltering returns to false after resetAll', () {
      final container = _makeContainer();
      addTearDown(container.dispose);
      final notifier = container.read(songFilterProvider.notifier);

      notifier.toggleKey('G');
      expect(container.read(songFilterProvider).isFiltering, isTrue);

      notifier.resetAll();
      expect(container.read(songFilterProvider).isFiltering, isFalse);
    });
  });

  // =========================================================================
  group('SongFilterNotifier mutations', () {
    late ProviderContainer container;

    setUp(() {
      container = _makeContainer();
    });
    tearDown(() => container.dispose());

    // -------------------------------------------------------------------------
    group('toggleKey', () {
      test('adds a key when not present', () {
        container.read(songFilterProvider.notifier).toggleKey('G');
        expect(
          container.read(songFilterProvider).selectedKeys,
          contains('G'),
        );
      });

      test('removes a key when already present', () {
        final notifier = container.read(songFilterProvider.notifier);
        notifier.toggleKey('G');
        notifier.toggleKey('G');
        expect(
          container.read(songFilterProvider).selectedKeys,
          isNot(contains('G')),
        );
      });

      test('can hold multiple keys simultaneously', () {
        final notifier = container.read(songFilterProvider.notifier);
        notifier.toggleKey('G');
        notifier.toggleKey('Am');
        expect(
          container.read(songFilterProvider).selectedKeys,
          containsAll(['G', 'Am']),
        );
      });

      test('clearKeyFilter empties selectedKeys', () {
        final notifier = container.read(songFilterProvider.notifier);
        notifier.toggleKey('G');
        notifier.toggleKey('C');
        notifier.clearKeyFilter();
        expect(
          container.read(songFilterProvider).selectedKeys,
          isEmpty,
        );
      });
    });

    // -------------------------------------------------------------------------
    group('toggleType', () {
      test('adds a type when not present', () {
        container.read(songFilterProvider.notifier).toggleType(SongType.hymn);
        expect(
          container.read(songFilterProvider).selectedTypes,
          contains(SongType.hymn),
        );
      });

      test('removes a type when already present', () {
        final notifier = container.read(songFilterProvider.notifier);
        notifier.toggleType(SongType.hymn);
        notifier.toggleType(SongType.hymn);
        expect(
          container.read(songFilterProvider).selectedTypes,
          isNot(contains(SongType.hymn)),
        );
      });
    });

    // -------------------------------------------------------------------------
    group('toggleTheme', () {
      test('adds a theme when not present', () {
        container.read(songFilterProvider.notifier).toggleTheme('Grace');
        expect(
          container.read(songFilterProvider).selectedThemes,
          contains('Grace'),
        );
      });

      test('removes a theme when already present', () {
        final notifier = container.read(songFilterProvider.notifier);
        notifier.toggleTheme('Grace');
        notifier.toggleTheme('Grace');
        expect(
          container.read(songFilterProvider).selectedThemes,
          isNot(contains('Grace')),
        );
      });
    });

    // -------------------------------------------------------------------------
    group('setBpmRange', () {
      test('updates bpmRange and sets isFiltering', () {
        container
            .read(songFilterProvider.notifier)
            .setBpmRange(const RangeValues(80, 160));
        final state = container.read(songFilterProvider);
        expect(state.bpmRange, const RangeValues(80, 160));
        expect(state.isFiltering, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    group('setSortOption', () {
      test('changes sortOption without affecting isFiltering', () {
        container
            .read(songFilterProvider.notifier)
            .setSortOption(SongSortOption.titleAz);
        final state = container.read(songFilterProvider);
        expect(state.sortOption, SongSortOption.titleAz);
        // Sort option alone does not set isFiltering
        expect(state.isFiltering, isFalse);
      });
    });

    // -------------------------------------------------------------------------
    group('toggleFavoritesFilter', () {
      test('flips showFavoritesOnly from false to true', () {
        container.read(songFilterProvider.notifier).toggleFavoritesFilter();
        expect(
          container.read(songFilterProvider).showFavoritesOnly,
          isTrue,
        );
      });

      test('flips showFavoritesOnly back to false on second call', () {
        final notifier = container.read(songFilterProvider.notifier);
        notifier.toggleFavoritesFilter();
        notifier.toggleFavoritesFilter();
        expect(
          container.read(songFilterProvider).showFavoritesOnly,
          isFalse,
        );
      });
    });

    // -------------------------------------------------------------------------
    group('applyExclusiveFilter', () {
      test('resets all and sets only the specified type', () {
        final notifier = container.read(songFilterProvider.notifier);
        // Pre-populate some state
        notifier.toggleKey('G');
        notifier.toggleTheme('Grace');

        notifier.applyExclusiveFilter(type: SongType.worship);

        final state = container.read(songFilterProvider);
        expect(state.selectedTypes, {SongType.worship});
        expect(state.selectedKeys, isEmpty);
        expect(state.selectedThemes, isEmpty);
      });

      test('resets all and sets only the specified key', () {
        final notifier = container.read(songFilterProvider.notifier);
        notifier.toggleType(SongType.hymn);

        notifier.applyExclusiveFilter(keyName: 'F#');

        final state = container.read(songFilterProvider);
        expect(state.selectedKeys, {'F#'});
        expect(state.selectedTypes, isEmpty);
      });

      test('resets all and sets favoritesOnly', () {
        final notifier = container.read(songFilterProvider.notifier);
        notifier.toggleKey('G');

        notifier.applyExclusiveFilter(favoritesOnly: true);

        final state = container.read(songFilterProvider);
        expect(state.showFavoritesOnly, isTrue);
        expect(state.selectedKeys, isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    group('setFilters', () {
      test('atomically applies all filter fields', () {
        container.read(songFilterProvider.notifier).setFilters(
              selectedKeys: {'C', 'G'},
              selectedTypes: {SongType.praise},
              selectedThemes: {'Joy'},
              bpmRange: const RangeValues(70, 130),
              sortOption: SongSortOption.titleAz,
              showFavoritesOnly: true,
            );

        final state = container.read(songFilterProvider);
        expect(state.selectedKeys, {'C', 'G'});
        expect(state.selectedTypes, {SongType.praise});
        expect(state.selectedThemes, {'Joy'});
        expect(state.bpmRange, const RangeValues(70, 130));
        expect(state.sortOption, SongSortOption.titleAz);
        expect(state.showFavoritesOnly, isTrue);
        expect(state.isFiltering, isTrue);
      });
    });
  });

  // =========================================================================
  group('filteredSongsProvider', () {
    // Build a list of songs that covers the filter/sort scenarios
    final songG = tSong(
      id: 'song-g',
      title: 'Amazing Grace',
      key: 'G',
      bpm: 72,
      type: SongType.hymn,
      themes: ['Grace', 'Salvation'],
      lyricLines: const [],
      createdAt: DateTime(2024, 6, 1),
    );

    final songAm = tSong(
      id: 'song-am',
      title: 'Build My Life',
      key: 'Am',
      bpm: 95,
      type: SongType.worship,
      themes: ['Devotion'],
      lyricLines: const [],
      createdAt: DateTime(2024, 7, 1),
    );

    final songC = tSong(
      id: 'song-c',
      title: 'Cornerstone',
      key: 'C',
      bpm: 120,
      type: SongType.praise,
      themes: ['Grace', 'Strength'],
      lyricLines: const [],
      createdAt: DateTime(2024, 8, 1),
    );

    final allSongs = [songG, songAm, songC];

    // Helper to build a container with a known song list
    ProviderContainer _containerWithSongs({
      List<Song>? songs,
      AsyncValue<Set<String>>? favIds,
    }) {
      return _makeContainer(
        overrides: [
          personalizedSongListProvider.overrideWithValue(
            AsyncData(songs ?? allSongs),
          ),
          if (favIds != null)
            favoriteSongIdsProvider.overrideWithValue(favIds),
        ],
      );
    }

    // -------------------------------------------------------------------------
    group('loading / error passthrough', () {
      test('returns AsyncLoading when personalizedSongListProvider is loading',
          () {
        final container = _makeContainer(
          overrides: [
            personalizedSongListProvider
                .overrideWithValue(const AsyncLoading()),
          ],
        );
        addTearDown(container.dispose);

        final result = container.read(filteredSongsProvider);
        expect(result, isA<AsyncLoading>());
      });

      test('returns AsyncError when personalizedSongListProvider has error', () {
        final err = Exception('DB error');
        final container = _makeContainer(
          overrides: [
            personalizedSongListProvider.overrideWithValue(
              AsyncError(err, StackTrace.empty),
            ),
          ],
        );
        addTearDown(container.dispose);

        final result = container.read(filteredSongsProvider);
        expect(result, isA<AsyncError>());
      });
    });

    // -------------------------------------------------------------------------
    group('no filters (empty query, default state)', () {
      test('returns all songs sorted by newest (default)', () {
        final container = _containerWithSongs();
        addTearDown(container.dispose);

        final result = container.read(filteredSongsProvider).value!;

        // newest order: songC (Aug) → songAm (Jul) → songG (Jun)
        expect(result.map((s) => s.id), ['song-c', 'song-am', 'song-g']);
      });
    });

    // -------------------------------------------------------------------------
    group('search query', () {
      test('filters by title substring (case-insensitive)', () {
        final container = _containerWithSongs();
        addTearDown(container.dispose);

        _setQuery(container, 'amazing');

        final result = container.read(filteredSongsProvider).value!;
        expect(result, hasLength(1));
        expect(result.first.id, 'song-g');
      });

      test('filters by artist name substring', () {
        // All songs share artist "Bethel Music" via tSong default
        final container = _containerWithSongs();
        addTearDown(container.dispose);

        _setQuery(container, 'bethel');

        final result = container.read(filteredSongsProvider).value!;
        expect(result, hasLength(3));
      });

      test('returns empty list when query matches nothing', () {
        final container = _containerWithSongs();
        addTearDown(container.dispose);

        _setQuery(container, 'zzznomatch');

        final result = container.read(filteredSongsProvider).value!;
        expect(result, isEmpty);
      });

      test('title matches sort above lyric matches', () {
        // songAm title contains 'build'; add a lyric-only song
        final songWithLyric = tSong(
          id: 'song-lyric',
          title: 'Other Song',
          key: 'F',
          lyricLines: [
            tLine(content: 'build my faith on nothing less'),
          ],
        );
        final container = _containerWithSongs(
          songs: [songAm, songWithLyric],
        );
        addTearDown(container.dispose);

        _setQuery(container, 'build');

        final result = container.read(filteredSongsProvider).value!;
        expect(result.first.id, 'song-am'); // title match first
        expect(result.last.id, 'song-lyric'); // lyric match second
      });
    });

    // -------------------------------------------------------------------------
    group('key filter', () {
      test('returns only songs matching the selected key', () {
        final container = _containerWithSongs();
        addTearDown(container.dispose);

        container.read(songFilterProvider.notifier).toggleKey('G');

        final result = container.read(filteredSongsProvider).value!;
        expect(result, hasLength(1));
        expect(result.first.id, 'song-g');
      });

      test('returns songs matching any of multiple selected keys', () {
        final container = _containerWithSongs();
        addTearDown(container.dispose);

        container.read(songFilterProvider.notifier).toggleKey('G');
        container.read(songFilterProvider.notifier).toggleKey('C');

        final result = container.read(filteredSongsProvider).value!;
        expect(result.map((s) => s.id), containsAll(['song-g', 'song-c']));
        expect(result, hasLength(2));
      });
    });

    // -------------------------------------------------------------------------
    group('type filter', () {
      test('returns only songs of the selected type', () {
        final container = _containerWithSongs();
        addTearDown(container.dispose);

        container.read(songFilterProvider.notifier).toggleType(SongType.hymn);

        final result = container.read(filteredSongsProvider).value!;
        expect(result, hasLength(1));
        expect(result.first.id, 'song-g');
      });
    });

    // -------------------------------------------------------------------------
    group('theme filter', () {
      test('returns songs that contain at least one selected theme', () {
        final container = _containerWithSongs();
        addTearDown(container.dispose);

        container.read(songFilterProvider.notifier).toggleTheme('Grace');

        final result = container.read(filteredSongsProvider).value!;
        // songG and songC both have theme 'Grace'
        expect(result.map((s) => s.id), containsAll(['song-g', 'song-c']));
        expect(result, hasLength(2));
      });
    });

    // -------------------------------------------------------------------------
    group('sort options', () {
      test('sorts A-Z by title', () {
        final container = _containerWithSongs();
        addTearDown(container.dispose);

        container
            .read(songFilterProvider.notifier)
            .setSortOption(SongSortOption.titleAz);

        final result = container.read(filteredSongsProvider).value!;
        // Amazing Grace, Build My Life, Cornerstone
        expect(
          result.map((s) => s.id),
          ['song-g', 'song-am', 'song-c'],
        );
      });

      test('sorts newest by createdAt descending', () {
        final container = _containerWithSongs();
        addTearDown(container.dispose);

        container
            .read(songFilterProvider.notifier)
            .setSortOption(SongSortOption.newest);

        final result = container.read(filteredSongsProvider).value!;
        // songC (Aug) → songAm (Jul) → songG (Jun)
        expect(
          result.map((s) => s.id),
          ['song-c', 'song-am', 'song-g'],
        );
      });
    });

    // -------------------------------------------------------------------------
    group('favorites filter via favoriteSongIdsProvider override', () {
      test('shows only favorited songs when showFavoritesOnly is true', () {
        final container = _containerWithSongs(
          favIds: const AsyncData({'song-am'}),
        );
        addTearDown(container.dispose);

        container.read(songFilterProvider.notifier).toggleFavoritesFilter();

        final result = container.read(filteredSongsProvider).value!;
        expect(result, hasLength(1));
        expect(result.first.id, 'song-am');
      });

      test('returns AsyncLoading when favoriteSongIdsProvider is loading', () {
        final container = _makeContainer(
          overrides: [
            personalizedSongListProvider.overrideWithValue(
              AsyncData(allSongs),
            ),
            favoriteSongIdsProvider
                .overrideWithValue(const AsyncLoading()),
          ],
        );
        addTearDown(container.dispose);

        // Turn on favorites filter
        container.read(songFilterProvider.notifier).toggleFavoritesFilter();

        final result = container.read(filteredSongsProvider);
        expect(result, isA<AsyncLoading>());
      });

      test('returns all songs when showFavoritesOnly is false (default)', () {
        final container = _containerWithSongs(
          favIds: const AsyncData({'song-am'}),
        );
        addTearDown(container.dispose);

        // showFavoritesOnly is false by default → no filtering
        final result = container.read(filteredSongsProvider).value!;
        expect(result, hasLength(3));
      });

      test('returns empty list when no song matches the favorite IDs set', () {
        final container = _containerWithSongs(
          favIds: const AsyncData({'non-existent-id'}),
        );
        addTearDown(container.dispose);

        container.read(songFilterProvider.notifier).toggleFavoritesFilter();

        final result = container.read(filteredSongsProvider).value!;
        expect(result, isEmpty);
      });

      // Confirm the favorites feature barrel is never imported — this test
      // file must compile without any import from lib/features/favorites/.
    });

    // -------------------------------------------------------------------------
    group('combined filters and search', () {
      test('applies key filter and search query together', () {
        final container = _containerWithSongs();
        addTearDown(container.dispose);

        // Key = G AND search = 'amazing'
        container.read(songFilterProvider.notifier).toggleKey('G');
        _setQuery(container, 'amazing');

        final result = container.read(filteredSongsProvider).value!;
        expect(result, hasLength(1));
        expect(result.first.id, 'song-g');
      });

      test('no results when search matches but key filter excludes', () {
        final container = _containerWithSongs();
        addTearDown(container.dispose);

        // 'amazing' matches songG (key=G), but filter only selects key=C
        container.read(songFilterProvider.notifier).toggleKey('C');
        _setQuery(container, 'amazing');

        final result = container.read(filteredSongsProvider).value!;
        expect(result, isEmpty);
      });
    });
  });
}
