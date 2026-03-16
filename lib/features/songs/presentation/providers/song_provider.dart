import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/song_model.dart';
import '../../data/remote/songs_api.dart';
import '../../data/song_repository.dart';
import '../../../../core/config/supabase_config.dart';

// --- DATA LAYER ---
final songsApiProvider = Provider<SongsApi>((ref) {
  return SongsApi(ref.read(supabaseClientProvider));
});

final songRepositoryProvider = Provider<SongRepository>((ref) {
  return SongRepository(ref.read(songsApiProvider));
});

// --- RAW DATA PROVIDER ---
final songListProvider = FutureProvider<List<Song>>((ref) async {
  return ref.read(songRepositoryProvider).getSongs();
});

final songDetailProvider = FutureProvider.family<Song, String>((
  ref,
  songId,
) async {
  return ref.read(songRepositoryProvider).getSongById(songId);
});

final worshipSongsProvider = FutureProvider<List<Song>>((ref) async {
  final allSongs = await ref.watch(songListProvider.future);
  return allSongs.where((s) => s.type == SongType.worship).toList();
});

/// Shelf 2: High Praise (Hero Card)
final praiseSongsProvider = FutureProvider<List<Song>>((ref) async {
  final allSongs = await ref.watch(songListProvider.future);
  return allSongs.where((s) => s.type == SongType.praise).toList();
});

/// Shelf 3: Hymns
final hymnSongsProvider = FutureProvider<List<Song>>((ref) async {
  final allSongs = await ref.watch(songListProvider.future);
  return allSongs.where((s) => s.type == SongType.hymn).toList();
});

/// Shelf 4: Grouped by Key (For the "Build by Key" horizontal row)
final songsGroupedByKeyProvider = FutureProvider<Map<String, List<Song>>>((
  ref,
) async {
  final allSongs = await ref.watch(songListProvider.future);

  final Map<String, List<Song>> grouped = {};
  for (final song in allSongs) {
    // Treat null or empty keys as 'Unknown'
    final key = (song.key != null && song.key!.isNotEmpty)
        ? song.key!
        : 'Unknown';
    grouped.putIfAbsent(key, () => []);
    grouped[key]!.add(song);
  }
  return grouped;
});
