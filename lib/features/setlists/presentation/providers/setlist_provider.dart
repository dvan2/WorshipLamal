import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/core/utils/key_transposer.dart';
import 'package:worship_lamal/features/profile/presentation/providers/auth_provider.dart';
import 'package:worship_lamal/features/profile/presentation/providers/preferences_provider.dart';
import 'package:worship_lamal/features/setlists/data/models/setlist_model.dart';
import 'package:worship_lamal/features/setlists/data/remote/setlists_api.dart';
import 'package:worship_lamal/features/setlists/data/repositories/setlist_repository.dart';
import 'package:worship_lamal/features/songs/presentation/providers/song_provider.dart';

// -----------------------------------------------------------------------------
// 1. DATA LAYER (The Piping)
// -----------------------------------------------------------------------------

/// Provides the raw API client
final setlistsApiProvider = Provider<SetlistsApi>((ref) {
  // We assume Supabase is initialized in main.dart
  return SetlistsApi(Supabase.instance.client);
});

/// Provides the Repository (Dependent on API)
final setlistRepositoryProvider = Provider<SetlistRepository>((ref) {
  ref.watch(authStateProvider);
  final api = ref.watch(setlistsApiProvider);
  return SetlistRepository(api);
});

// -----------------------------------------------------------------------------
// 2. READ ONLY PROVIDERS (Fetching Data)
// -----------------------------------------------------------------------------

/// Fetches the list of all setlists.
final setlistsListProvider = FutureProvider<List<Setlist>>((ref) async {
  final repo = ref.watch(setlistRepositoryProvider);
  return repo.getSetlists();
});

/// Fetches a SINGLE setlist with full details (lyrics, etc).
final setlistDetailProvider = FutureProvider.family<Setlist?, String>((
  ref,
  id,
) async {
  final repo = ref.watch(setlistRepositoryProvider);
  return repo.getSetlistById(id);
});

final followedSetlistsProvider = FutureProvider<List<Setlist>>((ref) async {
  final repo = ref.watch(setlistRepositoryProvider);
  return repo.getFollowedSetlists();
});

// CONTROLLER (Mutations: Create, Add, Delete)
final setlistControllerProvider =
    AsyncNotifierProvider<SetlistController, void>(() {
      return SetlistController();
    });

class SetlistController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Initial state is idle
  }

  /// Create a new setlist and refresh the list
  Future<String?> createSetlist(String title) async {
    state = const AsyncValue.loading(); // Set UI to loading

    try {
      final repo = ref.read(setlistRepositoryProvider);
      final newId = await repo.createSetlist(title);

      // Force the list to re-fetch so the new setlist appears immediately
      ref.invalidate(setlistsListProvider);

      state = const AsyncValue.data(null);
      return newId;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);

      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  // In SetlistController class
  Future<void> addSongs({
    required String setlistId,
    required List<String> songIds,
  }) async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final repo = ref.read(setlistRepositoryProvider);
      final songRepo = ref.read(songRepositoryProvider);
      final prefs = ref.read(preferencesProvider);

      final itemsToAdd = <Map<String, dynamic>>[];

      for (final songId in songIds) {
        String? keyToSave;

        if (prefs.vocalMode == VocalMode.female) {
          final song = await songRepo.getSongById(songId); // Fetch fresh data
          if (song.key != null) {
            keyToSave = KeyTransposer.transpose(song.key!, -5);
          }
        }

        itemsToAdd.add({
          'setlist_id': setlistId,
          'song_id': songId,
          'key': keyToSave,
        });
      }

      await repo.addSongsToSet(itemsToAdd);

      ref.invalidate(setlistDetailProvider(setlistId));
      ref.invalidate(setlistsListProvider);
    });
  }

  Future<void> updateKeyOverride({
    required String setlistId,
    required String itemId,
    required String newKey,
  }) async {
    try {
      final repo = ref.read(setlistRepositoryProvider);
      await repo.updateKeyOverride(itemId, newKey);
      ref.invalidate(setlistDetailProvider(setlistId));
    } catch (e) {
      debugPrint('Update Key Failed: $e');
    }
  }

  Future<void> removeSong({
    required String setlistId,
    required SetlistItem item,
  }) async {
    final repo = ref.read(setlistRepositoryProvider);

    try {
      await repo.removeSong(setlistId, item.id);

      ref.invalidate(setlistDetailProvider(setlistId));
      ref.invalidate(setlistsListProvider);
    } catch (e) {
      debugPrint('Delete failed: $e');
      ref.invalidate(setlistDetailProvider(setlistId));
    }
  }

  Future<void> reorderSongs({
    required String setlistId,
    required List<SetlistItem> currentList,
  }) async {
    try {
      final repo = ref.read(setlistRepositoryProvider);
      await repo.reorderSetlistItems(setlistId, currentList);

      ref.invalidate(setlistDetailProvider(setlistId));
    } catch (e) {
      debugPrint('Reorder failed: $e');
      ref.invalidate(setlistDetailProvider(setlistId));
    }
  }

  Future<void> toggleFollow({
    required String setlistId,
    required bool isCurrentlyFollowing,
  }) async {
    try {
      final repo = ref.read(setlistRepositoryProvider);

      if (isCurrentlyFollowing) {
        await repo.unfollowSetlist(setlistId);
      } else {
        await repo.followSetlist(setlistId);
      }

      ref.invalidate(followedSetlistsProvider);
    } catch (e, stack) {
      debugPrint('Toggle follow failed: $e');
      state = AsyncValue.error(e, stack);
    }
  }
}
