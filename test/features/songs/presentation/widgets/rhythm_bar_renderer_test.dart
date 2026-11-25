import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:worship_lamal/features/songs/presentation/widgets/rhythm_bar_renderer.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  group('RhythmBarRenderer', () {
    testWidgets('renders SizedBox.shrink when barLine is empty or whitespace', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const RhythmBarRenderer(
            barLine: '   ',
            targetKey: 'G',
            textStyle: TextStyle(fontSize: 16),
          ),
        ),
      );

      expect(find.text('|'), findsNothing);
      expect(find.byType(Row), findsNothing);
    });

    testWidgets('parses piped bars into measures with bounding pipes', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const RhythmBarRenderer(
            barLine: '| 1 | 4 | 5 |',
            targetKey: 'G',
            textStyle: TextStyle(fontSize: 16),
          ),
        ),
      );

      // 3 measures => 4 pipe separators (leading + 3 trailing)
      expect(find.text('|'), findsNWidgets(4));
      expect(find.byType(Expanded), findsNWidgets(3));
      expect(find.text('G'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
    });

    testWidgets('translates Nashville chords including minor and flat-7', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const RhythmBarRenderer(
            barLine: '| 1 4 | 6m b7 |',
            targetKey: 'G',
            textStyle: TextStyle(fontSize: 16),
          ),
        ),
      );

      expect(find.text('G'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.text('Em'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
    });

    testWidgets('translates the same barLine to a different targetKey', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const RhythmBarRenderer(
            barLine: '| 1 4 | 5 6m |',
            targetKey: 'C',
            textStyle: TextStyle(fontSize: 16),
          ),
        ),
      );

      expect(find.text('C'), findsOneWidget);
      expect(find.text('F'), findsOneWidget);
      expect(find.text('G'), findsOneWidget);
      expect(find.text('Am'), findsOneWidget);
    });

    testWidgets(
      'uses MainAxisAlignment.start for single-chord measures and spaceBetween for multi-chord measures',
      (tester) async {
        await tester.pumpWidget(
          _wrap(
            const RhythmBarRenderer(
              barLine: '| 1 | 4 5 |',
              targetKey: 'G',
              textStyle: TextStyle(fontSize: 16),
            ),
          ),
        );

        final singleMeasureRow = tester.widget<Row>(
          find.ancestor(of: find.text('G'), matching: find.byType(Row)).first,
        );
        final multiMeasureRow = tester.widget<Row>(
          find.ancestor(of: find.text('C'), matching: find.byType(Row)).first,
        );

        expect(singleMeasureRow.mainAxisAlignment, MainAxisAlignment.start);
        expect(
          multiMeasureRow.mainAxisAlignment,
          MainAxisAlignment.spaceBetween,
        );
      },
    );
  });
}
