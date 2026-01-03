import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/features/songs/data/models/setlist_model.dart';
import 'package:worship_lamal/features/songs/presentation/providers/setlist_provider.dart';

class SetlistsTab extends ConsumerWidget {
  const SetlistsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Watch BOTH providers
    final mySetlistsAsync = ref.watch(setlistsListProvider);
    final followedSetlistsAsync = ref.watch(followedSetlistsProvider);

    return Stack(
      children: [
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: AppColors.primary,
            child: const Icon(Icons.add),
            onPressed: () => _showCreateDialog(context, ref),
          ),
        ),

        Expanded(
          child: mySetlistsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) =>
                Center(child: Text('Error loading yours: $err')),
            data: (mySetlists) {
              return followedSetlistsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) =>
                    Center(child: Text('Error loading followed: $err')),
                data: (followedSetlists) {
                  // CHECK EMPTY STATE
                  if (mySetlists.isEmpty && followedSetlists.isEmpty) {
                    return _EmptySetlistState();
                  }

                  // COMBINE EVERYTHING
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CustomScrollView(
                      slivers: [
                        // SECTION A: MY SETLISTS
                        if (mySetlists.isNotEmpty) ...[
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(4, 16, 0, 8),
                              child: Text(
                                "My Setlists",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final setlist = mySetlists[index];
                              return _SetlistCard(
                                setlist: setlist,
                                isOwner: true,
                              );
                            }, childCount: mySetlists.length),
                          ),
                        ],

                        // SPACING
                        if (mySetlists.isNotEmpty &&
                            followedSetlists.isNotEmpty)
                          const SliverToBoxAdapter(child: SizedBox(height: 24)),

                        // SECTION B: FOLLOWED SETLISTS
                        if (followedSetlists.isNotEmpty) ...[
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(4, 16, 0, 8),
                              child: Text(
                                "Following",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final setlist = followedSetlists[index];
                              return _SetlistCard(
                                setlist: setlist,
                                isOwner: false,
                              );
                            }, childCount: followedSetlists.length),
                          ),
                        ],

                        // Extra space at bottom so list isn't hidden behind FAB
                        const SliverToBoxAdapter(child: SizedBox(height: 100)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (_) => const _CreateSetlistDialog());
  }

  // 👇 2. ADD THIS METHOD TO HANDLE JOINING
  Future<void> _showJoinByIdDialog(BuildContext context) async {
    final controller = TextEditingController();

    // Show Dialog and wait for result
    final setlistId = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Join Setlist by ID'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Paste UUID here...',
            border: OutlineInputBorder(),
            helperText: "Get this ID from the setlist owner",
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, controller.text.trim());
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );

    if (setlistId != null && setlistId.isNotEmpty && context.mounted) {
      context.pushNamed('setlistDetail', pathParameters: {'id': setlistId});
    }
  }
}

class _EmptySetlistState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.queue_music, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            "No setlists yet",
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text("Tap the + button to create one"),
        ],
      ),
    );
  }
}

// The Dialog to Create a Setlist
class _CreateSetlistDialog extends ConsumerStatefulWidget {
  const _CreateSetlistDialog();

  @override
  ConsumerState<_CreateSetlistDialog> createState() =>
      __CreateSetlistDialogState();
}

class __CreateSetlistDialogState extends ConsumerState<_CreateSetlistDialog> {
  final _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Watch controller state to show spinner if loading
    final state = ref.watch(setlistControllerProvider);
    final isLoading = state.isLoading;

    return AlertDialog(
      title: const Text('New Setlist'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          hintText: 'e.g. Sunday Service Oct 22',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading
              ? null
              : () async {
                  if (_controller.text.trim().isEmpty) return;

                  // Call the controller
                  final newId = await ref
                      .read(setlistControllerProvider.notifier)
                      .createSetlist(_controller.text.trim());

                  if (newId != null && context.mounted) {
                    Navigator.pop(context); // Close dialog

                    // Optional: Navigate directly to the new setlist
                    // context.pushNamed('setlistDetail', pathParameters: {'id': newId});
                  }
                },
          child: isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

class _SetlistCard extends StatelessWidget {
  final Setlist setlist;
  final bool isOwner;

  const _SetlistCard({required this.setlist, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      color: isOwner
          ? AppColors.surfaceVariant
          : Colors.blue.shade50, // Slight tint for followed
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOwner
              ? Colors.grey.withOpacity(0.1)
              : Colors.blue.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),

        // Icon differentiates type
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isOwner ? Colors.white : Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isOwner ? Icons.queue_music : Icons.bookmark,
            color: isOwner ? AppColors.primary : Colors.blue,
            size: 20,
          ),
        ),

        title: Text(setlist.title),

        subtitle: Row(
          children: [
            Text(
              '${setlist.items.length} songs',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            if (!isOwner) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "View Only",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),

        trailing: const Icon(Icons.chevron_right, color: Colors.grey),

        onTap: () {
          // Both navigate to the same detail screen
          // The Detail Screen Logic (isOwner check) handles the "Read Only" behavior
          context.pushNamed(
            'setlistDetail',
            pathParameters: {'id': setlist.id},
          );
        },
      ),
    );
  }
}
