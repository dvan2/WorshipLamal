import 'package:worship_lamal/features/songs/data/models/lyric_line_model.dart';
import 'package:worship_lamal/features/songs/data/models/rhythm_chart_model.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/setlists/data/models/setlist_model.dart';

final tArtist = Artist(id: 'artist-1', name: 'Bethel Music');

LyricLine tLine({
  int n = 1,
  String section = 'chorus',
  String content = 'Amazing grace how sweet the sound',
  String? chordPro = '[G]Amazing [C]grace',
}) =>
    LyricLine(
      id: 'line-$n',
      content: content,
      lineNumber: n,
      sectionType: section,
      contentChordPro: chordPro,
    );

const Object _defaultDateSentinel = Object();

Song tSong({
  String id = 'song-1',
  String title = 'Amazing Grace',
  String? key = 'G',
  int? bpm = 72,
  SongType type = SongType.worship,
  List<String> themes = const ['Grace'],
  List<Artist>? artists,
  List<LyricLine>? lyricLines,
  List<RhythmChart>? rhythmCharts,
  Object? createdAt = _defaultDateSentinel,
}) =>
    Song(
      id: id,
      title: title,
      artists: artists ?? [tArtist],
      lyricLines: lyricLines ?? [tLine()],
      rhythmCharts: rhythmCharts ?? const [],
      key: key,
      bpm: bpm,
      type: type,
      themes: themes,
      createdAt: identical(createdAt, _defaultDateSentinel)
          ? DateTime(2024, 1, 1)
          : createdAt as DateTime?,
    );

SetlistItem tSetlistItem({
  String id = 'item-1',
  String songId = 'song-1',
  Song? song,
  String? keyOverride,
  int sortOrder = 0,
}) =>
    SetlistItem(
      id: id,
      songId: songId,
      song: song ?? tSong(id: songId),
      keyOverride: keyOverride,
      sortOrder: sortOrder,
    );

Setlist tSetlist({
  String id = 'setlist-1',
  String title = 'Sunday Service',
  String userId = 'user-1',
  bool isPublic = false,
  DateTime? createdAt,
  List<SetlistItem>? items,
}) =>
    Setlist(
      id: id,
      title: title,
      createdAt: createdAt ?? DateTime(2024, 6, 1),
      isPublic: isPublic,
      userId: userId,
      items: items ?? [tSetlistItem()],
    );
