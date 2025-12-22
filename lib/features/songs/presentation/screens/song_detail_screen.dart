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

  List<SectionBlock> _buildSections(List<LyricLine> lyrics) {
    if (lyrics.isEmpty) return [];

    final Map<String, List<LyricLine>> order = {};

    for (final line in lyrics) {
      final key = line.sectionType ?? 'unknown';

      // create new bucket if empty, key being section name
      order.putIfAbsent(key, () => []);
      order[key]!.add(line);
    }

    return order.entries.map((entry) {
      final sectionKey = entry.key;
      final items = entry.value
        ..sort((a, b) => (a.lineNumber).compareTo(b.lineNumber));

      return SectionBlock(
        title: _formatSectionTitle(sectionKey),
        sectionType: SongSection.fromString(sectionKey),
        lines: items,
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

class SectionBlock {
  final String title;
  final List<LyricLine> lines;
  final SongSection sectionType;

  SectionBlock({
    required this.title,
    required this.lines,
    required this.sectionType,
  });
}
