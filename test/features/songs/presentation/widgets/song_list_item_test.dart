import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:worship_lamal/features/favorites/data/model/favorite_model.dart';
import 'package:worship_lamal/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/presentation/providers/display_key_provider.dart';
import 'package:worship_lamal/features/songs/presentation/widgets/song_list_item.dart';
import 'package:worship_lamal/features/userkey/presentation/providers/user_keys_provider.dart';

import '../../../../helpers/fixtures.dart';

Future<void> _pumpSongListItem(
  WidgetTester tester, {
  required Song song,
  String displayKey = 'G',
  Map<String, String> userKeysMap = const {},
  List<Favorite> favorites = const [],
  VoidCallback? onTap,
  VoidCallback? onLongPress,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        displayKeyProvider((
          originalKey: song.key,
          songId: song.id,
        )).overrideWithValue(displayKey),
        userPreferredKeysMapProvider.overrideWithValue(userKeysMap),
        favoritesListProvider.overrideWithValue(AsyncData(favorites)),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: SongListItem(
            song: song,
            onTap: onTap ?? () {},
            onLongPress: onLongPress,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('SongListItem', () {
    testWidgets('renders title, artist, BPM, type badge, and displayKey', (
      tester,
    ) async {
      final song = tSong(
        id: 'song-1',
        title: 'Amazing Grace',
        key: 'G',
        bpm: 72,
        type: SongType.worship,
      );

      await _pumpSongListItem(tester, song: song, displayKey: 'D');

      expect(find.text('Amazing Grace'), findsOneWidget);
      expect(find.text('Bethel Music • 72 BPM'), findsOneWidget);
      expect(find.text('WORSHIP'), findsOneWidget);
      expect(find.text('D'), findsOneWidget);
    });

    testWidgets('omits BPM and hides type badge for SongType.other', (
      tester,
    ) async {
      final song = tSong(
        id: 'song-2',
        title: 'Simple Song',
        bpm: null,
        type: SongType.other,
      );

      await _pumpSongListItem(tester, song: song);

      expect(find.text('Bethel Music'), findsOneWidget);
      expect(find.textContaining('BPM'), findsNothing);
      expect(find.text('OTHER'), findsNothing);
    });

    testWidgets('renders searchSnippet instead of artist metadata when set', (
      tester,
    ) async {
      final song = tSong(
        id: 'song-3',
        title: 'Amazing Grace',
        bpm: 72,
        type: SongType.hymn,
      ).copyWith(searchSnippet: 'how sweet the sound');

      await _pumpSongListItem(tester, song: song);

      expect(find.text('“…how sweet the sound…”'), findsOneWidget);
      expect(find.textContaining('Bethel Music'), findsNothing);
      expect(find.text('HYMN'), findsNothing);
    });

    testWidgets('shows outline heart when song is not in favorites', (
      tester,
    ) async {
      final song = tSong(id: 'song-1');

      await _pumpSongListItem(tester, song: song, favorites: const []);

      expect(find.byIcon(Icons.favorite_border), findsOneWidget);
      expect(find.byIcon(Icons.favorite), findsNothing);
    });

    testWidgets('shows filled red heart when song is in favorites', (
      tester,
    ) async {
      final song = tSong(id: 'song-1');
      final fav = Favorite(
        userId: 'user-1',
        songId: 'song-1',
        createdAt: DateTime(2024, 1, 1),
      );

      await _pumpSongListItem(tester, song: song, favorites: [fav]);

      final icon = tester.widget<Icon>(find.byIcon(Icons.favorite));
      expect(icon.color, Colors.red);
      expect(find.byIcon(Icons.favorite_border), findsNothing);
    });

    testWidgets('invokes onTap and onLongPress callbacks', (tester) async {
      var tapped = false;
      var longPressed = false;
      final song = tSong(id: 'song-1');

      await _pumpSongListItem(
        tester,
        song: song,
        onTap: () => tapped = true,
        onLongPress: () => longPressed = true,
      );

      await tester.tap(find.text('Amazing Grace'));
      expect(tapped, isTrue);

      await tester.longPress(find.text('Amazing Grace'));
      expect(longPressed, isTrue);
    });
  });
}
