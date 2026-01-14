import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:worship_lamal/features/profile/presentation/providers/preferences_provider.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/core/theme/app_constants.dart';
import 'package:worship_lamal/features/songs/presentation/providers/display_key_provider.dart';

class SongListItem extends ConsumerStatefulWidget {
  final Song song;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const SongListItem({
    super.key,
    required this.song,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  ConsumerState<SongListItem> createState() => _SongListItemState();
}

class _SongListItemState extends ConsumerState<SongListItem> {
  bool? _optimisticFavorite;

  @override
  Widget build(BuildContext context) {
    final originalKey = widget.song.key ?? "";
    final displayKey = ref.watch(displayKeyProvider(originalKey));
    final isTransposed =
        ref.watch(preferencesProvider).vocalMode == VocalMode.female;

    final favoritesAsync = ref.watch(favoritesListProvider);
    final currentFavorites = favoritesAsync.value ?? [];
    final isDatabaseFavorite = currentFavorites.any(
      (f) => f.songId == widget.song.id,
    );

    final isFavorite = _optimisticFavorite ?? isDatabaseFavorite;

    return InkWell(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.songCardPaddingHorizontal,
          vertical: AppConstants.songCardPaddingVertical,
        ),
        child: Row(
          children: [
            _buildLeadingIcon(),
            const SizedBox(width: AppConstants.songCardIconPadding),
            _buildSongInfo(context),
            const SizedBox(width: AppConstants.spacingLg),
            _buildTrailingActions(
              context,
              displayKey,
              isTransposed,
              isFavorite,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingIcon() {
    return Container(
      width: AppConstants.songCardIconSize,
      height: AppConstants.songCardIconSize,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.iconGradientStart, AppColors.iconGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppConstants.songCardIconRadius),
      ),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white,
        size: AppConstants.iconSizeMd,
      ),
    );
  }

  Widget _buildSongInfo(BuildContext context) {
    final String subtitleText;
    if (widget.song.bpm != null) {
      subtitleText = '${widget.song.artistNames} • ${widget.song.bpm} BPM';
    } else {
      subtitleText = widget.song.artistNames;
    }
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.song.title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppConstants.spacingXs),
          Text(
            subtitleText,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(height: 1.2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildKeyBadge(
    BuildContext context,
    String keyText,
    bool isTransposed,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.badgePaddingHorizontal,
        vertical: AppConstants.badgePaddingVertical,
      ),
      decoration: BoxDecoration(
        color: isTransposed
            ? AppColors.keyBadgeTransposedBackground
            : AppColors.keyBadgeBackground,
        borderRadius: BorderRadius.circular(AppConstants.badgeRadius),
      ),
      child: Text(
        keyText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: isTransposed
              ? AppColors.keyBadgeTransposedText
              : AppColors.keyBadgeText,
        ),
      ),
    );
  }

  Widget _buildTrailingActions(
    BuildContext context,
    String displayKey,
    bool isTransposed,
    bool isFavorite,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: () {
            setState(() {
              _optimisticFavorite = !isFavorite;
            });

            // B. BACKGROUND NETWORK CALL
            ref
                .read(favoriteControllerProvider.notifier)
                .toggleFavorite(
                  songId: widget.song.id,
                  isCurrentlyFavorite: isFavorite, // Pass original state
                );
          },
          // Added a Key to ensure the icon animation triggers correctly
          key: ValueKey(isFavorite),
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite
                ? Colors.red
                : AppColors.textSecondary.withOpacity(0.5),
            size: 24,
          ),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          splashRadius: 20,
        ),
        const SizedBox(width: 12),
        if (displayKey.isNotEmpty)
          _buildKeyBadge(context, displayKey, isTransposed),
      ],
    );
  }
}
