import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/core/utils/key_transposer.dart';
import 'package:worship_lamal/features/profile/presentation/providers/preferences_provider.dart';
import 'package:worship_lamal/features/songs/presentation/providers/song_filter_provider.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';

class SongPickerScreen extends ConsumerStatefulWidget {
  const SongPickerScreen({super.key});

  @override
  ConsumerState<SongPickerScreen> createState() => _SongPickerScreenState();
}

class _SongPickerScreenState extends ConsumerState<SongPickerScreen> {
  // Track selected IDs locally
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    // Clear any previous search queries so the list is full
    // We delay this to avoid "cannot modify provider during build" errors
    Future.microtask(() => ref.read(searchQueryProvider.notifier).clear());
  }

  @override
  Widget build(BuildContext context) {
    final songsAsync = ref.watch(filteredSongsProvider);

    final prefs = ref.watch(preferencesProvider);
    final isFemaleMode = prefs.vocalMode == VocalMode.female;

    return Scaffold(
      appBar: AppBar(
        title: Text('Select Songs (${_selectedIds.length})'),
        actions: [
          TextButton(
            onPressed: _selectedIds.isEmpty
                ? null
                : () {
                    // Return the list of IDs back to the previous screen
                    context.pop(_selectedIds.toList());
                  },
            child: const Text(
              'Done',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) =>
                  ref.read(searchQueryProvider.notifier).setQuery(val),
              decoration: const InputDecoration(
                hintText: 'Search library...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          // List
          Expanded(
            child: songsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (songs) {
                if (songs.isEmpty) {
                  return const Center(child: Text("No songs found"));
                }

                return ListView.separated(
                  itemCount: songs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    final isSelected = _selectedIds.contains(song.id);

                    final originalKey = song.key ?? '';
                    final displayKey = isFemaleMode
                        ? KeyTransposer.transpose(originalKey, -5)
                        : originalKey;

                    return CheckboxListTile(
                      value: isSelected,
                      activeColor: AppColors.primary,
                      title: Text(
                        song.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${song.artistNames} • $displayKey',
                        style: TextStyle(
                          color: isFemaleMode
                              ? AppColors.keyBadgeTransposedText
                              : null,
                        ),
                      ),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedIds.add(song.id);
                          } else {
                            _selectedIds.remove(song.id);
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
