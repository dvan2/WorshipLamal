import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/core/theme/app_constants.dart';
import 'package:worship_lamal/features/profile/presentation/providers/preferences_provider.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/presentation/providers/display_key_provider.dart';
import 'package:worship_lamal/features/songs/presentation/widgets/chord_line_renderer.dart';

import '../providers/song_provider.dart';
import '../widgets/song_header.dart';

class SongDetailScreen extends ConsumerStatefulWidget {
  final String songId;
  final String? overrideKey;

  const SongDetailScreen({super.key, required this.songId, this.overrideKey});

  @override
  ConsumerState<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends ConsumerState<SongDetailScreen> {
  bool _isChordMode = false;

  @override
  Widget build(BuildContext context) {
    final songAsync = ref.watch(songDetailProvider(widget.songId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Song'),
        actions: [
          IconButton(
            icon: Icon(_isChordMode ? Icons.lyrics : Icons.piano),
            tooltip: _isChordMode ? "Show Lyrics" : "Show Chords",
            onPressed: () {
              setState(() {
                _isChordMode = !_isChordMode;
              });
            },
          ),
        ],
      ),
      body: songAsync.when(
        data: (song) => _SongDetailContent(
          song: song,
          isChordMode: _isChordMode,
          overrideKey: widget.overrideKey,
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(error: err.toString()),
      ),
    );
  }
}

class _SongDetailContent extends ConsumerWidget {
  final Song song;
  final bool isChordMode;
  final String? overrideKey;

  const _SongDetailContent({
    required this.song,
    required this.isChordMode,
    this.overrideKey,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Using the Logic from Song Model
    final sections = song.sections;

    // Calculate the "Smart Default" (User Pref > Vocal Mode > Original)
    final smartDefaultKey = ref.watch(
      displayKeyProvider((originalKey: song.key, songId: song.id)),
    );

    final displayKey = overrideKey ?? smartDefaultKey;

    final isFemaleMode =
        ref.watch(preferencesProvider).vocalMode == VocalMode.female;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SongHeader(
            song: song,
            displayKey: displayKey,
            isTransposed: isFemaleMode,
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.all(AppConstants.songDetailPadding),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final section = sections[index];

              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < sections.length - 1
                      ? AppConstants.sectionSpacing
                      : 0,
                ),
                // 2. Unified Builder
                child: _buildSection(context, section, displayKey),
              );
            }, childCount: sections.length),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(
    BuildContext context,
    SectionBlock section,
    String currentKey,
  ) {
    // Determine colors based on section type
    final config = _getSectionConfig(section.sectionType);

    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      width: double.infinity,
      decoration: BoxDecoration(
        // Use the specific background color for this section type
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          // Use the specific border/accent color
          color: config.borderColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER PILL
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: config.headerColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                section.title.toUpperCase(),
                style: TextStyle(
                  color: config.textColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),

            // LINES LOOP (Lyrics/Chords)
            ...section.lines.map((line) {
              if (isChordMode) {
                // === CHORD MODE ===
                final contentToRender = line.contentChordPro ?? line.content;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: ChordLineRenderer(
                    line: contentToRender,
                    targetKey: currentKey,
                    chordStyle: const TextStyle(
                      fontSize: 15,
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.w800,
                    ),
                    lyricStyle: const TextStyle(
                      fontSize: 17,
                      color: AppColors.textPrimary,
                      height: 1.4,
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                );
              } else {
                // === LYRIC MODE ===
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Text(
                    line.content,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 17,
                      height: 1.6,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }
            }),
          ],
        ),
      ),
    );
  }

  _SectionConfig _getSectionConfig(String type) {
    final lowerType = type.toLowerCase().trim();

    // CHORUS
    if (lowerType.contains('chorus') && !lowerType.contains('pre')) {
      return _SectionConfig(
        backgroundColor: AppColors.chorusBackground, // e.g., Light Blue
        borderColor: AppColors.chorusBorder.withValues(alpha: 0.3),
        headerColor: AppColors.chorusBorder.withValues(alpha: 0.15),
        textColor: AppColors.chorusText, // Darker Blue
      );
    }
    // BRIDGE
    else if (lowerType.contains('bridge')) {
      return _SectionConfig(
        backgroundColor: AppColors.bridgeBackground, // e.g., Light Orange
        borderColor: AppColors.bridgeBorder.withValues(alpha: 0.3),
        headerColor: AppColors.bridgeBorder.withValues(alpha: 0.15),
        textColor: AppColors.bridgeText, // Darker Orange
      );
    }
    // PRE-CHORUS / TAG
    else if (lowerType.contains('pre') || lowerType.contains('tag')) {
      return _SectionConfig(
        backgroundColor: AppColors.preChorusBackground, // e.g., Light Purple
        borderColor: AppColors.preChorusBorder.withValues(alpha: 0.3),
        headerColor: AppColors.preChorusBorder.withValues(alpha: 0.15),
        textColor: AppColors.preChorusText,
      );
    }

    // DEFAULT (Verse)
    return _SectionConfig(
      backgroundColor: AppColors.verseBackground, // e.g., White/Gray
      borderColor: AppColors.primary.withValues(alpha: 0.1),
      headerColor: AppColors.primary.withValues(alpha: 0.08),
      textColor: AppColors.verseText,
    );
  }
}

class _SectionConfig {
  final Color backgroundColor;
  final Color borderColor;
  final Color headerColor;
  final Color textColor;

  const _SectionConfig({
    required this.backgroundColor,
    required this.borderColor,
    required this.headerColor,
    required this.textColor,
  });
}

class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text("Error: $error"),
      ),
    );
  }
}
