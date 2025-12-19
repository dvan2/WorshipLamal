import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/song_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(songListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Worship Lamal')),
      body: songsAsync.when(
        data: (songs) => ListView.builder(
          itemCount: songs.length,
          itemBuilder: (context, index) {
            final song = songs[index];
            return ListTile(
              title: Text(song.title),
              subtitle: Text(song.artist),
              onTap: () {
                context.goNamed('songDetail', pathParameters: {'id': song.id});
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
      ),
    );
  }
}
