// Display full song lists
// Contains the search field

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/core/theme/app_constants.dart';
import 'package:worship_lamal/features/songs/presentation/providers/song_filter_provider.dart';
import 'package:worship_lamal/features/songs/presentation/widgets/add_to_setlist_sheet.dart';
import 'package:worship_lamal/features/songs/presentation/widgets/song_filter_bottom_sheet.dart';
import 'package:worship_lamal/features/songs/presentation/widgets/song_list_item.dart';

class SongsTab extends ConsumerWidget {
  const SongsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This is the logic extracted from your old HomeScreen
    final songsAsync = ref.watch(filteredSongsProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppConstants.spacingLg,
            0,
            AppConstants.spacingLg,
            AppConstants.spacingMd,
          ),
          child: SongSearchField(
            searchProvider: searchQueryProvider,
            filterProvider: songFilterProvider,
          ),
        ),
        // Expanded List
        Expanded(
          child: songsAsync.when(
            skipLoadingOnReload: true,
            data: (songs) {
              if (songs.isEmpty && searchQuery.isNotEmpty) {
                return const Center(child: Text("No songs found"));
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
                    key: ValueKey(song.id),
                    song: song,
                    onTap: () => context.goNamed(
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
    );
  }
}

class SongSearchField extends ConsumerStatefulWidget {
  final NotifierProvider<SearchQueryNotifier, String> searchProvider;
  final NotifierProvider<SongFilterNotifier, SongFilterState> filterProvider;

  const SongSearchField({
    super.key,
    required this.searchProvider,
    required this.filterProvider,
  });

  @override
  ConsumerState<SongSearchField> createState() => _SongSearchFieldState();
}

class _SongSearchFieldState extends ConsumerState<SongSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(widget.searchProvider);
    final filterState = ref.watch(widget.filterProvider);
    final hasFilters = filterState.isFiltering;

    // Sync Controller with Provider
    ref.listen(widget.searchProvider, (previous, next) {
      if (next.isEmpty && _controller.text.isNotEmpty) {
        _controller.clear();
      }
    });

    return Row(
      children: [
        // 1. EXPANDED SEARCH BAR
        Expanded(
          child: TextField(
            controller: _controller,
            onChanged: (value) {
              ref.read(widget.searchProvider.notifier).setQuery(value);
            },
            decoration: InputDecoration(
              hintText: 'Search songs...',
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.textSecondary,
              ),
              // Only the Clear Button lives here now
              suffixIcon: query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.clear,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          ref.read(widget.searchProvider.notifier).clear(),
                    )
                  : null,
              filled: true,
              fillColor: AppColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(
                  12,
                ), // Matching rounded corners
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              isDense: true, // Makes it look slightly more compact/modern
            ),
          ),
        ),

        const SizedBox(width: 12),

        // 2. DETACHED FILTER BUTTON
        // Provides a consistent, large touch target that never moves
        Material(
          color: AppColors.surfaceVariant, // Match search bar color
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (context) => SongFilterBottomSheet(
                  targetProvider: widget.filterProvider,
                ),
              );
            },
            child: Container(
              height: 48, // Standard touch target height
              width: 48,
              alignment: Alignment.center,
              child: Badge(
                isLabelVisible: hasFilters,
                backgroundColor: AppColors.primary,
                smallSize: 8,
                child: Icon(
                  Icons.tune_rounded, // Rounded variant looks softer
                  color: hasFilters
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
