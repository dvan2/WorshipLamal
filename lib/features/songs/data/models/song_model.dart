import 'lyric_line_model.dart';

class Song {
  final String id;
  final String title;
  final List<Artist> artists;
  final List<LyricLine> lyricLines;
  final String? key;
  final int? bpm;
  final DateTime? createdAt;
  final DateTime? lastViewedAt;

  Song({
    required this.id,
    required this.title,
    required this.artists,
    required this.lyricLines,
    this.createdAt,
    this.key,
    this.bpm,
    this.lastViewedAt,
  });

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'] as String,
      title: map['title'] as String,
      artists:
          (map['song_artists'] as List?)?.map((sa) {
            return Artist.fromMap(sa['artists']);
          }).toList() ??
          [],
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

  Song copyWith({
    String? id,
    String? title,
    List<Artist>? artists,
    List<LyricLine>? lyricLines,
    String? key,
    int? bpm,
    DateTime? createdAt,
    DateTime? lastViewedAt,
  }) {
    return Song(
      id: id ?? this.id,
      title: title ?? this.title,
      artists: artists ?? this.artists,
      lyricLines: lyricLines ?? this.lyricLines,
      key: key ?? this.key,
      bpm: bpm ?? this.bpm,
      createdAt: createdAt ?? this.createdAt,
      lastViewedAt: lastViewedAt ?? this.lastViewedAt,
    );
  }

  List<SectionBlock> get sections {
    if (lyricLines.isEmpty) return [];

    final Map<String, List<LyricLine>> order = {};

    for (final line in lyricLines) {
      final key = line.sectionType ?? 'Misc';
      order.putIfAbsent(key, () => []);
      order[key]!.add(line);
    }

    return order.entries.map((entry) {
      final sectionKey = entry.key;
      final items = entry.value
        ..sort((a, b) => (a.lineNumber).compareTo(b.lineNumber));

      return SectionBlock(
        title: _capitalize(sectionKey),
        sectionType: sectionKey,
        lines: items,
      );
    }).toList();
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

extension SongUi on Song {
  String get artistNames {
    if (artists.isEmpty) return 'Unknown';
    return artists.map((a) => a.name).join(', ');
  }
}

class Artist {
  final String id;
  final String name;

  Artist({required this.id, required this.name});

  factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Unknown Artist',
    );
  }
}

class SectionBlock {
  final String title;
  final List<LyricLine> lines;
  final String sectionType;

  SectionBlock({
    required this.title,
    required this.lines,
    required this.sectionType,
  });
}
