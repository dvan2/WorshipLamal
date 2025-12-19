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
    final songsAsync = ref.watch(songListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Worship Lamal')),
      body: songsAsync.when(
        data: (songs) => ListView.separated(
          padding: EdgeInsets.symmetric(vertical: AppConstants.spacingSm),
          itemCount: songs.length,
          separatorBuilder: (context, index) =>
              const Divider(indent: AppConstants.dividerIndent),
          itemBuilder: (context, index) {
            final song = songs[index];
            return SongListItem(
              song: song,
              onTap: () {
                context.goNamed('songDetail', pathParameters: {'id': song.id});
              },
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => _ErrorState(error: err.toString()),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: AppConstants.iconSizeXl,
            color: AppColors.textTertiary,
          ),
          SizedBox(height: AppConstants.spacingLg),
          Text(
            'Something went wrong',
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          SizedBox(height: AppConstants.spacingSm),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppConstants.spacingXl),
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
