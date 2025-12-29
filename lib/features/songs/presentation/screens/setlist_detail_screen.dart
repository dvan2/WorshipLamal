import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/features/songs/data/models/setlist_model.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/songs/presentation/providers/setlist_provider.dart';

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
        onPressed: () {
          // TODO: Open Song Picker to add new songs
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Song picker coming next!')),
          );
        },
        label: const Text('Add Song'),
        icon: const Icon(Icons.add),
      ),
      body: setlistAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (setlist) {
          if (setlist.items.isEmpty) {
            return _EmptySetlistState(title: setlist.title);
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SetlistHeader(setlist: setlist),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80), // Space for FAB
                  itemCount: setlist.items.length,
                  itemBuilder: (context, index) {
                    final item = setlist.items[index];
                    return _SetlistItemCard(
                      item: item,
                      index: index,
                      onTap: () {
                        // Navigate to Song Detail
                        context.pushNamed(
                          'songDetail',
                          pathParameters: {'id': item.songId},
                        );
                      },
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

class _SetlistHeader extends StatelessWidget {
  final Setlist setlist;

  const _SetlistHeader({required this.setlist});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppColors.surfaceVariant.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            setlist.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(setlist.createdAt),
                style: TextStyle(color: AppColors.textTertiary),
              ),
              const SizedBox(width: 16),
              Icon(
                setlist.isPublic ? Icons.public : Icons.lock,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                setlist.isPublic ? 'Public' : 'Private',
                style: TextStyle(color: AppColors.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}

class _SetlistItemCard extends StatelessWidget {
  final SetlistItem item;
  final int index;
  final VoidCallback onTap;

  const _SetlistItemCard({
    required this.item,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 1. Sort Order Number
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // 2. Song Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.song.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.song.artistNames,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // 3. Key Badge
              _KeyBadge(displayKey: item.displayKey),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyBadge extends StatelessWidget {
  final String displayKey;

  const _KeyBadge({required this.displayKey});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            'KEY',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          Text(
            displayKey,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySetlistState extends StatelessWidget {
  final String title;

  const _EmptySetlistState({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 32),
          Icon(Icons.playlist_add, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            "This setlist is empty",
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text("Tap 'Add Song' to start building your set"),
        ],
      ),
    );
  }
}
