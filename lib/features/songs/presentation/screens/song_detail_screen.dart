import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/core/theme/app_constants.dart';
import 'package:worship_lamal/features/profile/presentation/providers/preferences_provider.dart';
import 'package:worship_lamal/features/setlists/presentation/providers/setlist_provider.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/presentation/providers/display_key_provider.dart';
import 'package:worship_lamal/features/songs/presentation/providers/history_provider.dart';
import 'package:worship_lamal/features/songs/presentation/screens/chord_mode_view.dart';
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

    final currentScale = ref.watch(chordScaleProvider);
    final displayPercentage = (currentScale * 100).round();

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
        actions: [
          // The Compact Zoom Pill
          Center(
            child: Container(
              height:
                  36, // Forces it to be shorter than a standard AppBar button
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Zoom Out (-)
                  IconButton(
                    icon: const Icon(Icons.remove, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40),
                    tooltip: 'Zoom Out',
                    onPressed: () =>
                        ref.read(chordScaleProvider.notifier).decrease(),
                  ),
                  // Reset (100%)
                  InkWell(
                    onTap: () => ref.read(chordScaleProvider.notifier).reset(),
                    child: Container(
                      alignment: Alignment.center,
                      constraints: const BoxConstraints(
                        minWidth: 44,
                      ), // Keeps the pill from jumping in size
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        "$displayPercentage%", // Dynamically injects 90%, 100%, 110%, etc.
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),

                  // Zoom In (+)
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40),
                    tooltip: 'Zoom In',
                    onPressed: () =>
                        ref.read(chordScaleProvider.notifier).increase(),
                  ),
                ],
              ),
            ),
          ),
          // Guide Button
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Chord Guide',
            onPressed: () => _showChordGuide(context),
          ),
          const SizedBox(width: 8),
        ],
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
            return ChordModeView(
              song: song,
              displayKey: displayKey,
              isTransposed: isFemaleMode,
            );
          } else {
            return _LyricModeView(
              song: song,
              displayKey: displayKey,
              isTransposed: isFemaleMode,
              scaleFactor: currentScale,
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
// 2. LYRIC MODE VIEW (Colorful, Vertical, Sections)
// ==============================================================================
class _LyricModeView extends StatelessWidget {
  final Song song;
  final String displayKey;
  final bool isTransposed;
  final double scaleFactor;

  const _LyricModeView({
    required this.song,
    required this.displayKey,
    required this.isTransposed,
    required this.scaleFactor,
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
      // 1. More breathing room between sections
      margin: const EdgeInsets.only(bottom: 24.0),

      // 2. The "Accent Bar" approach
      decoration: BoxDecoration(
        color: config.backgroundColor, // Now highly transparent
        border: Border(
          left: BorderSide(
            color: config.accentColor,
            width: 4.0, // A bold, modern left-line indicator
          ),
        ),
      ),

      // 3. Clean padding (more on the left to push away from the accent bar)
      padding: const EdgeInsets.only(
        left: 16.0,
        top: 8.0,
        bottom: 8.0,
        right: 12.0,
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 4. Naked, integrated headers
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              section.title.toUpperCase(),
              style: TextStyle(
                color: config.accentColor, // Matches the left bar
                fontWeight: FontWeight.w800,
                fontSize: 12 * scaleFactor,
                letterSpacing: 1.0, // Widened letter spacing looks premium
              ),
            ),
          ),

          // 5. The Lyrics
          ...section.lines.map((line) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6.0),
              child: Text(
                line.content,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize:
                      18 * scaleFactor, // Slightly larger for pure reading
                  height: 1.4, // Tighter line-height to group the stanza
                  color: Colors.black87, // Softer than pure black
                  fontWeight: FontWeight.w500, // Just a touch of weight
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  _SectionConfig _getSectionConfig(String type) {
    final lowerType = type.toLowerCase().trim();

    // The trick here is using highly transparent backgrounds (alpha: 0.05)
    // and bold, solid accent colors for the text and left border.
    if (lowerType.contains('chorus') && !lowerType.contains('pre')) {
      return _SectionConfig(
        backgroundColor: AppColors.chorusBackground.withValues(alpha: 0.2),
        accentColor: AppColors.chorusBorder,
      );
    } else if (lowerType.contains('bridge')) {
      return _SectionConfig(
        backgroundColor: AppColors.bridgeBackground.withValues(alpha: 0.2),
        accentColor: AppColors.bridgeBorder,
      );
    } else if (lowerType.contains('pre') || lowerType.contains('tag')) {
      return _SectionConfig(
        backgroundColor: AppColors.preChorusBackground.withValues(alpha: 0.2),
        accentColor: AppColors.preChorusBorder,
      );
    }

    // Default (Verses) - usually best kept completely clean/transparent
    return _SectionConfig(
      backgroundColor: Colors.transparent,
      accentColor: AppColors.primary.withValues(alpha: 0.6),
    );
  }
}

class _SectionConfig {
  final Color backgroundColor;
  final Color accentColor;

  const _SectionConfig({
    required this.backgroundColor,
    required this.accentColor,
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

void _showChordGuide(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.auto_stories, color: Colors.black87),
          SizedBox(width: 12),
          Text("How to Read", style: TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _GuideRow(
            icon: Icons.zoom_out_map,
            title: "Pinch to Zoom",
            description:
                "Use two fingers anywhere on the screen to scale the text up or down for easier reading.",
          ),
          SizedBox(height: 16),
          _GuideRow(
            icon: Icons.zoom_out_map,
            title: "Zoom Text",
            description:
                "Use the - and + buttons in the top menu, or use two fingers to pinch the screen to scale the text.",
          ),
          SizedBox(height: 16),
          _GuideRow(
            icon: Icons.restart_alt,
            title: "Reset View",
            description:
                "Tap the zoom percentage number in the middle to return the text to its default size.",
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Got it!"),
        ),
      ],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

class _GuideRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _GuideRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: Colors.blueGrey),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

void _showTextSettingsSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Text Size",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.text_decrease, size: 28),
                  onPressed: () =>
                      ref.read(chordScaleProvider.notifier).decrease(),
                ),
                TextButton(
                  onPressed: () =>
                      ref.read(chordScaleProvider.notifier).reset(),
                  child: const Text(
                    "RESET",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.text_increase, size: 28),
                  onPressed: () =>
                      ref.read(chordScaleProvider.notifier).increase(),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
