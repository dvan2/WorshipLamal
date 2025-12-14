class Song {
  final String id;
  final String title;
  final String artist;
  final String lyrics;

  Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.lyrics,
  });

  // Converts Supabase json to Song Object
  factory Song.fromMap(Map<String, dynamic> map) {
    var linesData = map['lyric_lines'] as List<dynamic>? ?? [];

    linesData.sort(
      (a, b) => (a['line_number'] as int).compareTo(b['line_number'] as int),
    );

    String fullLyrics = linesData
        .map((line) => line['content'] as String)
        .join('\n');

    return Song(
      id: map['id'].toString(),
      title: map['title'] ?? 'No Title',
      artist: map['artist'] ?? 'Unknown Artist',
      lyrics: fullLyrics.isEmpty ? "No lyrics available." : fullLyrics,
    );
  }
}
