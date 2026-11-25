import 'package:flutter_test/flutter_test.dart';
import 'package:worship_lamal/features/setlists/data/models/setlist_model.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';

// ---------------------------------------------------------------------------
// Raw map helpers mirroring the Supabase join shape
// ---------------------------------------------------------------------------

Map<String, dynamic> _minimalSongMap({
  String id = 'song-1',
  String title = 'Amazing Grace',
  String? key = 'G',
}) => {
      'id': id,
      'title': title,
      'key': key,
      'bpm': null,
      'type': 'worship',
      'themes': <dynamic>[],
      'created_at': null,
      'song_artists': <dynamic>[],
      'lyric_lines': <dynamic>[],
      'rhythm_charts': <dynamic>[],
    };

Map<String, dynamic> _itemMap({
  String id = 'item-1',
  String songId = 'song-1',
  int sortOrder = 0,
  String? keyOverride,
  Map<String, dynamic>? song,
}) => {
      'id': id,
      'song_id': songId,
      'sort_order': sortOrder,
      'key_override': keyOverride,
      'songs': song ?? _minimalSongMap(id: songId),
    };

Map<String, dynamic> _setlistMap({
  String id = 'sl-1',
  String title = 'Sunday Service',
  String userId = 'user-1',
  bool isPublic = false,
  String createdAt = '2024-06-01T00:00:00.000Z',
  List<dynamic>? items,
}) => {
      'id': id,
      'title': title,
      'user_id': userId,
      'is_public': isPublic,
      'created_at': createdAt,
      'setlist_items': items,
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  group('Setlist.fromMap — scalar fields', () {
    test('parses id, title, userId, isPublic, createdAt', () {
      final sl = Setlist.fromMap(_setlistMap());

      expect(sl.id, 'sl-1');
      expect(sl.title, 'Sunday Service');
      expect(sl.userId, 'user-1');
      expect(sl.isPublic, isFalse);
      expect(sl.createdAt, DateTime.parse('2024-06-01T00:00:00.000Z'));
    });

    test('isPublic = true is preserved', () {
      final sl = Setlist.fromMap(_setlistMap(isPublic: true));
      expect(sl.isPublic, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  group('Setlist.fromMap — null/missing-field safety', () {
    test('null id falls back to empty string', () {
      final map = _setlistMap();
      map['id'] = null;
      final sl = Setlist.fromMap(map);
      expect(sl.id, '');
    });

    test('null title falls back to "Untitled Setlist"', () {
      final map = _setlistMap();
      map['title'] = null;
      final sl = Setlist.fromMap(map);
      expect(sl.title, 'Untitled Setlist');
    });

    test('null setlist_items → empty items list', () {
      final sl = Setlist.fromMap(_setlistMap(items: null));
      expect(sl.items, isEmpty);
    });

    test('empty setlist_items array → empty items list', () {
      final sl = Setlist.fromMap(_setlistMap(items: []));
      expect(sl.items, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  group('Setlist.fromMap — nested SetlistItem parsing', () {
    test('single item is parsed with correct fields', () {
      final sl = Setlist.fromMap(_setlistMap(items: [_itemMap()]));

      expect(sl.items, hasLength(1));
      final item = sl.items.first;
      expect(item.id, 'item-1');
      expect(item.songId, 'song-1');
      expect(item.sortOrder, 0);
      expect(item.keyOverride, isNull);
    });

    test('nested song inside item is parsed', () {
      final sl = Setlist.fromMap(_setlistMap(items: [_itemMap()]));
      expect(sl.items.first.song.title, 'Amazing Grace');
      expect(sl.items.first.song.key, 'G');
    });

    test('keyOverride is propagated correctly', () {
      final item = _itemMap(keyOverride: 'Bb');
      final sl = Setlist.fromMap(_setlistMap(items: [item]));
      expect(sl.items.first.keyOverride, 'Bb');
    });

    test('multiple items are all parsed', () {
      final sl = Setlist.fromMap(_setlistMap(items: [
        _itemMap(id: 'item-1', sortOrder: 0),
        _itemMap(id: 'item-2', sortOrder: 1, songId: 'song-2',
            song: _minimalSongMap(id: 'song-2', title: 'Holy Spirit')),
      ]));

      expect(sl.items, hasLength(2));
      expect(sl.items[1].song.title, 'Holy Spirit');
    });
  });

  // -------------------------------------------------------------------------
  group('SetlistItem — sortOrder ordering', () {
    test('items retain their parsed sortOrder values', () {
      final sl = Setlist.fromMap(_setlistMap(items: [
        _itemMap(id: 'a', sortOrder: 2),
        _itemMap(id: 'b', sortOrder: 0),
        _itemMap(id: 'c', sortOrder: 1),
      ]));

      // fromMap does NOT auto-sort; we verify raw parsed values
      final orders = sl.items.map((i) => i.sortOrder).toList();
      expect(orders, [2, 0, 1]);
    });

    test('items can be sorted by sortOrder ascending', () {
      final sl = Setlist.fromMap(_setlistMap(items: [
        _itemMap(id: 'a', sortOrder: 2),
        _itemMap(id: 'b', sortOrder: 0),
        _itemMap(id: 'c', sortOrder: 1),
      ]));

      final sorted = [...sl.items]
        ..sort((x, y) => x.sortOrder.compareTo(y.sortOrder));
      expect(sorted.map((i) => i.sortOrder).toList(), [0, 1, 2]);
      expect(sorted.map((i) => i.id).toList(), ['b', 'c', 'a']);
    });

    test('null sort_order falls back to 0', () {
      final item = {
        'id': 'x',
        'song_id': 'song-1',
        'sort_order': null,
        'key_override': null,
        'songs': _minimalSongMap(),
      };
      final sl = Setlist.fromMap(_setlistMap(items: [item]));
      expect(sl.items.first.sortOrder, 0);
    });
  });

  // -------------------------------------------------------------------------
  group('SetlistItem.fromMap — field-level', () {
    test('null id falls back to empty string', () {
      final item = _itemMap();
      item['id'] = null;
      final parsed = SetlistItem.fromMap(item);
      expect(parsed.id, '');
    });

    test('null song_id falls back to empty string', () {
      final item = _itemMap();
      item['song_id'] = null;
      final parsed = SetlistItem.fromMap(item);
      expect(parsed.songId, '');
    });
  });

  // -------------------------------------------------------------------------
  group('SetlistItem.displayKey', () {
    test('returns keyOverride when present', () {
      final item = SetlistItem(
        id: 'i1',
        songId: 'song-1',
        song: Song(
            id: 'song-1', title: 'T', artists: const [], lyricLines: const [],
            key: 'G'),
        keyOverride: 'Bb',
        sortOrder: 0,
      );
      expect(item.displayKey, 'Bb');
    });

    test('returns song.key when keyOverride is null', () {
      final item = SetlistItem(
        id: 'i1',
        songId: 'song-1',
        song: Song(
            id: 'song-1', title: 'T', artists: const [], lyricLines: const [],
            key: 'D'),
        sortOrder: 0,
      );
      expect(item.displayKey, 'D');
    });

    test('returns "Unknown" when both keyOverride and song.key are null', () {
      final item = SetlistItem(
        id: 'i1',
        songId: 'song-1',
        song: Song(
            id: 'song-1', title: 'T', artists: const [], lyricLines: const []),
        sortOrder: 0,
      );
      expect(item.displayKey, 'Unknown');
    });
  });
}
