import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/song_provider.dart';

class SongDetailScreen extends ConsumerWidget {
  final String songId;

  const SongDetailScreen({super.key, required this.songId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songAsync = ref.watch(songDetailProvider(songId));

    return Scaffold(
      appBar: AppBar(title: const Text('Song')),
      body: songAsync.when(
        data: (song) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                song.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Text(song.artist, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  children: song.lyricLines
                      .map(
                        (line) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(line.content),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(err.toString())),
      ),
    );
  }
}
