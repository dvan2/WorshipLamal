import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worship_lamal/features/setlists/presentation/screens/widgets/song_picker_item.dart';
import 'package:worship_lamal/features/songs/presentation/providers/song_filter_provider.dart';
import 'package:worship_lamal/features/songs/presentation/widgets/song_search_field.dart';

class SongPickerScreen extends ConsumerStatefulWidget {
  // 1. Receive the list of IDs already in the setlist
  final List<String> existingSongIds;

  const SongPickerScreen({
    super.key,
    this.existingSongIds = const [], // Default to empty
  });

  @override
  ConsumerState<SongPickerScreen> createState() => _SongPickerScreenState();
}

class _SongPickerScreenState extends ConsumerState<SongPickerScreen> {
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(pickerSearchQueryProvider.notifier).clear(),
    );
    Future.microtask(() => ref.read(pickerFilterProvider.notifier).resetAll());
  }

  @override
  Widget build(BuildContext context) {
    // Relying on the personalized list provider (as we architected earlier!)
    final songsAsync = ref.watch(pickerFilteredSongsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Add Songs (${_selectedIds.length})'),
        actions: [
          TextButton(
            onPressed: _selectedIds.isEmpty
                ? null
                : () => context.pop(_selectedIds.toList()),
            child: const Text(
              'Done',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SongSearchField(
              searchProvider: pickerSearchQueryProvider,
              filterProvider: pickerFilterProvider,
            ),
          ),
          Expanded(
            child: songsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (songs) {
                if (songs.isEmpty) {
                  return const Center(child: Text("No songs found"));
                }

                return ListView.builder(
                  // We can remove the separator builder since SongPickerItem has good padding
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];

                    // 2. Check the lock state
                    final isAlreadyAdded = widget.existingSongIds.contains(
                      song.id,
                    );
                    final isSelected = _selectedIds.contains(song.id);

                    // 3. Render the new dedicated Picker Item
                    return SongPickerItem(
                      song: song,
                      isSelected: isSelected,
                      isAlreadyInSetlist: isAlreadyAdded,
                      onTap: () {
                        // Toggle logic handled cleanly here
                        setState(() {
                          if (isSelected) {
                            _selectedIds.remove(song.id);
                          } else {
                            _selectedIds.add(song.id);
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
