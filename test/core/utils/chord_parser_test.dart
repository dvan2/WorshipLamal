import 'package:flutter_test/flutter_test.dart';
import 'package:worship_lamal/core/utils/chord_parser.dart';

void main() {
  group('ChordParser', () {
    test('returns empty list for empty string input', () {
      final chunks = ChordParser.parse('');
      expect(chunks, isEmpty);
    });

    test('parses plain text without chords as a single chunk with null chord', () {
      final chunks = ChordParser.parse('Amazing grace how sweet the sound');
      expect(chunks.length, 1);
      expect(chunks.first.chord, isNull);
      expect(chunks.first.text, 'Amazing grace how sweet the sound');
    });

    test('parses line with chord only into chord chunk with empty text', () {
      final chunks = ChordParser.parse('[G]');
      expect(chunks.length, 1);
      expect(chunks.first.chord, 'G');
      expect(chunks.first.text, '');
    });

    test('parses chord at start followed by text', () {
      final chunks = ChordParser.parse('[G]Amazing');
      expect(chunks.length, 1);
      expect(chunks.first.chord, 'G');
      expect(chunks.first.text, 'Amazing');
    });

    test('parses leading text followed by chord and text', () {
      final chunks = ChordParser.parse('Amazing [G]Grace');
      expect(chunks.length, 2);
      expect(chunks[0].chord, isNull);
      expect(chunks[0].text, 'Amazing ');
      expect(chunks[1].chord, 'G');
      expect(chunks[1].text, 'Grace');
    });

    test('parses multiple chord-text pairs in standard ChordPro notation', () {
      final chunks = ChordParser.parse('[G]Amazing [C]grace how [D]sweet');
      expect(chunks.length, 3);
      expect(chunks[0].chord, 'G');
      expect(chunks[0].text, 'Amazing ');
      expect(chunks[1].chord, 'C');
      expect(chunks[1].text, 'grace how ');
      expect(chunks[2].chord, 'D');
      expect(chunks[2].text, 'sweet');
    });

    test('parses consecutive chords without text between them', () {
      final chunks = ChordParser.parse('[G][C]word');
      expect(chunks.length, 2);
      expect(chunks[0].chord, 'G');
      expect(chunks[0].text, '');
      expect(chunks[1].chord, 'C');
      expect(chunks[1].text, 'word');
    });

    test('handles malformed brackets without closing bracket as plain text', () {
      final chunks = ChordParser.parse('[G Amazing grace');
      expect(chunks.length, 1);
      expect(chunks.first.chord, isNull);
      expect(chunks.first.text, 'G Amazing grace');
    });

    test('handles leading text followed by unclosed bracket safely', () {
      final chunks = ChordParser.parse('Verse 1 [G broken chord');
      expect(chunks.length, 2);
      expect(chunks[0].chord, isNull);
      expect(chunks[0].text, 'Verse 1 ');
      expect(chunks[1].chord, isNull);
      expect(chunks[1].text, 'G broken chord');
    });

    test('handles empty brackets gracefully', () {
      final chunks = ChordParser.parse('[]word');
      expect(chunks.length, 1);
      expect(chunks.first.chord, '');
      expect(chunks.first.text, 'word');
    });

    test('parses complex chord extensions within brackets', () {
      final chunks = ChordParser.parse('[Cmaj7]Praise [F#m7b5]the [Gsus4/B]Lord');
      expect(chunks.length, 3);
      expect(chunks[0].chord, 'Cmaj7');
      expect(chunks[0].text, 'Praise ');
      expect(chunks[1].chord, 'F#m7b5');
      expect(chunks[1].text, 'the ');
      expect(chunks[2].chord, 'Gsus4/B');
      expect(chunks[2].text, 'Lord');
    });
  });
}
