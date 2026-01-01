import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worship_lamal/features/songs/presentation/providers/setlist_provider.dart';
import 'package:worship_lamal/features/songs/presentation/widgets/song_details/empty_setlist_state.dart';
import 'package:worship_lamal/features/songs/presentation/widgets/song_details/setlist_header.dart';
import 'package:worship_lamal/features/songs/presentation/widgets/song_details/setlist_item_card.dart';

class SetlistDetailScreen extends ConsumerWidget {
  final String setlistId;

  const SetlistDetailScreen({super.key, required this.setlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Fetch the specific setlist details
    final setlistAsync = ref.watch(setlistDetailProvider(setlistId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setlist Details'),
        actions: [
          // Option to edit the setlist title or delete it
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {
              // TODO: Implement Edit/Delete/Share options
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text('Add Songs'),
        icon: const Icon(Icons.add),
        onPressed: () async {
          // 1. Get the current list length to determine sort order
          // We use .valueOrNull because we might be in loading state,
          // but usually the data is there if we are clicking the FAB.
          final currentSetlist = setlistAsync.asData?.value;
          int nextOrderIndex = (currentSetlist?.items.length ?? 0) + 1;

          // 2. Open the Picker and wait for results
          final List<String>? selectedIds = await context
              .pushNamed<List<String>>('songPicker');

          if (selectedIds != null && selectedIds.isNotEmpty) {
            // 3. Loop through and add them
            final controller = ref.read(setlistControllerProvider.notifier);

            for (final songId in selectedIds) {
              await controller.addSong(
                setlistId: setlistId,
                songId: songId,
                order: nextOrderIndex,
              );
              nextOrderIndex++;
            }

            // Show confirmation
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added ${selectedIds.length} songs')),
              );
            }
          }
        },
      ),

      body: setlistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (setlist) {
          if (setlist.items.isEmpty) {
            return EmptySetlistState(title: setlist.title);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SetlistHeader(setlist: setlist),
              Expanded(
                child: ReorderableListView.builder(
                  padding: const EdgeInsets.only(bottom: 80),
                  itemCount: setlist.items.length,

                  buildDefaultDragHandles: false,

                  // 1. The Reorder Callback
                  onReorder: (oldIndex, newIndex) {
                    ref
                        .read(setlistControllerProvider.notifier)
                        .reorderSongs(
                          setlistId: setlistId,
                          currentList: setlist.items,
                          oldIndex: oldIndex,
                          newIndex: newIndex,
                        );
                  },

                  // 2. The Item Builder
                  itemBuilder: (context, index) {
                    final item = setlist.items[index];

                    // NOTE: Each item in ReorderableListView MUST have a Key
                    return Dismissible(
                      key: ValueKey(item.id), // Key goes here!
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        margin: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete_outline,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      onDismissed: (direction) {
                        final controller = ref.read(
                          setlistControllerProvider.notifier,
                        );
                        controller.removeSong(setlistId: setlistId, item: item);

                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Removed "${item.song.title}"'),
                            action: SnackBarAction(
                              label: 'UNDO',
                              onPressed: () {
                                controller.undoRemove(
                                  setlistId: setlistId,
                                  item: item,
                                );
                              },
                            ),
                          ),
                        );
                      },
                      child: SetlistItemCard(
                        item: item,
                        index: index,
                        onTap: () {
                          context.pushNamed(
                            'songDetail',
                            pathParameters: {'id': item.songId},
                          );
                        },
                        onKeyTap: () {
                          _showKeyPickerDialog(
                            context,
                            ref,
                            item.id,
                            setlistId,
                            item.displayKey,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

void _showKeyPickerDialog(
  BuildContext context,
  WidgetRef ref,
  String itemId,
  String setlistId,
  String currentKey,
) {
  final keys = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Change Key'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: keys.map((key) {
            final isSelected = key == currentKey;
            return ChoiceChip(
              label: Text(key),
              selected: isSelected,
              onSelected: (selected) async {
                if (selected) {
                  // 1. Close Dialog first for responsiveness
                  Navigator.pop(context);

                  // 2. Call Controller
                  await ref
                      .read(setlistControllerProvider.notifier)
                      .updateKeyOverride(
                        setlistId: setlistId,
                        itemId: itemId,
                        newKey: key,
                      );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Key changed to $key')),
                    );
                  }
                }
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}
