import 'package:flutter_test/flutter_test.dart';
import 'package:worship_lamal/features/songs/data/models/lyric_line_model.dart';
import 'package:worship_lamal/features/songs/data/models/rhythm_chart_model.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';

// ---------------------------------------------------------------------------
// Minimal raw maps that mirror what Supabase returns
// ---------------------------------------------------------------------------

Map<String, dynamic> _artistMap({String id = 'a1', String name = 'Bethel'}) =>
    {'id': id, 'name': name};

Map<String, dynamic> _songArtistMap(Map<String, dynamic> artistMap) =>
    {'artists': artistMap};

Map<String, dynamic> _lyricLineMap({
  String id = 'l1',
  String content = 'He is Lord',
  int lineNumber = 1,
  String sectionType = 'verse',
  String? chordPro = '[G]He is [D]Lord',
}) => {
      'id': id,
      'content': content,
      'line_number': lineNumber,
      'section_type': sectionType,
      'content_chord_pro': chordPro,
    };

Map<String, dynamic> _rhythmChartMap({
  String id = 'rc1',
  String songId = 'song-1',
  String sectionType = 'verse',
  int sortOrder = 0,
  String content = '1 | 4 | 5 |',
}) => {
      'id': id,
      'song_id': songId,
      'section_type': sectionType,
      'sort_order': sortOrder,
      'content': content,
    };

const Object _absent = Object();

