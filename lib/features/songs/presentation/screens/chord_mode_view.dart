import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/presentation/widgets/chord_line_renderer.dart';
import 'package:worship_lamal/features/profile/presentation/providers/preferences_provider.dart';

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
  // Remembers the scale at the exact moment the user touches the screen
  double _baseScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    final scaleFactor = ref.watch(chordScaleProvider);

    // 2. WRAP EVERYTHING IN A GESTURE DETECTOR
    return GestureDetector(
      // Fires once when the user's two fingers touch the screen
      onScaleStart: (details) {
        _baseScale = scaleFactor;
      },
      // Fires continuously as their fingers move closer/further apart
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
              // A. META-HEADER & DIVIDER (Unchanged)
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

                    final columns = _balanceColumns(
                      widget.song.sections,
                      columnCount,
                    );

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
                                  children: columns[index]
                                      .map(
                                        (s) => _buildCompactSection(
                                          context,
                                          s,
                                          isWideScreen,
                                          scaleFactor,
                                        ),
                                      )
                                      .toList(),
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

  // 3. APPLY THE SCALE FACTOR TO THE FONTS
  Widget _buildCompactSection(
    BuildContext context,
    SectionBlock section,
    bool isWideScreen,
    double scaleFactor,
  ) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 20.0 * scaleFactor,
      ), // Scale padding so it breathes naturally
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
                // Multiply base sizes by the new scale factor
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
                  // Multiply base sizes by the new scale factor
                  fontSize: (isWideScreen ? 14 : 13.5) * scaleFactor,
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                ),
                lyricStyle: TextStyle(
                  // Multiply base sizes by the new scale factor
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
}
