import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // REQUIRED for Clipboard
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/features/songs/data/models/setlist_model.dart';
import 'package:worship_lamal/features/setlists/presentation/providers/setlist_provider.dart';
import 'package:worship_lamal/features/setlists/presentation/screens/setlist_details/empty.dart';
import 'package:worship_lamal/features/setlists/presentation/screens/setlist_details/header.dart';
import 'package:worship_lamal/features/setlists/presentation/screens/setlist_details/item_card.dart';

class SetlistDetailScreen extends ConsumerWidget {
  final String setlistId;

  const SetlistDetailScreen({super.key, required this.setlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Fetch the specific setlist details
    final setlistAsync = ref.watch(setlistDetailProvider(setlistId));
    final followedListAsync = ref.watch(followedSetlistsProvider);

    // Calculate "Is Following" (safely handle async data)
    final isFollowing =
        followedListAsync.asData?.value.any((s) => s.id == setlistId) ?? false;

    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return setlistAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (setlist) {
        if (setlist == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Unavailable")),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("Setlist Not Found or Private"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.pop(),
                    child: const Text("Go Back"),
                  ),
                ],
              ),
            ),
          );
        }
        // Check Ownership
        final isOwner = setlist.userId == currentUserId;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Setlist Details'),
            actions: [
              if (isOwner)
                IconButton(
                  // Icon changes based on status: Link if public, Share (or Lock) if private
                  icon: Icon(setlist.isPublic ? Icons.link : Icons.share),
                  tooltip: 'Share Setlist',
                  onPressed: () {
                    _showShareDialog(context, ref, setlist);
                  },
                ),

              // Option to edit/delete (Existing)
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // TODO: Implement Edit/Delete options
                },
              ),
            ],
          ),
          floatingActionButton: isOwner
              ? FloatingActionButton.extended(
                  label: const Text('Add Songs'),
                  icon: const Icon(Icons.add),
                  onPressed: () async {
                    // 1. Get current list length
                    int nextOrderIndex = (setlist.items.length) + 1;

                    // 2. Open Picker
                    final List<String>? selectedIds = await context
                        .pushNamed<List<String>>('songPicker');

                    if (selectedIds != null && selectedIds.isNotEmpty) {
                      // 3. Loop and Add
                      final controller = ref.read(
                        setlistControllerProvider.notifier,
                      );

                      for (final songId in selectedIds) {
                        await controller.addSong(
                          setlistId: setlistId,
                          songId: songId,
                          order: nextOrderIndex,
                        );
                        nextOrderIndex++;
                      }

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added ${selectedIds.length} songs'),
                          ),
                        );
                      }
                    }
                  },
                )
              : null, // Hide FAB for guests
          body: Builder(
            builder: (context) {
              if (setlist.items.isEmpty) {
                return EmptySetlistState(title: setlist.title);
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SetlistHeader(setlist: setlist),

                  // FOLLOW BUTTON SECTION (For Non-Owners)
                  if (!isOwner)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      color: Theme.of(context).colorScheme.surface,
                      child: isFollowing
                          ? OutlinedButton.icon(
                              onPressed: () {
                                ref
                                    .read(setlistControllerProvider.notifier)
                                    .toggleFollow(
                                      setlistId: setlist.id,
                                      isCurrentlyFollowing: true,
                                    );
                              },
                              icon: const Icon(Icons.check),
                              label: const Text(
                                "Following (Updates Automatically)",
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green,
                                side: const BorderSide(color: Colors.green),
                              ),
                            )
                          : ElevatedButton.icon(
                              onPressed: () {
                                ref
                                    .read(setlistControllerProvider.notifier)
                                    .toggleFollow(
                                      setlistId: setlist.id,
                                      isCurrentlyFollowing: false,
                                    );
                              },
                              icon: const Icon(Icons.bookmark_add_outlined),
                              label: const Text("Follow this Setlist"),
                            ),
                    ),

                  // LIST VIEW
                  Expanded(
                    child: isOwner
                        ? _buildOwnerList(context, ref, setlist)
                        : _buildViewerList(context, ref, setlist),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// SHARE DIALOG LOGIC
// ---------------------------------------------------------------------------
void _showShareDialog(BuildContext context, WidgetRef ref, Setlist setlist) {
  // Construct the deep link (Replace with your actual domain scheme)
  final link = "worship-lamal-f1b1c.web.app/setlist/${setlist.id}";

  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Allow it to expand if needed
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              setlist.isPublic ? "Share Setlist" : "Make Public & Share?",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            if (!setlist.isPublic) ...[
              const Text(
                "This setlist is currently Private. To share it, it must be made Public (view-only). You can make it Private again later.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.public),
                  label: const Text("Make Public & Copy Link"),
                  onPressed: () async {
                    // 1. UPDATE DB: Unlock the list
                    final repo = ref.read(setlistRepositoryProvider);
                    // Ensure you have this method in your repository!
                    await repo.updateSetlistPublicStatus(setlist.id, true);

                    // 2. COPY LINK
                    await Clipboard.setData(ClipboardData(text: link));

                    // 3. REFRESH UI & CLOSE
                    ref.invalidate(setlistDetailProvider(setlist.id));
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Link copied! Setlist is now Public."),
                        ),
                      );
                    }
                  },
                ),
              ),
            ] else ...[
              // ALREADY PUBLIC: Show the Link and Copy option
              const Text(
                "Anyone with this link can view this setlist and follow updates.",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        link,
                        style: TextStyle(color: Colors.grey.shade800),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      tooltip: "Copy Link",
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: link));
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Link copied to clipboard!"),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () async {
                    // MAKE PRIVATE AGAIN
                    final repo = ref.read(setlistRepositoryProvider);
                    await repo.updateSetlistPublicStatus(setlist.id, false);

                    ref.invalidate(setlistDetailProvider(setlist.id));
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Setlist is now Private."),
                        ),
                      );
                    }
                  },
                  child: const Text("Stop Sharing (Make Private)"),
                ),
              ),
            ],
            // Add some bottom padding for safety
            const SizedBox(height: 16),
          ],
        ),
      );
    },
  );
}

Widget _buildOwnerList(BuildContext context, WidgetRef ref, Setlist setlist) {
  return ReorderableListView.builder(
    padding: const EdgeInsets.only(bottom: 80),
    itemCount: setlist.items.length,

    buildDefaultDragHandles: false,

    // 1. The Reorder Callback
    onReorder: (oldIndex, newIndex) {
      ref
          .read(setlistControllerProvider.notifier)
          .reorderSongs(
            setlistId: setlist.id,
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
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
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
          final controller = ref.read(setlistControllerProvider.notifier);
          controller.removeSong(setlistId: setlist.id, item: item);

          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Removed "${item.song.title}"'),
              action: SnackBarAction(
                label: 'UNDO',
                onPressed: () {
                  controller.undoRemove(setlistId: setlist.id, item: item);
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
              setlist.id,
              item.displayKey,
            );
          },
        ),
      );
    },
  );
}

Widget _buildViewerList(BuildContext context, WidgetRef ref, Setlist setlist) {
  return ListView.builder(
    padding: const EdgeInsets.only(bottom: 80),
    itemCount: setlist.items.length,
    itemBuilder: (context, index) {
      final item = setlist.items[index];

      return SetlistItemCard(
        item: item,
        index: index,
        onTap: () => context.pushNamed(
          'songDetail',
          pathParameters: {'id': item.songId},
        ),
        // Maybe disable key editing too?
        onKeyTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Only the owner can change keys.")),
          );
        },
        // Hide Drag Handle
        showDragHandle: false,
      );
    },
  );
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
