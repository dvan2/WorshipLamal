import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:worship_lamal/core/utils/nashville_helper.dart';

class RhythmBarRenderer extends StatelessWidget {
  final String barLine;
  final String targetKey;
  final TextStyle textStyle;

  const RhythmBarRenderer({
    super.key,
    required this.barLine,
    required this.targetKey,
    required this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final cleanLine = barLine.trim();
    if (cleanLine.isEmpty) return const SizedBox.shrink();

    final parts = cleanLine.split('|');

    if (parts.isNotEmpty && parts.first.trim().isEmpty) parts.removeAt(0);
    if (parts.isNotEmpty && parts.last.trim().isEmpty) parts.removeLast();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildPipe(),

          ...parts.expand((measure) {
            final rawChords = measure.trim();

            final individualChords = rawChords
                .split(RegExp(r'\s+'))
                .where((s) => s.isNotEmpty)
                .toList();

            return [
              Expanded(
                child: Padding(
                  // This padding creates the left indent for single chords,
                  // and keeps double chords from touching the pipes.
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    // THE NEW LOGIC: Start vs SpaceBetween
                    mainAxisAlignment: individualChords.length == 1
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.spaceBetween,
                    children: individualChords.map((chordStr) {
                      final displayChord = NashvilleHelper.translate(
                        chordStr,
                        targetKey,
                      );

                      return Text(
                        displayChord,
                        style: GoogleFonts.patrickHand(
                          textStyle: textStyle,
                          fontWeight: FontWeight.w700,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              _buildPipe(),
            ];
          }),
        ],
      ),
    );
  }

  Widget _buildPipe() {
    return Text(
      '|',
      style: GoogleFonts.patrickHand(
        textStyle: textStyle.copyWith(
          color: Colors.black26,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}
