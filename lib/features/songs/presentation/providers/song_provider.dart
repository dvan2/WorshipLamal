import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/core/utils/key_transposer.dart';
import 'package:worship_lamal/features/profile/presentation/providers/preferences_provider.dart';
import 'package:worship_lamal/features/userkey/presentation/providers/user_keys_provider.dart';

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

final personalizedSongListProvider = Provider<AsyncValue<List<Song>>>((ref) {
  final rawSongsAsync = ref.watch(songListProvider);
  final userKeysMap = ref.watch(userPreferredKeysMapProvider);
  final prefs = ref.watch(preferencesProvider);

  return rawSongsAsync.whenData((rawSongs) {
    // 3. Loop through every song and inject the user's preferred key
    return rawSongs.map((song) {
      String effectiveKey = song.key ?? '';

      // Apply the exact same priority logic we used before
      if (userKeysMap.containsKey(song.id)) {
        effectiveKey = userKeysMap[song.id]!;
      } else if (prefs.vocalMode == VocalMode.female &&
          effectiveKey.isNotEmpty) {
        effectiveKey = KeyTransposer.transpose(effectiveKey, -5);
      }

      if (effectiveKey.isEmpty) effectiveKey = 'Unknown';

      // 4. THE MAGIC: Return a cloned Song object with the new key permanently attached!
      return song.copyWith(key: effectiveKey);
    }).toList();
  });
});
