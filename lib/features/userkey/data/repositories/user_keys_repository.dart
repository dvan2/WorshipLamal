import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/features/userkey/data/model/user_key_model.dart';
import '../remote/user_keys_api.dart';

class UserKeysRepository {
  final UserKeysApi _api;

  UserKeysRepository(this._api);

  String get _currentUserId {
    final id = Supabase.instance.client.auth.currentUser?.id;
    if (id == null) {
      throw Exception('User must be logged in to manage keys');
    }
    return id;
  }

  Future<List<UserKey>> getAllKeys() async {
    final id = Supabase.instance.client.auth.currentUser?.id;
    if (id == null) return [];
    return _api.fetchUserKeys(id);
  }

  Future<void> setKey(String songId, String key) async {
    return _api.setUserKey(_currentUserId, songId, key);
  }

  Future<void> revertKey(String songId) async {
    return _api.deleteUserKey(_currentUserId, songId);
  }
}
