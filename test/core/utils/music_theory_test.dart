import 'package:flutter_test/flutter_test.dart';
import 'package:worship_lamal/core/utils/music_theory.dart';

void main() {
  group('MusicTheory', () {
    test('chromaticScale contains exactly 12 standard notes in chromatic order', () {
      expect(MusicTheory.chromaticScale.length, 12);
      expect(
        MusicTheory.chromaticScale,
        ['C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'],
      );
      // Ensure no duplicates
      expect(MusicTheory.chromaticScale.toSet().length, 12);
    });

    group('normalizeNote', () {
      test('normalizes all 6 enharmonic flat/sharp aliases to canonical scale notes', () {
        expect(MusicTheory.normalizeNote('Cb'), 'B');
        expect(MusicTheory.normalizeNote('Db'), 'C#');
        expect(MusicTheory.normalizeNote('D#'), 'Eb');
        expect(MusicTheory.normalizeNote('Gb'), 'F#');
        expect(MusicTheory.normalizeNote('G#'), 'Ab');
        expect(MusicTheory.normalizeNote('A#'), 'Bb');
      });

      test('passes through canonical chromatic scale notes unchanged', () {
        for (final note in MusicTheory.chromaticScale) {
          expect(MusicTheory.normalizeNote(note), note);
        }
      });

      test('returns unknown or empty note strings unchanged', () {
        expect(MusicTheory.normalizeNote(''), '');
        expect(MusicTheory.normalizeNote('?'), '?');
        expect(MusicTheory.normalizeNote('H'), 'H');
        expect(MusicTheory.normalizeNote('Unknown'), 'Unknown');
      });
    });
  });
}
