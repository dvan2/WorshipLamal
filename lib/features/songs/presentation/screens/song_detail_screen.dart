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
        actions: isChordMode
            ? [
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
                          onTap: () =>
                              ref.read(chordScaleProvider.notifier).reset(),
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
              ]
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
