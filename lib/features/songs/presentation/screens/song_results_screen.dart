import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worship_lamal/core/theme/app_constants.dart';
import 'package:worship_lamal/features/songs/presentation/providers/song_filter_provider.dart';
import 'package:worship_lamal/features/songs/presentation/widgets/add_to_setlist_sheet.dart';
import 'package:worship_lamal/features/songs/presentation/widgets/song_list_item.dart';
import 'package:worship_lamal/features/songs/presentation/screens/home_dashboard_tab.dart';
import 'package:worship_lamal/features/songs/presentation/widgets/song_search_field.dart'; // Import to access SongSearchField

class SongResultsScreen extends ConsumerWidget {
  const SongResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songsAsync = ref.watch(filteredSongsProvider);
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Songs'),
        elevation: 0,
        scrolledUnderElevation: 0,
        // Automatically gets a back button from GoRouter
      ),
      body: Column(
        children: [
          // 1. THE REAL SEARCH & FILTER BAR
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppConstants.spacingLg,
              AppConstants.spacingSm,
              AppConstants.spacingLg,
              AppConstants.spacingMd,
            ),
            child: SongSearchField(
              searchProvider: searchQueryProvider,
              filterProvider: songFilterProvider,
            ),
          ),

          // 2. THE LIST RESULTS
          Expanded(
            child: songsAsync.when(
              skipLoadingOnReload: true,
              data: (songs) {
                if (songs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No songs found",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Try a different keyword or clear your filters.",
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.only(top: 8, bottom: 80),
                  itemCount: songs.length,
                  separatorBuilder: (context, index) =>
                      const Divider(indent: AppConstants.dividerIndent),
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    return SongListItem(
                      key: ValueKey(song.id),
                      song: song,
                      onTap: () => context.pushNamed(
                        'songDetail',
                        pathParameters: {'id': song.id},
                      ),
                      onLongPress: () {
                        showModalBottomSheet(
                          context: context,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (context) => AddToSetlistSheet(
                            songId: song.id,
                            songTitle: song.title,
                          ),
                        );
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
