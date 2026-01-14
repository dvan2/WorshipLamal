import 'package:worship_lamal/features/songs/data/models/song_model.dart';

class Favorite {
  final String userId;
  final String songId;
  final DateTime createdAt;

  // Nullable because you might fetch just the IDs,
  // or you might fetch the full song details (Join).
  final Song? song;

  Favorite({
    required this.userId,
    required this.songId,
    required this.createdAt,
    this.song,
  });

  factory Favorite.fromMap(Map<String, dynamic> map) {
    return Favorite(
      userId: map['user_id'] as String,
      songId: map['song_id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),

      // SUPABASE MAGIC:
      // If you query .select('*, songs(*)') Supabase returns the
      // song data nested under the key 'songs'.
      song: map['songs'] != null
          ? Song.fromMap(map['songs'] as Map<String, dynamic>)
          : null,
    );
  }
}
