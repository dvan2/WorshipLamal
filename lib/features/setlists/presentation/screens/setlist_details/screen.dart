import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worship_lamal/features/setlists/presentation/providers/setlist_provider.dart';
import 'package:worship_lamal/features/setlists/presentation/screens/setlist_details/empty.dart';
import 'package:worship_lamal/features/setlists/presentation/screens/setlist_details/header.dart';
import 'package:worship_lamal/features/setlists/presentation/screens/setlist_details/setlist_owner_view.dart';
import 'package:worship_lamal/features/setlists/presentation/screens/setlist_details/setlist_share_sheet.dart';
import 'package:worship_lamal/features/setlists/presentation/screens/setlist_details/setlist_viewer_view.dart';
import 'package:worship_lamal/features/setlists/data/models/setlist_model.dart';

class SetlistDetailScreen extends ConsumerStatefulWidget {
  final String setlistId;
  final bool autoFollow;
  const SetlistDetailScreen({
    super.key,
    required this.setlistId,
    this.autoFollow = false,
  });

  @override
  ConsumerState<SetlistDetailScreen> createState() =>
      _SetlistDetailScreenState();
}

class _SetlistDetailScreenState extends ConsumerState<SetlistDetailScreen> {
  bool _hasAttemptedAutoFollow = false;

  @override
  Widget build(BuildContext context) {
    final setlistAsync = ref.watch(setlistDetailProvider(widget.setlistId));
    final followedAsync = ref.watch(followedSetlistsProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (widget.autoFollow && !_hasAttemptedAutoFollow) {
      // We need both the Setlist AND the Followed List to be loaded to make a decision
      if (setlistAsync.hasValue && followedAsync.hasValue) {
        final setlist = setlistAsync.value;
        final followedList = followedAsync.value ?? [];

        if (setlist != null) {
          final isOwner = setlist.userId == currentUserId;
          final isAlreadyFollowing = followedList.any(
            (s) => s.id == setlist.id,
          );

          // Only follow if: NOT owner AND NOT already following
          if (!isOwner && !isAlreadyFollowing) {
            // Mark as attempted immediately so we don't loop
            _hasAttemptedAutoFollow = true;

            // Schedule the state change for after the build frame
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref
                  .read(setlistControllerProvider.notifier)
                  .toggleFollow(
                    setlistId: setlist.id,
                    isCurrentlyFollowing: false, // We know it's false
                  );

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("You are now following this setlist!"),
                ),
              );
            });
          } else {
            // If they are owner or already following, just mark as done
            _hasAttemptedAutoFollow = true;
          }
        }
      }
    }

    return setlistAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, _) => Scaffold(body: Center(child: Text('Error: $err'))),
      data: (setlist) {
        if (setlist == null) return _buildNotFoundScreen(context);

        final isOwner = setlist.userId == currentUserId;
        final hasSongs = setlist.items.isNotEmpty;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Setlist Details'),
            actions: [
              if (isOwner)
                IconButton(
                  icon: Icon(setlist.isPublic ? Icons.link : Icons.share),
                  onPressed: () => showSetlistShareSheet(context, ref, setlist),
                ),
              // Optional: Edit/Delete Menu
              if (isOwner)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'More options',

                  // 1. MODERN SHAPE & SHADOW
                  elevation: 2, // Softer shadow (M3 uses lower elevation)
                  shadowColor: Colors.black12, // Very subtle shadow color
                  surfaceTintColor:
                      Colors.white, // Ensures the background stays clean
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      16,
                    ), // Large rounded corners
                  ),
                  offset: const Offset(0, 48), // Pushes the menu down slightly

                  onSelected: (value) {
                    if (value == 'rename') {
                      _showRenameDialog(context, ref, setlist);
                    } else if (value == 'delete') {
                      _showDeleteConfirmation(context, ref, setlist.id);
                    }
                  },
                  itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        // ITEM 1: RENAME
                        PopupMenuItem<String>(
                          value: 'rename',
                          height: 48, // Standard touch target
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 20,
                                color: Colors.grey[800],
                              ),
                              const SizedBox(
                                width: 12,
                              ), // Spacing between icon and text
                              Text(
                                'Rename',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey[900],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // DIVIDER (Optional, adds a nice separation)
                        const PopupMenuDivider(height: 1),

                        // ITEM 2: DELETE
                        PopupMenuItem<String>(
                          value: 'delete',
                          height: 48,
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 20,
                                color: Colors.red[400],
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.red[400], // Matches the icon
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
            ],
          ),
          floatingActionButton: isOwner ? _buildAddButton(context, ref) : null,
          body: hasSongs
              ? Column(
                  children: [
                    SetlistHeader(setlist: setlist),
                    if (!isOwner) _buildFollowButton(context, ref, setlist),
                    Expanded(
                      child: isOwner
                          ? SetlistOwnerView(setlist: setlist)
                          : SetlistViewerView(setlist: setlist),
                    ),
                  ],
                )
              : EmptySetlistState(title: setlist.title),
        );
      },
    );
  }

  Widget _buildNotFoundScreen(BuildContext context) {
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

  Widget _buildFollowButton(
    BuildContext context,
    WidgetRef ref,
    Setlist setlist,
  ) {
    final followedList =
        ref.watch(followedSetlistsProvider).asData?.value ?? [];
    final isFollowing = followedList.any((s) => s.id == setlist.id);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Theme.of(context).colorScheme.surface,
      child: isFollowing
          ? OutlinedButton.icon(
              onPressed: () => _toggleFollow(ref, setlist.id, true),
              icon: const Icon(Icons.check),
              label: const Text("Following"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
              ),
            )
          : ElevatedButton.icon(
              onPressed: () => _toggleFollow(ref, setlist.id, false),
              icon: const Icon(Icons.bookmark_add_outlined),
              label: const Text("Follow Setlist"),
            ),
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, Setlist setlist) {
    final controller = TextEditingController(text: setlist.title);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Rename Setlist"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Enter new name",
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                ref
                    .read(setlistControllerProvider.notifier)
                    .renameSetlist(
                      setlistId: setlist.id,
                      newTitle: controller.text.trim(),
                    );
                Navigator.pop(context);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    String setlistId,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Setlist?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () {
              // 1. Trigger delete
              ref
                  .read(setlistControllerProvider.notifier)
                  .deleteSetlist(setlistId);

              // 2. Close Dialog
              Navigator.pop(context);

              // 3. Go back to list screen
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  void _toggleFollow(WidgetRef ref, String setlistId, bool isFollowing) {
    ref
        .read(setlistControllerProvider.notifier)
        .toggleFollow(setlistId: setlistId, isCurrentlyFollowing: isFollowing);
  }

  Widget _buildAddButton(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      label: const Text('Add Songs'),
      icon: const Icon(Icons.add),
      onPressed: () async {
        final List<String>? selectedIds = await context.pushNamed('songPicker');

        if (selectedIds != null && selectedIds.isNotEmpty) {
          // Just call the controller. Logic is hidden.
          await ref
              .read(setlistControllerProvider.notifier)
              .addSongs(setlistId: widget.setlistId, songIds: selectedIds);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Added ${selectedIds.length} songs')),
            );
          }
        }
      },
    );
  }
}
