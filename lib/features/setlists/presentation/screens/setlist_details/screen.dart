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

class SetlistDetailScreen extends ConsumerWidget {
  final String setlistId;
  const SetlistDetailScreen({super.key, required this.setlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setlistAsync = ref.watch(setlistDetailProvider(setlistId));
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

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
              IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
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
              .addSongs(setlistId: setlistId, songIds: selectedIds);

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
