class UserKey {
  final String userId;
  final String songId;
  final String preferredKey;

  UserKey({
    required this.userId,
    required this.songId,
    required this.preferredKey,
  });

  factory UserKey.fromMap(Map<String, dynamic> map) {
    return UserKey(
      userId: map['user_id'] as String,
      songId: map['song_id'] as String,
      preferredKey: map['preferred_key'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'song_id': songId,
      'preferred_key': preferredKey,
    };
  }
}
