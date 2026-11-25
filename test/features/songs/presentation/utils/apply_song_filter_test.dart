import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worship_lamal/features/songs/data/models/lyric_line_model.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/data/models/song_sort_option.dart';
import 'package:worship_lamal/features/songs/presentation/providers/song_filter_provider.dart';
import 'package:worship_lamal/features/songs/presentation/utils/apply_song_filter.dart';

import '../../../../helpers/fixtures.dart';

void main() {
  group('applyFilterAndSort', () {
    late Song songGrace;
    late Song songPraise;
    late Song songHymn;
    late List<Song> allTestSongs;

    setUp(() {
      songGrace = tSong(
        id: 'song-1',
        title: 'Amazing Grace',
        key: 'G',
        bpm: 72,
        type: SongType.worship,
        themes: const ['Grace', 'Cross'],
        artists: [Artist(id: 'a1', name: 'John Newton')],
        createdAt: DateTime(2023, 1, 1),
        lyricLines: [
          tLine(n: 1, content: 'Amazing grace how sweet the sound'),
          tLine(n: 2, content: 'That saved a wretch like me'),
        ],
      );

      songPraise = tSong(
        id: 'song-2',
        title: 'Lion and the Lamb',
        key: 'C',
        bpm: 130,
        type: SongType.praise,
        themes: const ['Power', 'Victory'],
        artists: [Artist(id: 'a2', name: 'Bethel Music')],
        createdAt: DateTime(2024, 6, 1),
        lyricLines: [
          tLine(n: 1, content: 'He is the Lion of Judah'),
          tLine(n: 2, content: 'Chain breaker and deliverer'),
        ],
      );

      songHymn = tSong(
        id: 'song-3',
        title: 'Be Thou My Vision',
        key: 'D',
        bpm: null, // Test null BPM edge case
        type: SongType.hymn,
        themes: const ['Devotion'],
        artists: [Artist(id: 'a3', name: 'Traditional')],
        createdAt: DateTime(2022, 1, 1),
        lyricLines: [
          tLine(n: 1, content: 'Be Thou my vision O Lord of my heart'),
          tLine(n: 2, content: 'Naught be all else to me save that Thou art'),
        ],
      );

      allTestSongs = [songGrace, songPraise, songHymn];
    });

    group('Key filtering', () {
      test('filters by single selected key', () {
        final result = applyFilterAndSort(
          allSongs: allTestSongs,
          query: '',
          filters: const SongFilterState(selectedKeys: {'G'}),
          favoriteIds: {},
        );
        expect(result.length, 1);
        expect(result.first.id, 'song-1');
      });

      test('filters by multiple selected keys', () {
        final result = applyFilterAndSort(
          allSongs: allTestSongs,
          query: '',
          filters: const SongFilterState(selectedKeys: {'C', 'D'}),
          favoriteIds: {},
        );
        expect(result.length, 2);
        expect(result.map((s) => s.id).toSet(), {'song-2', 'song-3'});
      });

      test('empty selectedKeys passes all songs through', () {
        final result = applyFilterAndSort(
          allSongs: allTestSongs,
          query: '',
          filters: const SongFilterState(selectedKeys: {}),
          favoriteIds: {},
        );
        expect(result.length, 3);
      });
    });

    group('BPM filtering', () {
      test('excludes songs outside the bpm range', () {
        final result = applyFilterAndSort(
          allSongs: allTestSongs,
          query: '',
          filters: const SongFilterState(
            bpmRange: RangeValues(60, 90),
          ),
          favoriteIds: {},
        );
        // songGrace has bpm 72 (in range)
        // songPraise has bpm 130 (out of range)
        // songHymn has null bpm (null bpm passes through because song.bpm != null condition)
        expect(result.map((s) => s.id), contains('song-1'));
        expect(result.map((s) => s.id), contains('song-3'));
        expect(result.map((s) => s.id), isNot(contains('song-2')));
      });

      test('filters out songs below min bpm', () {
        final result = applyFilterAndSort(
          allSongs: allTestSongs,
          query: '',
          filters: const SongFilterState(
            bpmRange: RangeValues(100, 150),
          ),
          favoriteIds: {},
        );
        expect(result.map((s) => s.id), contains('song-2'));
        expect(result.map((s) => s.id), isNot(contains('song-1')));
      });
    });

    group('Song type filtering', () {
      test('filters to specific SongType', () {
        final result = applyFilterAndSort(
          allSongs: allTestSongs,
          query: '',
          filters: const SongFilterState(selectedTypes: {SongType.praise}),
          favoriteIds: {},
        );
        expect(result.length, 1);
        expect(result.first.id, 'song-2');
      });

      test('filters with multiple SongTypes selected', () {
        final result = applyFilterAndSort(
          allSongs: allTestSongs,
          query: '',
          filters: const SongFilterState(
            selectedTypes: {SongType.worship, SongType.hymn},
          ),
          favoriteIds: {},
        );
        expect(result.length, 2);
        expect(result.map((s) => s.id).toSet(), {'song-1', 'song-3'});
      });
    });

    group('Theme filtering', () {
      test('matches songs that contain at least one of the selected themes', () {
        final result = applyFilterAndSort(
          allSongs: allTestSongs,
          query: '',
          filters: const SongFilterState(selectedThemes: {'Cross'}),
          favoriteIds: {},
        );
        expect(result.length, 1);
        expect(result.first.id, 'song-1');
      });

      test('returns empty when no songs match the selected theme', () {
        final result = applyFilterAndSort(
          allSongs: allTestSongs,
          query: '',
          filters: const SongFilterState(selectedThemes: {'NonExistent'}),
          favoriteIds: {},
        );
        expect(result, isEmpty);
      });
    });

    group('Favorites filtering', () {
      test('returns only songs present in favoriteIds when showFavoritesOnly is true', () {
        final result = applyFilterAndSort(
          allSongs: allTestSongs,
          query: '',
          filters: const SongFilterState(showFavoritesOnly: true),
          favoriteIds: {'song-1', 'song-3'},
        );
        expect(result.length, 2);
        expect(result.map((s) => s.id).toSet(), {'song-1', 'song-3'});
      });

      test('ignores favoriteIds when showFavoritesOnly is false', () {
        final result = applyFilterAndSort(
          allSongs: allTestSongs,
          query: '',
          filters: const SongFilterState(showFavoritesOnly: false),
          favoriteIds: {'song-1'},
        );
        expect(result.length, 3);
      });
    });

    group('Search query matching and title priority', () {
      test('matches title with case insensitivity and sets isTitleMatch to true', () {
        final result = applyFilterAndSort(
          allSongs: allTestSongs,
          query: 'AMAZING',
          filters: const SongFilterState(),
          favoriteIds: {},
        );
        expect(result.length, 1);
        expect(result.first.id, 'song-1');
        expect(result.first.isTitleMatch, isTrue);
        expect(result.first.searchSnippet, isNull);
      });

      test('matches artist name as title match', () {
        final result = applyFilterAndSort(
          allSongs: allTestSongs,
          query: 'Bethel',
          filters: const SongFilterState(),
          favoriteIds: {},
        );
        expect(result.length, 1);
        expect(result.first.id, 'song-2');
        expect(result.first.isTitleMatch, isTrue);
      });

      test('matches lyrics when title does not match, populating searchSnippet', () {
        final result = applyFilterAndSort(
          allSongs: allTestSongs,
          query: 'chain breaker',
          filters: const SongFilterState(),
          favoriteIds: {},
        );
        expect(result.length, 1);
        expect(result.first.id, 'song-2');
        expect(result.first.isTitleMatch, isFalse);
        expect(result.first.searchSnippet, 'Chain breaker and deliverer');
      });

      test('returns empty when neither title, artist, nor lyrics match query', () {
        final result = applyFilterAndSort(
          allSongs: allTestSongs,
          query: 'unknown phrase xyz',
          filters: const SongFilterState(),
          favoriteIds: {},
        );
        expect(result, isEmpty);
      });

      test('prioritizes title match above lyric match during active search', () {
        // Create song with "Grace" in title vs song with "grace" only in lyric
        final songLyricOnly = tSong(
          id: 'song-lyric',
          title: 'Everlasting God',
          lyricLines: [tLine(n: 1, content: 'Filled with grace and love')],
        );
        final list = [songLyricOnly, songGrace];

        final result = applyFilterAndSort(
          allSongs: list,
          query: 'grace',
          filters: const SongFilterState(sortOption: SongSortOption.titleAz),
          favoriteIds: {},
        );

        // Even though 'E' comes before 'A' in titleAz, title match takes priority!
        expect(result.first.id, songGrace.id);
        expect(result.first.isTitleMatch, isTrue);
        expect(result.last.id, songLyricOnly.id);
        expect(result.last.isTitleMatch, isFalse);
      });
    });

    group('Sorting options', () {
      test('sorts by titleAz alphabetically', () {
        final result = applyFilterAndSort(
          allSongs: allTestSongs,
          query: '',
          filters: const SongFilterState(sortOption: SongSortOption.titleAz),
          favoriteIds: {},
        );
        expect(result.map((s) => s.title).toList(), [
          'Amazing Grace',
          'Be Thou My Vision',
          'Lion and the Lamb',
        ]);
      });

      test('sorts by newest based on createdAt timestamp', () {
        final result = applyFilterAndSort(
          allSongs: allTestSongs,
          query: '',
          filters: const SongFilterState(sortOption: SongSortOption.newest),
          favoriteIds: {},
        );
        // songPraise (2024-06-01), songGrace (2023-01-01), songHymn (2022-01-01)
        expect(result.map((s) => s.id).toList(), ['song-2', 'song-1', 'song-3']);
      });

      test('sorts newest with null createdAt placed at the end', () {
        final songNoDate = tSong(id: 'song-nodate', title: 'No Date', createdAt: null);
        final result = applyFilterAndSort(
          allSongs: [songNoDate, songGrace],
          query: '',
          filters: const SongFilterState(sortOption: SongSortOption.newest),
          favoriteIds: {},
        );
        expect(result.first.id, songGrace.id);
        expect(result.last.id, songNoDate.id);
      });

      test('sorts by recentlyViewed using historyMap', () {
        final historyMap = {
          'song-3': DateTime(2024, 10, 10), // Most recent
          'song-1': DateTime(2024, 9, 1),   // Older
          // song-2 not in history
        };

        final result = applyFilterAndSort(
          allSongs: allTestSongs,
          query: '',
          filters: const SongFilterState(sortOption: SongSortOption.recentlyViewed),
          favoriteIds: {},
          historyMap: historyMap,
        );

        expect(result.map((s) => s.id).toList(), [
          'song-3',
          'song-1',
          'song-2', // No history, falls to the end
        ]);
      });

      test('recentlyViewed falls back to titleAz when historyMap is null or empty', () {
        final result = applyFilterAndSort(
          allSongs: allTestSongs,
          query: '',
          filters: const SongFilterState(sortOption: SongSortOption.recentlyViewed),
          favoriteIds: {},
          historyMap: null,
        );
        expect(result.map((s) => s.title).toList(), [
          'Amazing Grace',
          'Be Thou My Vision',
          'Lion and the Lamb',
        ]);
      });
    });
  });
}
