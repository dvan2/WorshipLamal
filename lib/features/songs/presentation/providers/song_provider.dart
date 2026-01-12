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
