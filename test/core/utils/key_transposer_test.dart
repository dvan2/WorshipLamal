import 'package:flutter_test/flutter_test.dart';
import 'package:worship_lamal/core/utils/key_transposer.dart';

void main() {
  group('KeyTransposer', () {
    group('edge cases and guards', () {
      test('returns empty string if input key is empty', () {
        expect(KeyTransposer.transpose('', 0), '');
        expect(KeyTransposer.transpose('', 5), '');
        expect(KeyTransposer.transpose('', -5), '');
      });

      test('returns unknown key string unchanged', () {
        expect(KeyTransposer.transpose('?', 3), '?');
        expect(KeyTransposer.transpose('Unknown', 5), 'Unknown');
        expect(KeyTransposer.transpose('XYZ', -2), 'XYZ');
      });

      test('transposing 0 semitones returns the canonical or normalized key', () {
        expect(KeyTransposer.transpose('C', 0), 'C');
        expect(KeyTransposer.transpose('G', 0), 'G');
        expect(KeyTransposer.transpose('Db', 0), 'C#');
      });
    });

    group('positive shifts (sharps, flats, wrap-around)', () {
      test('transposes by single and multiple semitones', () {
        expect(KeyTransposer.transpose('C', 1), 'C#');
        expect(KeyTransposer.transpose('C', 2), 'D');
        expect(KeyTransposer.transpose('C', 3), 'Eb');
        expect(KeyTransposer.transpose('C', 4), 'E');
        expect(KeyTransposer.transpose('C', 5), 'F');
        expect(KeyTransposer.transpose('C', 7), 'G');
      });

      test('wraps around circularly past B to C', () {
        expect(KeyTransposer.transpose('B', 1), 'C');
        expect(KeyTransposer.transpose('Bb', 2), 'C');
        expect(KeyTransposer.transpose('A', 4), 'C#');
        expect(KeyTransposer.transpose('B', 3), 'D');
      });

      test('full octave and multiple octave shifts wrap back correctly', () {
        expect(KeyTransposer.transpose('G', 12), 'G');
        expect(KeyTransposer.transpose('C', 24), 'C');
        expect(KeyTransposer.transpose('Eb', 13), 'E');
      });

      test('normalizes enharmonic input before shifting', () {
        // Db normalizes to C# (index 1), + 2 = index 3 (Eb)
        expect(KeyTransposer.transpose('Db', 2), 'Eb');
        // D# normalizes to Eb (index 3), + 1 = index 4 (E)
        expect(KeyTransposer.transpose('D#', 1), 'E');
        // Gb normalizes to F# (index 6), + 1 = index 7 (G)
        expect(KeyTransposer.transpose('Gb', 1), 'G');
      });
    });

    group('negative shifts and female vocal mode (-5)', () {
      test('transposes female vocal mode (-5 semitones) correctly across roots', () {
        expect(KeyTransposer.transpose('G', -5), 'D');
        expect(KeyTransposer.transpose('C', -5), 'G');
        expect(KeyTransposer.transpose('D', -5), 'A');
        expect(KeyTransposer.transpose('E', -5), 'B');
        expect(KeyTransposer.transpose('A', -5), 'E');
        expect(KeyTransposer.transpose('F', -5), 'C');
      });

      test('wraps around circularly backward past C to B', () {
        expect(KeyTransposer.transpose('C', -1), 'B');
        expect(KeyTransposer.transpose('C', -2), 'Bb');
        expect(KeyTransposer.transpose('C', -3), 'A');
        expect(KeyTransposer.transpose('C#', -2), 'B');
      });

      test('handles large negative shifts beyond -12 semitones', () {
        // -14 semitones == -2 semitones -> C - 2 = Bb
        expect(KeyTransposer.transpose('C', -14), 'Bb');
        // -24 semitones == full 2 octaves down
        expect(KeyTransposer.transpose('F#', -24), 'F#');
        // -17 semitones == -5 semitones -> G - 5 = D
        expect(KeyTransposer.transpose('G', -17), 'D');
      });
    });
  });
}
