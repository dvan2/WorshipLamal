import 'package:flutter_test/flutter_test.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';

void main() {
  test('Song.fromMap parses lyric lines correctly', () {
    final song = Song.fromMap({
      'id': '1',
      'title': 'Amazing Grace',
      'artist': 'John Newton',
      'lyric_lines': [
        {'content': 'Amazing grace, how sweet the sound', 'line_number': 1},
      ],
    });

    expect(song.id, '1');
    expect(song.title, 'Amazing Grace');
    expect(song.artist, 'John Newton');
    expect(song.lyricLines.length, 1);
    expect(song.lyricLines.first.content, 'Amazing grace, how sweet the sound');
  });

  test('Song.fromMap handles null lyric_lines safely', () {
    final song = Song.fromMap({
      'id': '1',
      'title': 'No Lyrics Song',
      'artist': null,
      'lyric_lines': null,
    });

    expect(song.lyricLines, isEmpty);
    expect(song.artist, isNotNull);
  });
}
