import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/core/theme/app_theme.dart';
import 'package:worship_lamal/features/favorites/favorites_feature.dart';
import 'package:worship_lamal/features/songs/songs_feature.dart';
import 'core/routing/app_router.dart';

class WorshipLamal extends StatelessWidget {
  const WorshipLamal({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        favoriteSongIdsProvider.overrideWith((ref) {
          final favAsync = ref.watch(favoritesListProvider);
          return favAsync.whenData(
            (favs) => favs.map((f) => f.songId).toSet(),
          );
        }),
      ],
      child: MaterialApp.router(
        routerConfig: appRouter,
        theme: AppTheme.lightTheme,
      ),
    );
  }
}
