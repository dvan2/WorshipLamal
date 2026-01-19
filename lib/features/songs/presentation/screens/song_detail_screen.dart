import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/core/theme/app_constants.dart';
import 'package:worship_lamal/features/profile/presentation/providers/preferences_provider.dart';
import 'package:worship_lamal/features/setlists/presentation/providers/setlist_provider.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/presentation/providers/display_key_provider.dart';
import 'package:worship_lamal/features/songs/presentation/widgets/chord_line_renderer.dart';

import '../providers/song_provider.dart';
import '../widgets/song_header.dart';

class SongDetailScreen extends ConsumerWidget {
  final String songId;
  final String? setlistId;

  const SongDetailScreen({super.key, required this.songId, this.setlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songAsync = ref.watch(songDetailProvider(songId));

    final prefs = ref.watch(preferencesProvider);
    final isChordMode = prefs.contentMode == ContentMode.chords;

    String? realtimeOverrideKey;

    if (setlistId != null) {
      final setlistAsync = ref.watch(setlistDetailProvider(setlistId!));

      // If we have data, find THIS song inside that setlist
      if (setlistAsync.value != null) {
        final setlist = setlistAsync.value!;
        // Find the specific item for this song
        // (We use .firstWhereOrNull in case it was deleted remotely)
        try {
          final item = setlist.items.firstWhere((i) => i.songId == songId);
          // Get the live key from the stream!
          if (item.keyOverride != null && item.keyOverride!.isNotEmpty) {
            realtimeOverrideKey = item.keyOverride;
          }
        } catch (_) {
          // Song might have been removed from setlist while we are viewing it
        }
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Song')),
      body: songAsync.when(
        data: (song) => _SongDetailContent(
          song: song,
          isChordMode: isChordMode,
          overrideKey: realtimeOverrideKey,
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
    final sections = song.sections;

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
    final config = _getSectionConfig(section.sectionType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      width: double.infinity,
      decoration: BoxDecoration(
        color: config.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER PILL
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
              margin: const EdgeInsets.only(bottom: 6),
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

            // LINES LOOP
            ...section.lines.map((line) {
              // 3. LOGIC SIMPLIFIED: Just check the boolean passed in
              if (isChordMode) {
                // === CHORD MODE ===
                final contentToRender = line.contentChordPro ?? line.content;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
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
                  padding: const EdgeInsets.only(bottom: 6.0),
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

    if (lowerType.contains('chorus') && !lowerType.contains('pre')) {
      return _SectionConfig(
        backgroundColor: AppColors.chorusBackground,
        borderColor: AppColors.chorusBorder.withValues(alpha: 0.3),
        headerColor: AppColors.chorusBorder.withValues(alpha: 0.15),
        textColor: AppColors.chorusText,
      );
    } else if (lowerType.contains('bridge')) {
      return _SectionConfig(
        backgroundColor: AppColors.bridgeBackground,
        borderColor: AppColors.bridgeBorder.withValues(alpha: 0.3),
        headerColor: AppColors.bridgeBorder.withValues(alpha: 0.15),
        textColor: AppColors.bridgeText,
      );
    } else if (lowerType.contains('pre') || lowerType.contains('tag')) {
      return _SectionConfig(
        backgroundColor: AppColors.preChorusBackground,
        borderColor: AppColors.preChorusBorder.withValues(alpha: 0.3),
        headerColor: AppColors.preChorusBorder.withValues(alpha: 0.15),
        textColor: AppColors.preChorusText,
      );
    }

    return _SectionConfig(
      backgroundColor: AppColors.verseBackground,
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
