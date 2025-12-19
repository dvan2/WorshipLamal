import 'lyric_line_model.dart';

class Song {
  final String id;
  final String title;
  final String artist;
  final List<LyricLine> lyricLines;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.lyricLines,
  });

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as String,
      title: map['title'] as String,
      artist: map['artist'] as String? ?? 'Unknown Artist',
      lyricLines: (map['lyric_lines'] as List<dynamic>? ?? [])
          .map((line) => LyricLine.fromMap(line))
          .toList(),
    );
  }
}
