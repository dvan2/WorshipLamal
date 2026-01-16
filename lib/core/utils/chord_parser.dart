class ChordChunk {
  final String? chord;
  final String text;

  ChordChunk({this.chord, required this.text});
}

class ChordParser {
  static List<ChordChunk> parse(String line) {
    final List<ChordChunk> chunks = [];

    final parts = line.split('[');

    for (int i = 0; i < parts.length; i++) {
      String part = parts[i];
      if (part.isEmpty) continue;

      if (i == 0 && !line.startsWith('[')) {
        // Case: "Amazing [G]..." -> "Amazing " is the first part
        chunks.add(ChordChunk(chord: null, text: part));
      } else {
        // Case: "G]Grace"
        final closeBracketIndex = part.indexOf(']');
        if (closeBracketIndex != -1) {
          final chord = part.substring(0, closeBracketIndex);
          final text = part.substring(closeBracketIndex + 1);
          chunks.add(ChordChunk(chord: chord, text: text));
        } else {
          // Malformed bracket, treat as text
          chunks.add(ChordChunk(chord: null, text: part));
        }
      }
    }

    return chunks;
  }
}
