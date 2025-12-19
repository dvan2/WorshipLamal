import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/core/theme/app_constants.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/data/models/lyric_line_model.dart';

import '../providers/song_provider.dart';
import '../widgets/song_header.dart';
import '../widgets/lyric_section_widget.dart';

class SongDetailScreen extends ConsumerWidget {
  final String songId;

  const SongDetailScreen({super.key, required this.songId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songAsync = ref.watch(songDetailProvider(songId));

    return Scaffold(
      appBar: AppBar(title: const Text('Song')),
      body: songAsync.when(
        data: (song) => _SongDetailContent(song: song),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(error: err.toString()),
      ),
    );
  }
}

class _SongDetailContent extends StatelessWidget {
  final Song song;

  const _SongDetailContent({required this.song});

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections(song.lyricLines);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: SongHeader(song: song)),
        SliverPadding(
          padding: EdgeInsets.all(AppConstants.songDetailPadding),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final section = sections[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < sections.length - 1
                      ? AppConstants.sectionSpacing
                      : 0,
                ),
                child: LyricSectionWidget(section: section),
              );
            }, childCount: sections.length),
          ),
        ),
      ],
    );
  }

  /// Build ordered sections from flat LyricLine list
  /// Preserves first-seen order of sections
  List<SectionBlock> _buildSections(List<LyricLine> lyrics) {
    if (lyrics.isEmpty) return [];

    // Use a map to preserve first-seen order of sections
    final sectionMap = <String, List<LyricLine>>{};

    for (final line in lyrics) {
      final sectionKey = line.sectionType ?? 'unknown';
      if (!sectionMap.containsKey(sectionKey)) {
        sectionMap[sectionKey] = [];
      }
      sectionMap[sectionKey]!.add(line);
    }

    // Convert map to list of SectionBlocks
    return sectionMap.entries.map((entry) {
      final title = entry.key;
      final lines = entry.value;

      // Sort lines by line number within each section
      lines.sort((a, b) => a.lineNumber.compareTo(b.lineNumber));

      return SectionBlock(
        title: _formatSectionTitle(title),
        sectionType: SongSection.fromString(title),
        lines: lines,
      );
    }).toList();
  }

  /// Format section title for display (e.g., "verse" -> "Verse 1")
  String _formatSectionTitle(String rawTitle) {
    final section = SongSection.fromString(rawTitle);
    return section.displayName.isNotEmpty
        ? section.displayName
        : rawTitle.toUpperCase();
  }
}

class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: AppConstants.iconSizeXl,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: AppConstants.spacingLg),
          Text(
            'Failed to load song',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: AppConstants.spacingSm),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingXl),
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

/// Represents one lyrics block on screen
class SectionBlock {
  final String title;
  final SongSection sectionType;
  final List<LyricLine> lines;

  const SectionBlock({
    required this.title,
    required this.sectionType,
    required this.lines,
  });
}
