import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/features/userkey/data/model/user_key_model.dart';

class UserKeysApi {
  final SupabaseClient _client;

  UserKeysApi(this._client);

  /// Fetch all custom keys for a specific user
  Future<List<UserKey>> fetchUserKeys(String userId) async {
    final response = await _client
        .from('user_keys')
        .select()
        .eq('user_id', userId);

    return (response as List).map((item) => UserKey.fromMap(item)).toList();
  }

  /// Set (Insert or Update) a preferred key
  Future<void> setUserKey(String userId, String songId, String key) async {
    await _client.from('user_keys').upsert({
      'user_id': userId,
      'song_id': songId,
      'preferred_key': key,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Remove a preferred key (Revert to original)
  Future<void> deleteUserKey(String userId, String songId) async {
    await _client.from('user_keys').delete().match({
      'user_id': userId,
      'song_id': songId,
    });
  }
}
