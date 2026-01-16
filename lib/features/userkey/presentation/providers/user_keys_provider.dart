import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/features/userkey/data/model/user_key_model.dart';
import '../../data/remote/user_keys_api.dart';
import '../../data/repositories/user_keys_repository.dart';
import '../../../profile/presentation/providers/auth_provider.dart';

// -----------------------------------------------------------------------------
// 1. DATA LAYER INJECTION
// -----------------------------------------------------------------------------

final userKeysApiProvider = Provider<UserKeysApi>((ref) {
  return UserKeysApi(Supabase.instance.client);
});

final userKeysRepositoryProvider = Provider<UserKeysRepository>((ref) {
  ref.watch(authStateProvider); // Re-build if auth changes
  final api = ref.watch(userKeysApiProvider);
  return UserKeysRepository(api);
});

// -----------------------------------------------------------------------------
// 2. READ ONLY PROVIDERS
// -----------------------------------------------------------------------------

/// Raw fetch of the list
final userKeysListProvider = FutureProvider<List<UserKey>>((ref) async {
  final repo = ref.watch(userKeysRepositoryProvider);
  return repo.getAllKeys();
});

/// Optimized Map for UI Lookup: { 'songId': 'PreferredKey' }
final userPreferredKeysMapProvider = Provider<Map<String, String>>((ref) {
  final keysAsync = ref.watch(userKeysListProvider);

  return keysAsync.maybeWhen(
    data: (keys) {
      // Convert List to Map for O(1) lookup
      return {for (var k in keys) k.songId: k.preferredKey};
    },
    orElse: () => {},
  );
});

// -----------------------------------------------------------------------------
// 3. CONTROLLER (Mutations)
// -----------------------------------------------------------------------------

class UserKeyController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> setKey(String songId, String key) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(userKeysRepositoryProvider);
      await repo.setKey(songId, key);
      ref.invalidate(userKeysListProvider); // Refresh the map
    });
  }

  Future<void> revertKey(String songId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(userKeysRepositoryProvider);
      await repo.revertKey(songId);
      ref.invalidate(userKeysListProvider); // Refresh the map
    });
  }
}

final userKeyControllerProvider =
    AsyncNotifierProvider<UserKeyController, void>(() {
      return UserKeyController();
    });
