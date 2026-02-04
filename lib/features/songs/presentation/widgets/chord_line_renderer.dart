import 'package:flutter/material.dart';
import 'package:worship_lamal/core/utils/nashville_helper.dart';
import '../../../../core/utils/chord_parser.dart';

class ChordLineRenderer extends StatelessWidget {
  final String line;
  final TextStyle lyricStyle;
  final TextStyle chordStyle;
  final String? targetKey;

  const ChordLineRenderer({
    super.key,
    required this.line,
    this.lyricStyle = const TextStyle(
      fontSize: 16,
      color: Colors.black,
      height: 1.5,
    ),
    this.chordStyle = const TextStyle(
      fontSize: 14,
      color: Colors.deepOrange,
      fontWeight: FontWeight.bold,
    ),
    this.targetKey,
  });

  @override
  Widget build(BuildContext context) {
    final rawChunks = ChordParser.parse(line);

    // 1. Group chunks into "Words" to prevent splitting in the middle of a word
    final words = _groupChunksIntoWords(rawChunks);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      runSpacing: 8.0, // Add vertical spacing between wrapped lines
      children: words.map((wordChunks) {
        // 2. Each "Word" is a Row, forcing its parts to stay together
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: wordChunks.map((chunk) {
            return _buildChunkColumn(chunk);
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget _buildChunkColumn(ChordChunk chunk) {
    String displayChord = chunk.chord ?? "";
    if (targetKey != null && displayChord.isNotEmpty) {
      displayChord = NashvilleHelper.translate(displayChord, targetKey!);
    }

    // CALCULATE: How tall is your chord text?
    // If your chord fontSize is 11.0, use that.
    const double chordLineHeight = 11.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (displayChord.isNotEmpty)
          Text(displayChord, style: chordStyle)
        else
          // FIX: Instead of shrinking to nothing, reserve the height
          // effectively forcing an "invisible chord" line.
          const SizedBox(height: chordLineHeight),

        Text(chunk.text, style: lyricStyle.copyWith(letterSpacing: 0)),
      ],
    );
  }

  /// Groups chunks so that "Ma" and "whna" become one unit,
  /// but "Keima " (ending in space) starts a new unit.
  List<List<ChordChunk>> _groupChunksIntoWords(List<ChordChunk> rawChunks) {
    final List<List<ChordChunk>> words = [];
    List<ChordChunk> currentWord = [];

    for (final chunk in rawChunks) {
      // Split chunk text by space to properly identify word boundaries
      // e.g. If a chunk is "Hello World", we must split it so it can wrap.
      final parts = _splitKeepDelimiter(chunk.text, ' ');

      for (int i = 0; i < parts.length; i++) {
        final partText = parts[i];
        // Only the first part gets the chord (e.g. [C]Hello World -> C is on Hello)
        final partChord = (i == 0) ? chunk.chord : null;

        final atom = ChordChunk(text: partText, chord: partChord);
        currentWord.add(atom);

        // If this part ends with a space, it closes the current word.
        if (partText.endsWith(' ') || partText.endsWith('\n')) {
          words.add(currentWord);
          currentWord = [];
        }
      }
    }
    // Add any remaining fragments
    if (currentWord.isNotEmpty) {
      words.add(currentWord);
    }
    return words;
  }

  /// Splits text but keeps the delimiter attached to the end of the word
  /// "Hello World" -> ["Hello ", "World"]
  List<String> _splitKeepDelimiter(String text, String delimiter) {
    List<String> result = [];
    int start = 0;
    while (true) {
      int index = text.indexOf(delimiter, start);
      if (index == -1) {
        if (start < text.length) {
          result.add(text.substring(start));
        }
        break;
      }
      result.add(text.substring(start, index + 1));
      start = index + 1;
    }
    return result;
  }
}
