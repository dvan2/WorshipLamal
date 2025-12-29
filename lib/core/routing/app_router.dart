import 'package:go_router/go_router.dart';
import 'package:worship_lamal/features/songs/presentation/screens/setlist_detail_screen.dart';

import '../../features/songs/presentation/screens/home_screen.dart';
import '../../features/songs/presentation/screens/song_detail_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
      routes: [
        GoRoute(
          path: 'song/:id',
          name: 'songDetail',
          builder: (context, state) {
            final songId = state.pathParameters['id']!;
            return SongDetailScreen(songId: songId);
          },
        ),
        GoRoute(
          path: 'setlist/:id',
          name: 'setlistDetail',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            // We will build this screen next!
            return SetlistDetailScreen(setlistId: id);
          },
        ),
      ],
    ),
  ],
);
