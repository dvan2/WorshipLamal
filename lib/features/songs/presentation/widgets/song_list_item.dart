import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/features/profile/presentation/providers/preferences_provider.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/core/theme/app_constants.dart';
import 'package:worship_lamal/features/songs/presentation/providers/display_key_provider.dart';

/// Reusable song list item widget
/// Displays song information in a clean, consistent format
class SongListItem extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final originalKey = song.key ?? "";
    final displayKey = ref.watch(displayKeyProvider(originalKey));
    final isTransposed =
        ref.watch(preferencesProvider).vocalMode == VocalMode.female;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppConstants.songCardPaddingHorizontal,
          vertical: AppConstants.songCardPaddingVertical,
        ),
        child: Row(
          children: [
            _buildLeadingIcon(),
            SizedBox(width: AppConstants.songCardIconPadding),
            _buildSongInfo(context),
            SizedBox(width: AppConstants.spacingLg),
            _buildMetadata(context, displayKey, isTransposed),
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
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            song.title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: AppConstants.spacingXs),
          Text(
            song.artistNames,
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

  Widget _buildMetadata(
    BuildContext context,
    String displayKey,
    bool isTransposed,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (displayKey.isNotEmpty)
          _buildKeyBadge(context, displayKey, isTransposed),

        if (displayKey.isNotEmpty && song.bpm != null)
          const SizedBox(height: AppConstants.spacingXs),

        if (song.bpm != null) _buildBpmText(context),
      ],
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
        // Purple for Transposed (Female), Blue for Original
        color: isTransposed
            ? AppColors.keyBadgeTransposedBackground
            : AppColors.keyBadgeBackground,
        borderRadius: BorderRadius.circular(AppConstants.badgeRadius),
      ),
      child: Text(
        keyText, // Shows the new key (e.g., "D")
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700, // Make it slightly bolder
          // Purple text for Transposed
          color: isTransposed
              ? AppColors.keyBadgeTransposedText
              : AppColors.keyBadgeText,
        ),
      ),
    );
  }

  Widget _buildBpmText(BuildContext context) {
    return Text(
      '${song.bpm} BPM',
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
    );
  }
}
