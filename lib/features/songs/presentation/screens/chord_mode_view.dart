import 'package:flutter/material.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/presentation/widgets/chord_line_renderer.dart';
import '../widgets/song_header.dart';

class ChordModeView extends StatelessWidget {
  final Song song;
  final String displayKey;
  final bool isTransposed;

  const ChordModeView({
    super.key,
    required this.song,
    required this.displayKey,
    required this.isTransposed,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Split sections down the middle for the 2 columns
    final midPoint = (song.sections.length / 2).ceil();
    final leftColumn = song.sections.take(midPoint).toList();
    final rightColumn = song.sections.skip(midPoint).toList();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          children: [
            // ----------------------------------------------------
            // A. META-HEADER & DIVIDER
            // ----------------------------------------------------
            Padding(
              // Reduced horizontal padding for mobile
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left Side: Title & Artist
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              song.title,
                              style: const TextStyle(
                                fontSize:
                                    18, // Reduced from 26 to fit mobile better
                                fontWeight: FontWeight.w900,
                                color: Colors.black,
                                letterSpacing: -0.5,
                                height: 1.1,
                              ),
                            ),
                            if (song.artistNames.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2.0),
                                child: Text(
                                  song.artistNames,
                                  style: const TextStyle(
                                    fontSize: 13, // Reduced from 15
                                    fontStyle: FontStyle.italic,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8), // Buffer between title and key
                      // Right Side: Key & BPM
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            "Key of $displayKey",
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          if (song.bpm != null)
                            Text(
                              "${song.bpm} BPM",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black87,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Divider(
                    color: Colors.black,
                    thickness: 1.5,
                    height: 1.5,
                  ),
                ],
              ),
            ),

            // ----------------------------------------------------
            // B. FORCED 2-COLUMN SHEET MUSIC BODY
            // ----------------------------------------------------
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                thickness: 4,
                radius: const Radius.circular(2),
                child: SingleChildScrollView(
                  // Minimal padding to maximize 2-column space on mobile
                  padding: EdgeInsets.fromLTRB(12, 12, 12, 32 + bottomPadding),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // LEFT COLUMN
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: leftColumn
                              .map((s) => _buildCompactSection(context, s))
                              .toList(),
                        ),
                      ),
                      // THE GUTTER: Reduced from 32 to 12 for mobile screens
                      const SizedBox(width: 12),
                      // RIGHT COLUMN
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: rightColumn
                              .map((s) => _buildCompactSection(context, s))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSection(BuildContext context, SectionBlock section) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16.0,
      ), // Slightly tighter section spacing
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              section.title,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                fontSize: 13, // Reduced from 15
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          ...section.lines.map((line) {
            final contentToRender = line.contentChordPro ?? line.content;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: ChordLineRenderer(
                line: contentToRender,
                targetKey: displayKey,
                // CRITICAL FOR MOBILE 2-COLUMN: Smaller fonts prevent wrapping
                chordStyle: const TextStyle(
                  fontSize: 11.5,
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                ),
                lyricStyle: const TextStyle(
                  fontSize: 10.5,
                  color: Colors.black87,
                  height: 1.15, // Tighter line height
                  letterSpacing: -0.2, // Very slight squeeze to fit more text
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
