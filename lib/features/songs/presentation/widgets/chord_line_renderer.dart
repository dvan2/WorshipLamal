import 'package:flutter/material.dart';
import 'package:worship_lamal/core/utils/nashville_helper.dart';
import '../../../../core/utils/chord_parser.dart'; // Import your parser

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
    final chunks = ChordParser.parse(line);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end, // Align text to bottom
      children: chunks.map((chunk) {
        String displayChord = chunk.chord ?? "";
        if (targetKey != null && displayChord.isNotEmpty) {
          displayChord = NashvilleHelper.translate(displayChord, targetKey!);
        }
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (displayChord.isNotEmpty)
              Text(
                displayChord, // Render the Translated Note (e.g., "Am")
                style: chordStyle,
              )
            else
              const SizedBox(height: 0),
            Text(chunk.text, style: lyricStyle),
          ],
        );
      }).toList(),
    );
  }
}
