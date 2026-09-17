import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/data/models/rhythm_chart_model.dart'; // Ensure this matches your path
import 'package:worship_lamal/features/songs/presentation/widgets/chord_line_renderer.dart';
import 'package:worship_lamal/features/songs/presentation/widgets/rhythm_bar_renderer.dart'; // Ensure this matches your path
import 'package:worship_lamal/features/profile/presentation/providers/preferences_provider.dart';

// 1. Helper class to group Rhythm Charts by section (like Verse, Chorus)
class RhythmSectionBlock {
  final String title;
  final List<RhythmChart> charts;

  RhythmSectionBlock({required this.title, required this.charts});
}

class ChordModeView extends ConsumerStatefulWidget {
  final Song song;
  final String displayKey;
  final bool isTransposed;

  const ChordModeView({
    super.key,
    required this.song,
    required this.displayKey,
    required this.isTransposed,
  });

  @override
  ConsumerState<ChordModeView> createState() => _ChordModeViewState();
}

class _ChordModeViewState extends ConsumerState<ChordModeView> {
  double _baseScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final scaleFactor = ref.watch(chordScaleProvider);

    // Check which workflow we are using
    final hasRhythmCharts = widget.song.rhythmCharts.isNotEmpty;

    return GestureDetector(
      onScaleStart: (details) {
        _baseScale = scaleFactor;
      },
      onScaleUpdate: (details) {
        ref
            .read(chordScaleProvider.notifier)
            .setScale(_baseScale * details.scale);
      },
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            children: [
              // ----------------------------------------------------
              // A. META-HEADER & DIVIDER
              // ----------------------------------------------------
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.song.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                  letterSpacing: -0.5,
                                  height: 1.1,
                                ),
                              ),
                              if (widget.song.artistNames.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    widget.song.artistNames,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontStyle: FontStyle.italic,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "Key of ${widget.displayKey}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            if (widget.song.bpm != null)
                              Text(
                                "${widget.song.bpm} BPM",
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(
                      color: Colors.black,
                      thickness: 1.5,
                      height: 1.5,
                    ),
                  ],
                ),
              ),

              // ----------------------------------------------------
              // B. RESPONSIVE SHEET MUSIC BODY
              // ----------------------------------------------------
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWideScreen = constraints.maxWidth >= 600;
                    final columnCount = isWideScreen ? 2 : 1;

                    return Scrollbar(
                      thumbVisibility: true,
                      thickness: 4,
                      radius: const Radius.circular(2),
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          16,
                          16,
                          16,
                          32 + bottomPadding,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(columnCount, (index) {
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: index < columnCount - 1 ? 16.0 : 0.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  // THE FORK: Rhythm Charts vs Lyric Charts
                                  children: hasRhythmCharts
                                      ? _buildRhythmGridColumns(
                                          columnCount,
                                          index,
                                          isWideScreen,
                                          scaleFactor,
                                        )
                                      : _buildLegacyLyricColumns(
                                          columnCount,
                                          index,
                                          isWideScreen,
                                          scaleFactor,
                                        ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // NEW WORKFLOW: Rhythm Grid Builders
  // =========================================================================
  List<Widget> _buildRhythmGridColumns(
    int columnCount,
    int index,
    bool isWideScreen,
    double scaleFactor,
  ) {
    final sections = _getRhythmSections();
    final columns = _balanceRhythmColumns(sections, columnCount);

    return columns[index]
        .map(
          (s) =>
              _buildRhythmCompactSection(context, s, isWideScreen, scaleFactor),
        )
        .toList();
  }

  List<RhythmSectionBlock> _getRhythmSections() {
    final Map<String, List<RhythmChart>> map = {};
    for (final chart in widget.song.rhythmCharts) {
      final key = chart.sectionType;
      map.putIfAbsent(key, () => []);
      map[key]!.add(chart);
    }

    final sections = map.entries.map((entry) {
      final items = entry.value
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return RhythmSectionBlock(title: entry.key, charts: items);
    }).toList();

    // Sort the sections themselves based on the first line's sortOrder
    sections.sort(
      (a, b) => a.charts.first.sortOrder.compareTo(b.charts.first.sortOrder),
    );
    return sections;
  }

  List<List<RhythmSectionBlock>> _balanceRhythmColumns(
    List<RhythmSectionBlock> sections,
    int columnCount,
  ) {
    if (columnCount == 1 || sections.isEmpty) return [sections];

    final heights = sections
        .map((s) => 40.0 + (s.charts.length * 30.0))
        .toList();
    final totalHeight = heights.fold(0.0, (a, b) => a + b);
    final targetHeight = totalHeight / columnCount;

    List<List<RhythmSectionBlock>> columns = List.generate(
      columnCount,
      (_) => [],
    );
    double currentColumnHeight = 0;
    int currentColumnIndex = 0;

    for (int i = 0; i < sections.length; i++) {
      if (currentColumnIndex < columnCount - 1 &&
          currentColumnHeight + (heights[i] / 2) > targetHeight) {
        currentColumnIndex++;
        currentColumnHeight = 0;
      }
      columns[currentColumnIndex].add(sections[i]);
      currentColumnHeight += heights[i];
    }
    return columns;
  }

  Widget _buildRhythmCompactSection(
    BuildContext context,
    RhythmSectionBlock section,
    bool isWideScreen,
    double scaleFactor,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24.0 * scaleFactor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The Boxed Section Header (To match your image reference)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 6 * scaleFactor,
              vertical: 2 * scaleFactor,
            ),
            margin: EdgeInsets.only(bottom: 8.0 * scaleFactor),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.black, width: 1.5),
            ),
            child: Text(
              _capitalize(section.title),
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: (isWideScreen ? 15 : 14) * scaleFactor,
              ),
            ),
          ),
          // The Rhythm Bars
          ...section.charts.map((chart) {
            return RhythmBarRenderer(
              barLine: chart.content, // Translates Nashville numbers internally
              targetKey: widget.displayKey,
              textStyle: TextStyle(
                fontSize:
                    (isWideScreen ? 18 : 16) * scaleFactor, // Big, bold chords!
                color: Colors.black,
              ),
            );
          }),
        ],
      ),
    );
  }

  // =========================================================================
  // LEGACY WORKFLOW: Lyric + Chord Builders (Unchanged)
  // =========================================================================
  List<Widget> _buildLegacyLyricColumns(
    int columnCount,
    int index,
    bool isWideScreen,
    double scaleFactor,
  ) {
    final columns = _balanceColumns(widget.song.sections, columnCount);
    return columns[index]
        .map((s) => _buildCompactSection(context, s, isWideScreen, scaleFactor))
        .toList();
  }

  List<List<SectionBlock>> _balanceColumns(
    List<SectionBlock> sections,
    int columnCount,
  ) {
    if (columnCount == 1 || sections.isEmpty) return [sections];

    final heights = sections
        .map((s) => 35.0 + (s.lines.length * 24.0))
        .toList();
    final totalHeight = heights.fold(0.0, (a, b) => a + b);
    final targetHeight = totalHeight / columnCount;

    List<List<SectionBlock>> columns = List.generate(columnCount, (_) => []);
    double currentColumnHeight = 0;
    int currentColumnIndex = 0;

    for (int i = 0; i < sections.length; i++) {
      if (currentColumnIndex < columnCount - 1 &&
          currentColumnHeight + (heights[i] / 2) > targetHeight) {
        currentColumnIndex++;
        currentColumnHeight = 0;
      }
      columns[currentColumnIndex].add(sections[i]);
      currentColumnHeight += heights[i];
    }
    return columns;
  }

  Widget _buildCompactSection(
    BuildContext context,
    SectionBlock section,
    bool isWideScreen,
    double scaleFactor,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.0 * scaleFactor),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: 6.0 * scaleFactor),
            child: Text(
              section.title,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
                fontSize: (isWideScreen ? 15 : 14) * scaleFactor,
              ),
            ),
          ),
          ...section.lines.map((line) {
            final contentToRender = line.contentChordPro ?? line.content;
            return Padding(
              padding: EdgeInsets.only(bottom: 4.0 * scaleFactor),
              child: ChordLineRenderer(
                line: contentToRender,
                targetKey: widget.displayKey,
                chordStyle: TextStyle(
                  fontSize: (isWideScreen ? 14 : 13.5) * scaleFactor,
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                ),
                lyricStyle: TextStyle(
                  fontSize: (isWideScreen ? 13 : 12.5) * scaleFactor,
                  color: Colors.black87,
                  height: 1.2,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
