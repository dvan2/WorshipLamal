import 'package:flutter_test/flutter_test.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';

void main() {
  test('Song.fromMap parses artists and lyric lines correctly', () {
    final song = Song.fromMap({
      'id': '1',
      'title': 'Amazing Grace',
      'song_artists': [
        {
          'artists': {'id': 'artist-1', 'name': 'John Newton'},
        },
      ],
      'lyric_lines': [
        {'content': 'Amazing grace, how sweet the sound', 'line_number': 1},
      ],
    });

    expect(song.id, '1');
    expect(song.title, 'Amazing Grace');

    expect(song.artists.length, 1);
    expect(song.artists.first.name, 'John Newton');

    expect(song.lyricLines.length, 1);
    expect(song.lyricLines.first.content, 'Amazing grace, how sweet the sound');
  });

  test('Song.fromMap handles null artists and lyric_lines safely', () {
    final song = Song.fromMap({
      'id': '1',
      'title': 'No Lyrics Song',
      'song_artists': null,
      'lyric_lines': null,
    });

    expect(song.artists, isEmpty);
    expect(song.lyricLines, isEmpty);
  });

  test('SongUi extension returns correct artist names string', () {
    // Case 1: Multiple Artists
    final songMultiple = Song(
      id: '1',
      title: 'Title',
      lyricLines: [],
      artists: [
        Artist(id: '1', name: 'Bethel'),
        Artist(id: '2', name: 'Elevation'),
      ],
    );
    expect(songMultiple.artistNames, 'Bethel, Elevation');

    // Case 2: Single Artist
    final songSingle = Song(
      id: '1',
      title: 'Title',
      lyricLines: [],
      artists: [Artist(id: '1', name: 'Hillsong')],
    );
    expect(songSingle.artistNames, 'Hillsong');

    // Case 3: No Artists (Edge case in extension)
    final songEmpty = Song(
      id: '1',
      title: 'Title',
      lyricLines: [],
      artists: [],
    );
    expect(songEmpty.artistNames, 'Unknown');
  });
}
