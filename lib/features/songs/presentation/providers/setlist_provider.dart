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
/// Usage: ref.watch(setlistsListProvider)
final setlistsListProvider = FutureProvider<List<Setlist>>((ref) async {
  final repo = ref.watch(setlistRepositoryProvider);
  return repo.getSetlists();
});

/// Fetches a SINGLE setlist with full details (lyrics, etc).
/// Usage: ref.watch(setlistDetailProvider(id))
final setlistDetailProvider = FutureProvider.family<Setlist, String>((
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

      state = const AsyncValue.data(null); // Set UI to success
      return newId;
    } catch (e, stack) {
      state = AsyncValue.error(e, stack); // Set UI to error
      debugPrint('Create Failed: $e');

      state = AsyncValue.error(e, stack);
      return null;
    }
  }

  /// Add a song to a setlist
  Future<void> addSong({
    required String setlistId,
    required String songId,
    required int order,
  }) async {
    state = const AsyncValue.loading();

    try {
      final repo = ref.read(setlistRepositoryProvider);
      await repo.addSong(setlistId: setlistId, songId: songId, order: order);

      // Refresh ONLY the detail view of this specific setlist
      ref.invalidate(setlistDetailProvider(setlistId));
      // Also refresh the main list (in case we show song counts there)
      ref.invalidate(setlistsListProvider);

      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}
