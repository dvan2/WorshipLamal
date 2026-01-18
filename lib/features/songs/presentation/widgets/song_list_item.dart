import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/features/favorites/presentation/providers/favorites_provider.dart';
import 'package:worship_lamal/features/setlists/presentation/screens/setlist_details/key_picker_dialog.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/core/theme/app_constants.dart';
import 'package:worship_lamal/features/songs/presentation/providers/display_key_provider.dart';
import 'package:worship_lamal/features/userkey/presentation/providers/user_keys_provider.dart';

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
    final finalDisplayKey = ref.watch(
      displayKeyProvider((
        originalKey: widget.song.key,
        songId: widget.song.id,
      )),
    );

    final userKeysMap = ref.watch(userPreferredKeysMapProvider);
    final userPreferredKey = userKeysMap[widget.song.id]; // Null if not set
    bool isUserPreferred = false;
    bool isAutoTransposed = false;

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
              finalDisplayKey,
              isUserPreferred,
              isAutoTransposed,
              isFavorite,
              userPreferredKey,
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
    bool isUserPreferred,
    bool isAutoTransposed,
    String? currentPreferredKey,
  ) {
    final Color baseColor;

    if (isUserPreferred) {
      baseColor = Colors.amber.shade800; // Your Teal/Brand color
    } else if (isAutoTransposed) {
      baseColor = const Color(0xFFE91E63);
    } else {
      baseColor = AppColors.primary; // Default/Original
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showKeyPicker(context, currentPreferredKey),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: baseColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Text(
            keyText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w800,
              // Use the solid base color for text so it's readable
              color: baseColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrailingActions(
    BuildContext context,
    String displayKey,
    bool isUserPreferred,
    bool isAutoTransposed,
    bool isFavorite,
    String? currentPreferredKey,
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
          _buildKeyBadge(
            context,
            displayKey,
            isUserPreferred,
            isAutoTransposed,
            currentPreferredKey,
          ),
      ],
    );
  }

  void _showKeyPicker(BuildContext context, String? currentPreferredKey) {
    showDialog(
      context: context,
      builder: (context) => KeyPickerDialog(
        currentKey: currentPreferredKey,

        // Handle Selection (Save to Supabase)
        onKeySelected: (newKey) {
          ref
              .read(userKeyControllerProvider.notifier)
              .setKey(widget.song.id, newKey);
        },

        // Handle Reset (Delete from Supabase)
        onReset: () {
          ref
              .read(userKeyControllerProvider.notifier)
              .revertKey(widget.song.id);
        },
      ),
    );
  }
}
