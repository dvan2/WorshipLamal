import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/core/theme/app_constants.dart';
import 'package:worship_lamal/features/profile/presentation/providers/preferences_provider.dart';
import 'package:worship_lamal/features/setlists/presentation/providers/setlist_provider.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/presentation/providers/display_key_provider.dart';
import 'package:worship_lamal/features/songs/presentation/providers/history_provider.dart';
import 'package:worship_lamal/features/songs/presentation/widgets/chord_line_renderer.dart';

import '../providers/song_provider.dart';
import '../widgets/song_header.dart';

class SongDetailScreen extends ConsumerWidget {
  final String songId;
  final String? setlistId;

  const SongDetailScreen({super.key, required this.songId, this.setlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. DATA LOGIC
    final songAsync = ref.watch(songDetailProvider(songId));
    final prefs = ref.watch(preferencesProvider);
    final isChordMode = prefs.contentMode == ContentMode.chords;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(historyControllerProvider).logView(songId);
    });

    String? realtimeOverrideKey;
    if (setlistId != null) {
      final setlistAsync = ref.watch(setlistDetailProvider(setlistId!));
      if (setlistAsync.value != null) {
        try {
          final item = setlistAsync.value!.items.firstWhere(
            (i) => i.songId == songId,
          );
          if (item.keyOverride != null && item.keyOverride!.isNotEmpty) {
            realtimeOverrideKey = item.keyOverride;
          }
        } catch (_) {}
      }
    }

    return Scaffold(
      // Change background based on mode (White for chords, Default/Theme for lyrics)
      backgroundColor: isChordMode ? Colors.white : null,
      appBar: AppBar(
        title: const Text('Song'),
        // Force white AppBar in Chord Mode to match paper look
        backgroundColor: isChordMode ? Colors.white : null,
        elevation: isChordMode ? 0 : null,
        iconTheme: isChordMode
            ? const IconThemeData(color: Colors.black)
            : null,
        titleTextStyle: isChordMode
            ? const TextStyle(
                color: Colors.black,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              )
            : null,
      ),
      body: songAsync.when(
        data: (song) {
          // Calculate Display Key Once
          final smartDefaultKey = ref.watch(
            displayKeyProvider((originalKey: song.key, songId: song.id)),
          );
          final displayKey = realtimeOverrideKey ?? smartDefaultKey;
          final isFemaleMode =
              ref.watch(preferencesProvider).vocalMode == VocalMode.female;

          // 2. SWITCH VIEW BASED ON MODE
          if (isChordMode) {
            return _ChordModeView(
              song: song,
              displayKey: displayKey,
              isTransposed: isFemaleMode,
            );
          } else {
            return _LyricModeView(
              song: song,
              displayKey: displayKey,
              isTransposed: isFemaleMode,
            );
          }
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(error: err.toString()),
      ),
    );
  }
}

// ==============================================================================
// 1. CHORD MODE VIEW (Always 2 Columns, Compact)
// ==============================================================================
class _ChordModeView extends StatelessWidget {
  final Song song;
  final String displayKey;
  final bool isTransposed;

  const _ChordModeView({
    required this.song,
    required this.displayKey,
    required this.isTransposed,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Center(
      child: ConstrainedBox(
        // Keep the max width constraint so it doesn't look ridiculous on desktops,
        // but it will fill 100% of mobile screens.
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SongHeader(
                song: song,
                displayKey: displayKey,
                isTransposed: isTransposed,
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
            Expanded(
              child: Scrollbar(
                thumbVisibility: true,
                thickness: 4,
                radius: const Radius.circular(2),
                child: SingleChildScrollView(
                  // 1. REDUCED PADDING:
                  // Changed horizontal padding from 16 to 8 to give columns more room.
                  padding: EdgeInsets.fromLTRB(8, 16, 8, 32 + bottomPadding),
                  child: _buildTwoColumnLayout(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTwoColumnLayout(BuildContext context) {
    final midPoint = (song.sections.length / 2).ceil();
    final leftColumn = song.sections.take(midPoint).toList();
    final rightColumn = song.sections.skip(midPoint).toList();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: leftColumn
                .map((s) => _buildCompactSection(context, s))
                .toList(),
          ),
        ),
        // 2. REDUCED GUTTER:
        // Changed from 24 to 12. This saves space while keeping separation visible.
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: rightColumn
                .map((s) => _buildCompactSection(context, s))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactSection(BuildContext context, SectionBlock section) {
    return Padding(
      // Tighter vertical spacing between sections
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 2.0),
            child: Text(
              section.title.toUpperCase(),
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 11, // Small, crisp header
                decoration: TextDecoration.underline,
              ),
            ),
          ),
          ...section.lines.map((line) {
            final contentToRender = line.contentChordPro ?? line.content;
            return Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: ChordLineRenderer(
                line: contentToRender,
                targetKey: displayKey,
                // 3. COMPACT FONTS:
                // Reduced sizes slightly to prevent wrapping on narrow screens
                chordStyle: const TextStyle(
                  fontSize: 11.5,
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                ),
                lyricStyle: const TextStyle(
                  fontSize: 11.5,
                  color: Colors.black87,
                  height: 1.15, // Tight line height
                  letterSpacing: -0.3, // Slight squeeze to fit more text
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ==============================================================================
// 2. LYRIC MODE VIEW (Colorful, Vertical, Sections)
// ==============================================================================
class _LyricModeView extends StatelessWidget {
  final Song song;
  final String displayKey;
  final bool isTransposed;

  const _LyricModeView({
    required this.song,
    required this.displayKey,
    required this.isTransposed,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SongHeader(
              song: song,
              displayKey: displayKey,
              isTransposed: isTransposed,
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(AppConstants.songDetailPadding),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final section = song.sections[index];
              return Padding(
                padding: EdgeInsets.only(
                  bottom: index < song.sections.length - 1
                      ? AppConstants.sectionSpacing
                      : 0,
                ),
                child: _buildColoredSection(context, section),
              );
            }, childCount: song.sections.length),
          ),
        ),
      ],
    );
  }

  Widget _buildColoredSection(BuildContext context, SectionBlock section) {
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
            ...section.lines.map((line) {
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