Map<String, dynamic> _fullSongMap({
  String id = 'song-1',
  String title = 'Amazing Grace',
  String? key = 'G',
  int? bpm = 72,
  String? type = 'worship',
  Object? themes = _absent,
  String? createdAt = '2024-01-01T00:00:00.000Z',
  Object? songArtists = _absent,
  Object? lyricLines = _absent,
  Object? rhythmCharts = _absent,
}) => {
      'id': id,
      'title': title,
      'key': key,
      'bpm': bpm,
      'type': type,
      'themes':
          identical(themes, _absent) ? ['Grace'] : themes,
      'created_at': createdAt,
      'song_artists':
          identical(songArtists, _absent)
              ? [_songArtistMap(_artistMap())]
              : songArtists,
      'lyric_lines':
          identical(lyricLines, _absent) ? [_lyricLineMap()] : lyricLines,
      'rhythm_charts':
          identical(rhythmCharts, _absent) ? <dynamic>[] : rhythmCharts,
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('SongType.fromString', () {
    test('maps "worship" (case-insensitive) to SongType.worship', () {
      expect(SongType.fromString('worship'), SongType.worship);
      expect(SongType.fromString('Worship'), SongType.worship);
      expect(SongType.fromString('WORSHIP'), SongType.worship);
    });

    test('maps "praise" to SongType.praise', () {
      expect(SongType.fromString('praise'), SongType.praise);
    });

    test('maps "hymn" to SongType.hymn', () {
      expect(SongType.fromString('hymn'), SongType.hymn);
    });

    test('maps null to SongType.other', () {
      expect(SongType.fromString(null), SongType.other);
    });

    test('maps unknown string to SongType.other', () {
      expect(SongType.fromString('gospel'), SongType.other);
    });

    test('maps empty string to SongType.other', () {
      expect(SongType.fromString(''), SongType.other);
    });

    test('trims whitespace before matching', () {
      expect(SongType.fromString(' praise '), SongType.praise);
    });
  });

  // -------------------------------------------------------------------------
  group('Song.fromMap — full/happy-path', () {
    test('parses all scalar fields correctly', () {
      final song = Song.fromMap(_fullSongMap());

      expect(song.id, 'song-1');
      expect(song.title, 'Amazing Grace');
      expect(song.key, 'G');
      expect(song.bpm, 72);
      expect(song.type, SongType.worship);
      expect(song.themes, ['Grace']);
      expect(song.createdAt, DateTime.parse('2024-01-01T00:00:00.000Z'));
    });

    test('parses nested song_artists → artists', () {
      final song = Song.fromMap(_fullSongMap());

      expect(song.artists, hasLength(1));
      expect(song.artists.first.id, 'a1');
      expect(song.artists.first.name, 'Bethel');
    });

    test('parses nested lyric_lines', () {
      final song = Song.fromMap(_fullSongMap());

      expect(song.lyricLines, hasLength(1));
      final line = song.lyricLines.first;
      expect(line.id, 'l1');
      expect(line.content, 'He is Lord');
      expect(line.lineNumber, 1);
      expect(line.sectionType, 'verse');
      expect(line.contentChordPro, '[G]He is [D]Lord');
    });

    test('parses nested rhythm_charts', () {
      final map = _fullSongMap(
        rhythmCharts: [_rhythmChartMap()],
      );
      final song = Song.fromMap(map);

      expect(song.rhythmCharts, hasLength(1));
      final chart = song.rhythmCharts.first;
      expect(chart.id, 'rc1');
      expect(chart.sectionType, 'verse');
      expect(chart.sortOrder, 0);
      expect(chart.content, '1 | 4 | 5 |');
    });

    test('multiple artists are all parsed', () {
      final map = _fullSongMap(songArtists: [
        _songArtistMap(_artistMap(id: 'a1', name: 'Bethel')),
        _songArtistMap(_artistMap(id: 'a2', name: 'Hillsong')),
      ]);
      final song = Song.fromMap(map);

      expect(song.artists, hasLength(2));
      expect(song.artists[1].name, 'Hillsong');
    });
  });

  // -------------------------------------------------------------------------
  group('Song.fromMap — null/missing-field safety', () {
    test('null key → song.key is null', () {
      final song = Song.fromMap(_fullSongMap(key: null));
      expect(song.key, isNull);
    });

    test('null bpm → song.bpm is null', () {
      final song = Song.fromMap(_fullSongMap(bpm: null));
      expect(song.bpm, isNull);
    });

    test('null type → SongType.other', () {
      final song = Song.fromMap(_fullSongMap(type: null));
      expect(song.type, SongType.other);
    });

    test('null themes → empty list', () {
      final song = Song.fromMap(_fullSongMap(themes: null));
      expect(song.themes, isEmpty);
    });

    test('null created_at → song.createdAt is null', () {
      final song = Song.fromMap(_fullSongMap(createdAt: null));
      expect(song.createdAt, isNull);
    });

    test('null song_artists → empty artists list', () {
      final song = Song.fromMap(_fullSongMap(songArtists: null));
      expect(song.artists, isEmpty);
    });

    test('null lyric_lines → empty lyricLines list', () {
      final song = Song.fromMap(_fullSongMap(lyricLines: null));
      expect(song.lyricLines, isEmpty);
    });

    test('null rhythm_charts → empty rhythmCharts list', () {
      final song = Song.fromMap(_fullSongMap(rhythmCharts: null));
      expect(song.rhythmCharts, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  group('Song.sections — section grouping', () {
    LyricLine line(String section, int n) => LyricLine(
          id: 'l$n',
          content: 'line $n',
          lineNumber: n,
          sectionType: section,
        );

    test('returns empty list when lyricLines is empty', () {
      final song = Song(
        id: 's1',
        title: 'Test',
        artists: const [],
        lyricLines: const [],
      );
      expect(song.sections, isEmpty);
    });

    test('groups lines by sectionType', () {
      final song = Song(
        id: 's1',
        title: 'Test',
        artists: const [],
        lyricLines: [
          line('verse', 1),
          line('verse', 2),
          line('chorus', 3),
        ],
      );
      final sections = song.sections;

      expect(sections, hasLength(2));
      expect(sections[0].sectionType, 'verse');
      expect(sections[0].lines, hasLength(2));
      expect(sections[1].sectionType, 'chorus');
      expect(sections[1].lines, hasLength(1));
    });

    test('section title is capitalized', () {
      final song = Song(
        id: 's1',
        title: 'Test',
        artists: const [],
        lyricLines: [line('bridge', 1)],
      );
      expect(song.sections.first.title, 'Bridge');
    });

    test('lines within a section are sorted by lineNumber', () {
      // Provide lines out of order
      final song = Song(
        id: 's1',
        title: 'Test',
        artists: const [],
        lyricLines: [
          line('verse', 3),
          line('verse', 1),
          line('verse', 2),
        ],
      );
      final verses = song.sections.first;
      expect(verses.lines.map((l) => l.lineNumber).toList(), [1, 2, 3]);
    });

    test('null sectionType lines are grouped under "Misc"', () {
      final song = Song(
        id: 's1',
        title: 'Test',
        artists: const [],
        lyricLines: [
          LyricLine(id: 'x', content: 'misc', lineNumber: 1),
        ],
      );
      expect(song.sections.first.sectionType, 'Misc');
      expect(song.sections.first.title, 'Misc');
    });

    test('preserves insertion order of distinct section types', () {
      final song = Song(
        id: 's1',
        title: 'Test',
        artists: const [],
        lyricLines: [
          line('verse', 1),
          line('chorus', 2),
          line('bridge', 3),
        ],
      );
      final types = song.sections.map((s) => s.sectionType).toList();
      expect(types, ['verse', 'chorus', 'bridge']);
    });
  });

  // -------------------------------------------------------------------------
  group('Artist.fromMap', () {
    test('parses id and name', () {
      final artist = Artist.fromMap({'id': 'a1', 'name': 'Elevation'});
      expect(artist.id, 'a1');
      expect(artist.name, 'Elevation');
    });

    test('null name falls back to "Unknown Artist"', () {
      final artist = Artist.fromMap({'id': 'a1', 'name': null});
      expect(artist.name, 'Unknown Artist');
    });
  });

  // -------------------------------------------------------------------------
  group('SongUi.artistNames extension', () {
    test('returns comma-joined artist names', () {
      final song = Song(
        id: 's1',
        title: 'T',
        artists: [
          Artist(id: 'a1', name: 'Bethel'),
          Artist(id: 'a2', name: 'Hillsong'),
        ],
        lyricLines: const [],
      );
      expect(song.artistNames, 'Bethel, Hillsong');
    });

    test('returns "Unknown" when artists list is empty', () {
      final song = Song(
        id: 's1',
        title: 'T',
        artists: const [],
        lyricLines: const [],
      );
      expect(song.artistNames, 'Unknown');
    });
  });

  // -------------------------------------------------------------------------
  group('LyricLine.fromMap', () {
    test('parses all fields', () {
      final line = LyricLine.fromMap(_lyricLineMap());
      expect(line.id, 'l1');
      expect(line.content, 'He is Lord');
      expect(line.lineNumber, 1);
      expect(line.sectionType, 'verse');
      expect(line.contentChordPro, '[G]He is [D]Lord');
    });

    test('null id falls back to empty string', () {
      final line = LyricLine.fromMap({
        'id': null,
        'content': 'x',
        'line_number': 1,
        'section_type': 'verse',
        'content_chord_pro': null,
      });
      expect(line.id, '');
    });

    test('null content falls back to empty string', () {
      final line = LyricLine.fromMap({
        'id': 'x',
        'content': null,
        'line_number': 2,
        'section_type': null,
        'content_chord_pro': null,
      });
      expect(line.content, '');
    });

    test('null line_number falls back to 0', () {
      final line = LyricLine.fromMap({
        'id': 'x',
        'content': 'y',
        'line_number': null,
        'section_type': null,
        'content_chord_pro': null,
      });
      expect(line.lineNumber, 0);
    });

    test('null section_type → null sectionType', () {
      final line = LyricLine.fromMap({
        'id': 'x',
        'content': 'y',
        'line_number': 1,
        'section_type': null,
        'content_chord_pro': null,
      });
      expect(line.sectionType, isNull);
    });

    test('null content_chord_pro → null contentChordPro', () {
      final line = LyricLine.fromMap({
        'id': 'x',
        'content': 'y',
        'line_number': 1,
        'section_type': 'verse',
        'content_chord_pro': null,
      });
      expect(line.contentChordPro, isNull);
    });
  });

  // -------------------------------------------------------------------------
  group('RhythmChart.fromJson', () {
    test('parses all fields', () {
      final chart = RhythmChart.fromJson(_rhythmChartMap());
      expect(chart.id, 'rc1');
      expect(chart.songId, 'song-1');
      expect(chart.sectionType, 'verse');
      expect(chart.sortOrder, 0);
      expect(chart.content, '1 | 4 | 5 |');
    });
  });
}
