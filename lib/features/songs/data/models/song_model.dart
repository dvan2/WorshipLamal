import 'lyric_line_model.dart';

class Song {
  final String id;
  final String title;
  final List<Artist> artists;
  final List<LyricLine> lyricLines;
  final String? key;
  final int? bpm;
  final DateTime? createdAt;

  Song({
    required this.id,
    required this.title,
    required this.artists,
    required this.lyricLines,
    this.createdAt,
    this.key,
    this.bpm,
  });

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as String,
      title: map['title'] as String,
      artists: (map['song_artists'] as List)
          .map((sa) => Artist.fromMap(sa['artists']))
          .toList(),
      lyricLines: (map['lyric_lines'] as List<dynamic>? ?? [])
          .map((line) => LyricLine.fromMap(line))
          .toList(),
      key: map['key'] as String?,
      bpm: map['bpm'] as int?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
    );
  }
}

extension SongUi on Song {
  String get artistNames {
    if (artists.isEmpty) return 'Unknown artist';
    return artists.map((a) => a.name).join(', ');
  }
}

class Artist {
  final String id;
  final String name;

  Artist({required this.id, required this.name});

  factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(id: map['id'] as String, name: map['name'] as String);
  }
}
