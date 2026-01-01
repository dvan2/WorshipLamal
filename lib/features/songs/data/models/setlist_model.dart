import './song_model.dart';

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

  // Helper to show the correct key in the UI
  String get displayKey => keyOverride ?? song.key ?? 'Unknown';
}
