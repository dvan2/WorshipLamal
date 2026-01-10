import '../../../songs/data/models/song_model.dart';

class Setlist {
  final String id;
  final String title;
  final DateTime createdAt;
  final bool isPublic;
  final List<SetlistItem> items;
  final String userId;

  Setlist({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.isPublic,
    required this.items,
    required this.userId,
  });

  factory Setlist.fromMap(Map<String, dynamic> map) {
    return Setlist(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      title: map['title'] ?? 'Untitled Setlist',
      createdAt: DateTime.parse(map['created_at']),
      isPublic: map['is_public'] ?? false,
      // Safely map the nested list of items
      items:
          (map['setlist_items'] as List<dynamic>?)
              ?.map((x) => SetlistItem.fromMap(x))
              .toList() ??
          [],
    );
  }

  Setlist copyWith({
    String? id,
    String? title,
    DateTime? createdAt,
    bool? isPublic,
    List<SetlistItem>? items,
    String? userId,
  }) {
    return Setlist(
      id: id ?? this.id,
      title: title ?? this.title,
      createdAt: createdAt ?? this.createdAt,
      isPublic: isPublic ?? this.isPublic,
      items: items ?? this.items,
      userId: userId ?? this.userId,
    );
  }
}

class SetlistItem {
  final String id;
  final String songId;
  final Song song;
  final String? keyOverride;
  final int sortOrder;

  SetlistItem({
    required this.id,
    required this.songId,
    required this.song,
    this.keyOverride,
    required this.sortOrder,
  });

  factory SetlistItem.fromMap(Map<String, dynamic> map) {
    return SetlistItem(
      id: map['id'] ?? '',
      songId: map['song_id'] ?? '',
      keyOverride: map['key_override'],
      sortOrder: map['sort_order'] ?? 0,
      // Map the nested 'song' object returned by Supabase
      song: Song.fromMap(map['songs'] as Map<String, dynamic>),
    );
  }

  SetlistItem copyWith({
    String? id,
    String? songId,
    Song? song,
    String? keyOverride,
    int? sortOrder,
  }) {
    return SetlistItem(
      id: id ?? this.id,
      songId: songId ?? this.songId,
      song: song ?? this.song,
      // Note: This pattern keeps the old value if you pass null.
      // If you specifically need to set keyOverride to null (remove the key),
      // you would need to recreate the object manually or use a specialized pattern.
      keyOverride: keyOverride ?? this.keyOverride,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  // Helper to show the correct key in the UI
  String get displayKey => keyOverride ?? song.key ?? 'Unknown';
}
