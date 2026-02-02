import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/features/songs/presentation/providers/song_provider.dart';
import 'package:worship_lamal/features/songs/presentation/widgets/chord_line_renderer.dart';

class SongChordsScreen extends ConsumerWidget {
  final String songId;

  const SongChordsScreen({super.key, required this.songId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songAsync = ref.watch(songDetailProvider(songId));

    return Scaffold(
      backgroundColor: Colors.white, // Paper-like background
      appBar: AppBar(
        title: const Text("Chords", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: songAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (song) {
          final sections = song.sections;

          return LayoutBuilder(
            builder: (context, constraints) {
              // 1. Determine if we can fit two columns (Tablet/Landscape)
              // Adjust this value (e.g., 500) based on your needs.
              bool useTwoColumns = constraints.maxWidth > 500;

              if (!useTwoColumns) {
                // SINGLE COLUMN MODE (Phone Portrait)
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sections
                        .map((s) => _buildCompactSection(context, s))
                        .toList(),
                  ),
                );
              } else {
                // 2. TWO COLUMN MODE (The "PDF Look")
                // Split sections roughly in half
                final midPoint = (sections.length / 2).ceil();
                final leftColumn = sections.take(midPoint).toList();
                final rightColumn = sections.skip(midPoint).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: leftColumn
                              .map((s) => _buildCompactSection(context, s))
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: 24), // Gutter between columns
                      // Right Column
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
                );
              }
            },
          );
        },
      ),
    );
  }

  Widget _buildCompactSection(BuildContext context, dynamic section) {
    return Padding(
      // Reduced bottom padding significantly (was 24)
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. MINIMALIST HEADER
          // Removed the container/pill. Just bold text like the PDF.
          Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Text(
              section.title.toUpperCase(), // PDF style usually caps
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 14, // Smaller font
                decoration:
                    TextDecoration.underline, // Optional: matches some charts
              ),
            ),
          ),

          // 2. COMPACT LINES
          ...section.lines.map<Widget>((line) {
            final contentToRender = line.contentChordPro ?? line.content;

            return Padding(
              // Very tight spacing between lines (was 16)
              padding: const EdgeInsets.only(bottom: 4.0),
              child: ChordLineRenderer(
                line: contentToRender,
                // 3. SMALLER FONTS
                chordStyle: const TextStyle(
                  fontSize: 13, // Reduced from 15
                  color:
                      Colors.black, // Dark chords often read better on charts
                  fontWeight: FontWeight.w700,
                ),
                lyricStyle: const TextStyle(
                  fontSize: 13, // Reduced from 16
                  color: Colors.black87,
                  height: 1.2, // Tighter line height
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
