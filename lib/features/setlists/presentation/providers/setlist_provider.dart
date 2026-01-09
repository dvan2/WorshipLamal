import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/core/utils/key_transposer.dart';
import 'package:worship_lamal/features/profile/presentation/providers/preferences_provider.dart';
import 'package:worship_lamal/features/songs/data/models/setlist_model.dart';
import 'package:worship_lamal/features/songs/data/remote/setlists_api.dart';
import 'package:worship_lamal/features/songs/data/repositories/setlist_repository.dart';
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

// -----------------------------------------------------------------------------
// 3. CONTROLLER (Mutations: Create, Add, Delete)
// -----------------------------------------------------------------------------

/// Manages actions like "Create Setlist" or "Add Song".
/// It handles the Loading state for your UI buttons automatically.
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

  Future<void> addSong({
    required String setlistId,
    required String songId,
    String? keyOverride,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repo = ref.read(setlistRepositoryProvider);

      final setlist = await repo.getSetlistById(setlistId);
      if (setlist == null) throw Exception("Setlist not found");
      final newOrder = setlist.items.length;

      await repo.addSong(
        setlistId: setlistId,
        songId: songId,
        order: newOrder,
        keyOverride: keyOverride,
      );

      // 5. Refresh
      ref.invalidate(setlistDetailProvider(setlistId));
      ref.invalidate(setlistsListProvider);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
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
      final songRepo = ref.read(songRepositoryProvider); // Use repo to be safe
      final prefs = ref.read(preferencesProvider);

      // 1. Fetch song details needed for transposition (safer than reading list provider)
      // You might need to implement getSongsByIds in your repo, or fetch individually in parallel.
      // For now, let's assume we can fetch them or just trust the logic.

      final itemsToAdd = <Map<String, dynamic>>[];

      for (final songId in songIds) {
        String? keyToSave;

        // Logic moved from UI to Controller
        if (prefs.vocalMode == VocalMode.female) {
          final song = await songRepo.getSongById(songId); // Fetch fresh data
          if (song.key != null) {
            keyToSave = KeyTransposer.transpose(song.key!, -5);
          }
        }

        itemsToAdd.add({
          'setlist_id': setlistId,
          'song_id': songId,
          'key': keyToSave, // The repo's add method needs to support this
        });
      }

      // 2. Perform BULK insert (Much faster)
      await repo.addSetlistItems(itemsToAdd);

      // 3. Refresh
      ref.invalidate(setlistDetailProvider(setlistId));
    });
  }

  Future<void> updateKeyOverride({
    required String setlistId,
    required String itemId,
    required String newKey,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repo = ref.read(setlistRepositoryProvider);

      await repo.updateKeyOverride(itemId, newKey);

      ref.invalidate(setlistDetailProvider(setlistId));

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      debugPrint('Update Key Failed: $e');
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> removeSong({
    required String setlistId,
    required SetlistItem
    item, // We pass the whole item so we can restore it if needed
  }) async {
    // 1. Keep a backup in memory for the Undo action
    final repo = ref.read(setlistRepositoryProvider);

    try {
      await repo.removeSong(item.id);

      ref.invalidate(setlistDetailProvider(setlistId));

      // don't set state to loading/error because this happens in the background
      // while the user sees the row disappear.
    } catch (e) {
      debugPrint('Delete failed: $e');
    }
  }

  Future<void> undoRemove({
    required String setlistId,
    required SetlistItem item,
  }) async {
    // Re-add the song with its original sort order
    await addSong(setlistId: setlistId, songId: item.songId);
  }

  Future<void> reorderSongs({
    required String setlistId,
    required List<SetlistItem> currentList,
    required int oldIndex,
    required int newIndex,
  }) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    // 2. Modify the list locally (create a copy to be safe)
    final items = List<SetlistItem>.from(currentList);
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);

    // 3. Update Database
    // We send the ENTIRE re-sorted list to the repo.
    // The repo will assign sort_order: 0 to the first item, 1 to the second, etc.
    final repo = ref.read(setlistRepositoryProvider);

    // Optimistically refresh the UI?
    // Ideally, we'd update the local state immediately, but for now
    // we'll just fire the API call and invalidate.
    try {
      await repo.reorderSetlistItems(setlistId, items);
      ref.invalidate(setlistDetailProvider(setlistId));
    } catch (e) {
      debugPrint('Reorder failed: $e');
    }
  }

  // FOLLOWED SETLISTS PROVIDER

  /// Toggle the follow status of a setlist
  Future<void> toggleFollow({
    required String setlistId,
    required bool isCurrentlyFollowing,
  }) async {
    // 1. Optimistic Update or Loading State?
    // Since this is a simple toggle, we usually don't need a full loading screen,
    // but preventing double-taps is good.

    try {
      final repo = ref.read(setlistRepositoryProvider);

      if (isCurrentlyFollowing) {
        await repo.unfollowSetlist(setlistId);
      } else {
        await repo.followSetlist(setlistId);
      }

      // 2. Refresh the list of followed setlists
      // This will automatically update the UI button state because the UI watches this list.
      ref.invalidate(followedSetlistsProvider);
    } catch (e, stack) {
      debugPrint('Toggle follow failed: $e');
      state = AsyncValue.error(e, stack);
    }
  }
}
