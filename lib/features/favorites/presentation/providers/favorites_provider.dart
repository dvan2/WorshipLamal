import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/features/favorites/data/model/favorite_model.dart';
import 'package:worship_lamal/features/favorites/data/remote/favorites_api.dart';
import 'package:worship_lamal/features/favorites/data/repositories/favorites_repository.dart';
import 'package:worship_lamal/features/profile/presentation/providers/auth_provider.dart';

// 1. DATA LAYER (Dependency Injection)

final favoritesApiProvider = Provider<FavoritesApi>((ref) {
  return FavoritesApi(Supabase.instance.client);
});

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  ref.watch(authStateProvider);
  final api = ref.watch(favoritesApiProvider);
  return FavoritesRepository(api);
});

// 2. READ ONLY PROVIDER (The List)

final favoritesListProvider = FutureProvider<List<Favorite>>((ref) async {
  final repo = ref.watch(favoritesRepositoryProvider);
  return repo.getFavorites();
});

class FavoriteController extends AsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Initial state is idle
  }

  /// Toggles the favorite status of a song
  Future<void> toggleFavorite({
    required String songId,
    required bool isCurrentlyFavorite,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(favoritesRepositoryProvider);

      if (isCurrentlyFavorite) {
        await repo.removeFavorite(songId);
      } else {
        await repo.addFavorite(songId);
      }

      // Refresh the list so the UI updates
      ref.invalidate(favoritesListProvider);
    });
  }
}

final favoriteControllerProvider =
    AsyncNotifierProvider<FavoriteController, void>(() {
      return FavoriteController();
    });
