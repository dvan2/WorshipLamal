import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

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

// lib/features/songs/providers/song_provider.dart

// 1. Holds the current search text
final searchQueryProvider = StateProvider<String>((ref) => '');

// 2. Computes the filtered list automatically
final filteredSongsProvider = Provider<AsyncValue<List<Song>>>((ref) {
  // Watch the raw data from the database
  final songsAsync = ref.watch(songListProvider);
  // Watch the search text
  final query = ref.watch(searchQueryProvider).toLowerCase();

  // "whenData" maps the data if it exists, but keeps Loading/Error states intact
  return songsAsync.whenData((songs) {
    if (query.isEmpty) return songs;

    return songs.where((song) {
      final titleMatch = song.title.toLowerCase().contains(query);
      final artistMatch = song.artistNames.toLowerCase().contains(query);
      final keyMatch = song.key?.toLowerCase().contains(query) ?? false;

      return titleMatch || artistMatch || keyMatch;
    }).toList();
  });
});
