import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:worship_lamal/features/songs/presentation/providers/song_filter_provider.dart';

import '../../data/models/song_model.dart';
import '../../data/remote/songs_api.dart';
import '../../data/song_repository.dart';
import '../../../../core/config/supabase_config.dart';

final songsApiProvider = Provider<SongsApi>((ref) {
  return SongsApi(ref.read(supabaseClientProvider));
});

final songRepositoryProvider = Provider<SongRepository>((ref) {
  return SongRepository(ref.read(songsApiProvider));
});

final songListProvider = FutureProvider<List<Song>>((ref) async {
  return ref.read(songRepositoryProvider).getSongs();
});

final songDetailProvider = FutureProvider.family<Song, String>((
  ref,
  songId,
) async {
  return ref.read(songRepositoryProvider).getSongById(songId);
});

// 1. Holds the current search text
final searchQueryProvider = StateProvider<String>((ref) => '');

final filteredSongsProvider = FutureProvider<List<Song>>((ref) async {
  // 1. Watch all inputs
  final allSongs = await ref.watch(songListProvider.future);

  final query = ref.watch(searchQueryProvider).toLowerCase();
  final filters = ref.watch(songFilterProvider);

  // 2. Apply Logic
  return allSongs.where((song) {
    // A. Text Search
    final matchesText =
        song.title.toLowerCase().contains(query) ||
        // Check your model: is it artistName or artistNames?
        // Using artistNames based on your previous code comments.
        (song.artistNames).toLowerCase().contains(query);

    if (!matchesText) return false;

    // B. Key Filter
    if (filters.selectedKeys.isNotEmpty) {
      if (!filters.selectedKeys.contains(song.key)) return false;
    }

    // C. BPM Filter
    if (song.bpm != null) {
      if (song.bpm! < filters.bpmRange.start ||
          song.bpm! > filters.bpmRange.end) {
        return false;
      }
    }

    return true;
  }).toList();
});
