import 'package:flutter/material.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';

class SongHeader extends StatelessWidget {
  final Song song;
  final String displayKey;
  final bool isTransposed;

  const SongHeader({
    super.key,
    required this.song,
    required this.displayKey,
    this.isTransposed = false,
  });

  @override
  Widget build(BuildContext context) {
    // Construct metadata string like "Key of G | 68 BPM"
    final List<String> metaParts = [];
    if (displayKey.isNotEmpty) metaParts.add("Key of $displayKey");
    if (song.bpm != null) metaParts.add("${song.bpm} BPM");
    final metaString = metaParts.join(" | ");

    return Container(
      // Removed the colored gradient and border for a clean "paper" look
      width: double.infinity,
      // Removed horizontal padding here (handled by the parent screen)
      // Added vertical padding to give it breathing room from the top
      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ROW 1: Title (Left) and Metadata (Right)
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // TITLE
              Expanded(
                child: Text(
                  song.title,
                  style: const TextStyle(
                    fontSize: 24, // Large and bold
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // METADATA (Key | BPM)
              // Aligned to baseline of title for a sharp look
              if (metaString.isNotEmpty)
                Text(
                  metaString,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    // Highlight color if transposed, otherwise black like reference
                    color: isTransposed ? Colors.deepOrange : Colors.black,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 4),

          // ROW 2: Artist Name
          Text(
            song.artistNames,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500, // Medium weight
              fontStyle:
                  FontStyle.italic, // Italic often looks nice for artists
              color: Colors.grey, // Subtle grey to de-emphasize
            ),
          ),
        ],
      ),
    );
  }
}
