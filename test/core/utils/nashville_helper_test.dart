import 'package:flutter_test/flutter_test.dart';
import 'package:worship_lamal/core/utils/nashville_helper.dart';

void main() {
  group('NashvilleHelper', () {
    group('edge cases and guards', () {
      test('returns empty string if chord input is empty', () {
        expect(NashvilleHelper.translate('', 'C'), '');
        expect(NashvilleHelper.translate('', 'G'), '');
      });

      test('returns unchanged chord if key root is unknown or invalid', () {
        expect(NashvilleHelper.translate('1', '?'), '1');
        expect(NashvilleHelper.translate('4/1', 'XYZ'), '4/1');
        expect(NashvilleHelper.translate('b7', ''), 'b7');
      });
    });

    group('major scale scale degrees (Key of C)', () {
      // 1=C, 2=D, 3=E, 4=F, 5=G, 6=A, b7=Bb, 7=B
      test('translates numbers 1 through 7 accurately in key of C', () {
        expect(NashvilleHelper.translate('1', 'C'), 'C');
        expect(NashvilleHelper.translate('2', 'C'), 'D');
        expect(NashvilleHelper.translate('3', 'C'), 'E');
        expect(NashvilleHelper.translate('4', 'C'), 'F');
        expect(NashvilleHelper.translate('5', 'C'), 'G');
        expect(NashvilleHelper.translate('6', 'C'), 'A');
        expect(NashvilleHelper.translate('7', 'C'), 'B');
      });

      test('translates b7 correctly in key of C to Bb', () {
        expect(NashvilleHelper.translate('b7', 'C'), 'Bb');
      });
    });

    group('transposition across different key roots', () {
      test('translates degrees in key of G', () {
        // G root: 1=G, 4=C, 5=D, 6=E, b7=F
        expect(NashvilleHelper.translate('1', 'G'), 'G');
        expect(NashvilleHelper.translate('4', 'G'), 'C');
        expect(NashvilleHelper.translate('5', 'G'), 'D');
        expect(NashvilleHelper.translate('6', 'G'), 'E');
        expect(NashvilleHelper.translate('b7', 'G'), 'F');
      });

      test('translates degrees in key of D', () {
        // D root: 1=D, 2=E, 4=G, 5=A, b7=C
        expect(NashvilleHelper.translate('1', 'D'), 'D');
        expect(NashvilleHelper.translate('4', 'D'), 'G');
        expect(NashvilleHelper.translate('5', 'D'), 'A');
        expect(NashvilleHelper.translate('b7', 'D'), 'C');
      });

      test('translates degrees in flat keys (Eb)', () {
        // Eb root: 1=Eb, 4=Ab, 5=Bb, b7=C# (MusicTheory chromatic scale uses C# rather than Db)
        expect(NashvilleHelper.translate('1', 'Eb'), 'Eb');
        expect(NashvilleHelper.translate('4', 'Eb'), 'Ab');
        expect(NashvilleHelper.translate('5', 'Eb'), 'Bb');
        expect(NashvilleHelper.translate('b7', 'Eb'), 'C#');
      });

      test('normalizes enharmonic key roots (Db -> C#)', () {
        // Db normalizes to C#: 1=C#, 4=F#, 5=Ab
        expect(NashvilleHelper.translate('1', 'Db'), 'C#');
        expect(NashvilleHelper.translate('4', 'Db'), 'F#');
        expect(NashvilleHelper.translate('5', 'Db'), 'Ab');
      });
    });

    group('minor key roots', () {
      test('strips trailing m from minor key root before calculation', () {
        // Am key root -> strips 'm' -> resolves using A root: 1=A, 4=D, 5=E
        expect(NashvilleHelper.translate('1', 'Am'), 'A');
        expect(NashvilleHelper.translate('4', 'Am'), 'D');
        expect(NashvilleHelper.translate('5', 'Am'), 'E');
        expect(NashvilleHelper.translate('1m', 'Am'), 'Am');
      });

      test('handles Em and Bm roots', () {
        // Em -> E root: 1=E, 4=A, 5=B
        expect(NashvilleHelper.translate('1', 'Em'), 'E');
        expect(NashvilleHelper.translate('4', 'Em'), 'A');
        expect(NashvilleHelper.translate('5', 'Em'), 'B');
      });
    });

    group('complex chords, suffixes, and slash/compound chords', () {
      test('preserves chord suffixes like m, maj7, m7, sus4, add9', () {
        expect(NashvilleHelper.translate('6m', 'C'), 'Am');
        expect(NashvilleHelper.translate('6m7', 'C'), 'Am7');
        expect(NashvilleHelper.translate('2m', 'G'), 'Am');
        expect(NashvilleHelper.translate('1maj7', 'C'), 'Cmaj7');
        expect(NashvilleHelper.translate('5sus4', 'D'), 'Asus4');
        expect(NashvilleHelper.translate('4add9', 'G'), 'Cadd9');
        expect(NashvilleHelper.translate('b7sus', 'G'), 'Fsus');
      });

      test('translates compound slash chords (e.g. 4/1, 5/7, 1/3)', () {
        // In G: 4=C, 1=G -> C/G
        expect(NashvilleHelper.translate('4/1', 'G'), 'C/G');
        // In C: 1=C, 3=E -> C/E
        expect(NashvilleHelper.translate('1/3', 'C'), 'C/E');
        // In D: 5=A, 7=C# -> A/C#
        expect(NashvilleHelper.translate('5/7', 'D'), 'A/C#');
        // With minor and slash: 6m/1 in G -> Em/G
        expect(NashvilleHelper.translate('6m/1', 'G'), 'Em/G');
      });

      test('translates space-separated chord progressions in a line', () {
        expect(
          NashvilleHelper.translate('1 4 5 1', 'C'),
          'C F G C',
        );
        expect(
          NashvilleHelper.translate('1 - 5 - 6m - 4', 'G'),
          'G - D - Em - C',
        );
      });
    });
  });
}
