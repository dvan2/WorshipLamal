import 'package:go_router/go_router.dart';
import 'package:worship_lamal/features/setlists/presentation/screens/setlist_details/screen.dart';
import 'package:worship_lamal/features/setlists/presentation/screens/setlist_details/song_picker_screen.dart';

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
            final overrideKey = state.uri.queryParameters['key'];
            return SongDetailScreen(songId: songId, overrideKey: overrideKey);
          },
        ),
        GoRoute(
          path: 'setlist/:id',
          name: 'setlistDetail',
          builder: (context, state) {
            final id = state.pathParameters['id']!;

            final autoFollowParam = state.uri.queryParameters['auto_follow'];
            final shouldAutoFollow = autoFollowParam == 'true';
            // We will build this screen next!
            return SetlistDetailScreen(
              setlistId: id,
              autoFollow: shouldAutoFollow,
            );
          },
        ),
        GoRoute(
          path: 'song-picker',
          name: 'songPicker',
          builder: (context, state) => const SongPickerScreen(),
        ),
      ],
    ),
  ],
);
