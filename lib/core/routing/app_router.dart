import 'package:go_router/go_router.dart';

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
      ],
    ),
  ],
);
