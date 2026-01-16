import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/features/songs/presentation/providers/song_provider.dart';
import 'package:worship_lamal/features/songs/presentation/widgets/chord_line_renderer.dart';
import 'package:worship_lamal/features/songs/presentation/widgets/chord_view_toolbar.dart'; // From previous step

class SongChordsScreen extends ConsumerWidget {
  final String songId;

  const SongChordsScreen({super.key, required this.songId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songAsync = ref.watch(songDetailProvider(songId));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chords"),
        backgroundColor: AppColors.surface,
      ),
      body: songAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text("Error: $err")),
        data: (song) {
          // 1. Use the SHARED logic from the model
          final sections = song.sections;

          return Column(
            children: [
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final section = sections[index];
                          return _buildSectionItem(context, section);
                        }, childCount: sections.length),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionItem(BuildContext context, dynamic section) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 24.0,
      ), // Spacing between Verse/Chorus
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. SECTION HEADER (e.g., "Verse 1")
          // Matches the style of your main song detail screen
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              section.title,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),

          // 2. LINES (Using ChordLineRenderer)
          ...section.lines.map((line) {
            // Prefer chord_pro content, fallback to plain lyrics
            final contentToRender = line.contentChordPro ?? line.content;

            return Padding(
              padding: const EdgeInsets.only(
                bottom: 16.0,
              ), // Spacing between lines
              child: ChordLineRenderer(
                line: contentToRender,
                // You can pass specific styles here if needed
                chordStyle: const TextStyle(
                  fontSize: 15,
                  color: Colors.deepOrange,
                  fontWeight: FontWeight.w900,
                ),
                lyricStyle: const TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                  height: 1.5,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
