import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worship_lamal/features/songs/presentation/widgets/chord_line_renderer.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  group('ChordLineRenderer', () {
    testWidgets('renders chord text above lyric text in a Column', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const ChordLineRenderer(line: '[G]Amazing grace')),
      );

      final chordFinder = find.text('G');
      final lyricFinder = find.text('Amazing ');

      expect(chordFinder, findsOneWidget);
      expect(lyricFinder, findsOneWidget);

      final chordTop = tester.getTopLeft(chordFinder).dy;
      final lyricTop = tester.getTopLeft(lyricFinder).dy;
      expect(chordTop, lessThan(lyricTop));

      final column = tester.widget<Column>(
        find.ancestor(of: chordFinder, matching: find.byType(Column)).first,
      );
      expect(column.crossAxisAlignment, CrossAxisAlignment.start);
    });

    testWidgets('reserves vertical space when a chunk has no chord', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const ChordLineRenderer(line: 'Plain [C]word')),
      );

      expect(find.text('Plain '), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('word'), findsOneWidget);

      final plainColumn = tester.widget<Column>(
        find.ancestor(
          of: find.text('Plain '),
          matching: find.byType(Column),
        ).first,
      );
      expect(
        plainColumn.children.whereType<SizedBox>().any((b) => b.height == 11.0),
        isTrue,
      );
    });

    testWidgets('translates Nashville chords using targetKey', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ChordLineRenderer(
            line: '[1]Amazing [4]grace [5]how',
            targetKey: 'G',
          ),
        ),
      );

      expect(find.text('G'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
      expect(find.text('1'), findsNothing);
    });

    testWidgets('re-transposes Nashville chords when targetKey changes', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const ChordLineRenderer(
            line: '[1]Amazing [4]grace [5]how',
            targetKey: 'D',
          ),
        ),
      );

      expect(find.text('D'), findsOneWidget);
      expect(find.text('G'), findsOneWidget);
      expect(find.text('A'), findsOneWidget);
    });

    testWidgets('keeps raw chords untranslated when targetKey is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const ChordLineRenderer(line: '[Am]Holy [F]Spirit')),
      );

      expect(find.text('Am'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
    });

    testWidgets('groups mid-word chord splits into the same Row unit', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const ChordLineRenderer(
            line: '[1]Ma[4]whna [5]Keima',
            targetKey: 'G',
          ),
        ),
      );

      final maRow = find.ancestor(
        of: find.text('Ma'),
        matching: find.byType(Row),
      );
      final whnaRow = find.ancestor(
        of: find.text('whna '),
        matching: find.byType(Row),
      );
      final keimaRow = find.ancestor(
        of: find.text('Keima'),
        matching: find.byType(Row),
      );

      expect(maRow, findsOneWidget);
      expect(whnaRow, findsOneWidget);
      expect(keimaRow, findsOneWidget);

      // 'Ma' and 'whna ' belong to the same word Row; 'Keima' is separate.
      expect(tester.widget<Row>(maRow), same(tester.widget<Row>(whnaRow)));
      expect(tester.widget<Row>(maRow), isNot(same(tester.widget<Row>(keimaRow))));
    });

    testWidgets('splits multi-word chunks into separate word Rows', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const ChordLineRenderer(
            line: '[1]Hello World',
            targetKey: 'C',
          ),
        ),
      );

      final helloRow = tester.widget<Row>(
        find.ancestor(of: find.text('Hello '), matching: find.byType(Row)),
      );
      final worldRow = tester.widget<Row>(
        find.ancestor(of: find.text('World'), matching: find.byType(Row)),
      );

      expect(helloRow, isNot(same(worldRow)));
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('renders empty Wrap for an empty line', (tester) async {
      await tester.pumpWidget(_wrap(const ChordLineRenderer(line: '')));

      final wrap = tester.widget<Wrap>(find.byType(Wrap));
      expect(wrap.children, isEmpty);
    });
  });
}
