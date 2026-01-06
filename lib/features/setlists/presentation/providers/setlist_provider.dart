import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/features/songs/data/models/setlist_model.dart';
import 'package:worship_lamal/features/songs/data/remote/setlists_api.dart';
import 'package:worship_lamal/features/songs/data/repositories/setlist_repository.dart';

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
      debugPrint('Create Failed: $e');

      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  Future<void> addSong({
    required String setlistId,
    required String songId,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repo = ref.read(setlistRepositoryProvider);

      final setlist = await repo.getSetlistById(setlistId);
      if (setlist == null) throw Exception("Setlist not found");
      final newOrder = setlist.items.length;

      await repo.addSong(setlistId: setlistId, songId: songId, order: newOrder);

      // 5. Refresh
      ref.invalidate(setlistDetailProvider(setlistId));
      ref.invalidate(setlistsListProvider);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateKeyOverride({
    required String setlistId,
    required String itemId,
    required String newKey,
  }) async {
    state = const AsyncValue.loading();

    try {
      // 2. Get the Repository using ref.read()
      final repo = ref.read(setlistRepositoryProvider);

      // 3. Call the Repository method
      await repo.updateKeyOverride(itemId, newKey);

      // 4. Refresh the UI
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
      // 2. Delete it immediately
      await repo.removeSong(item.id);

      // 3. Refresh UI
      ref.invalidate(setlistDetailProvider(setlistId));

      // 4. We don't set state to loading/error because this happens in the background
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
    // 1. Flutter Reorder Quirk Fix
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

final followedSetlistsProvider = FutureProvider<List<Setlist>>((ref) async {
  final repo = ref.watch(setlistRepositoryProvider);
  return repo.getFollowedSetlists();
});
