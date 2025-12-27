import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/core/theme/app_constants.dart';

import '../providers/song_provider.dart';
import '../widgets/song_list_item.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. WATCH the smart filtered list
    final songsAsync = ref.watch(filteredSongsProvider);

    // 2. Read the query just to check if it's empty (for the "X" button)
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Worship Lamal'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spacingLg,
              0,
              AppConstants.spacingLg,
              AppConstants.spacingMd,
            ),
            child: _SearchField(), // Extracted widget for cleanliness
          ),
        ),
      ),
      body: songsAsync.when(
        data: (songs) {
          // Handle "No Results" state
          if (songs.isEmpty && searchQuery.isNotEmpty) {
            return const Center(child: Text("No songs found"));
            // (You can use your _EmptySearchState widget here)
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(
              vertical: AppConstants.spacingSm,
            ),
            itemCount: songs.length,
            separatorBuilder: (context, index) =>
                const Divider(indent: AppConstants.dividerIndent),
            itemBuilder: (context, index) {
              final song = songs[index];
              return SongListItem(
                song: song,
                onTap: () => context.goNamed(
                  'songDetail',
                  pathParameters: {'id': song.id},
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

// Separate the Search Field so it accesses 'ref' cleanly
class _SearchField extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We watch the query to show/hide the clear button
    final query = ref.watch(searchQueryProvider);

    return TextField(
      // 3. IMPORTANT: Update provider on change. No setState needed!
      onChanged: (value) {
        ref.read(searchQueryProvider.notifier).state = value;
      },
      decoration: InputDecoration(
        hintText: 'Search songs, artists...',
        prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
        suffixIcon: query.isNotEmpty
            ? IconButton(
                icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                onPressed: () {
                  // Clear the global state
                  ref.read(searchQueryProvider.notifier).state = '';
                  // Note: You might need a TextEditingController if you want to clear
                  // the actual text visually, but for simple cases, this updates the list.
                },
              )
            : null,
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacingLg,
          vertical: AppConstants.spacingMd,
        ),
      ),
    );
  }
}
