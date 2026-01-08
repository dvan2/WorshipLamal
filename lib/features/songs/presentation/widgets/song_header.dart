import 'package:flutter/material.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/core/theme/app_constants.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';

class SongHeader extends StatelessWidget {
  final Song song;
  // 1. New Properties
  final String displayKey;
  final bool isTransposed;

  const SongHeader({
    super.key,
    required this.song,
    // 2. Require them (pass song.key as default if needed)
    required this.displayKey,
    this.isTransposed = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppConstants.songDetailPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primaryLight.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: const Border(
          bottom: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            song.title,
            style: Theme.of(
              context,
            ).textTheme.displayMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppConstants.songHeaderSpacing),
          Text(
            song.artistNames,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),

          if (displayKey.isNotEmpty || song.bpm != null)
            const SizedBox(height: AppConstants.spacingLg),

          if (displayKey.isNotEmpty || song.bpm != null)
            Wrap(
              spacing: AppConstants.spacingMd,
              runSpacing: AppConstants.spacingSm,
              children: [
                if (displayKey.isNotEmpty)
                  _buildMetadataBadge(
                    context,
                    Icons.music_note,
                    'Key',
                    displayKey, // 3. Use the dynamic key
                    isTransposed: isTransposed, // 4. Pass the flag
                  ),
                if (song.bpm != null)
                  _buildMetadataBadge(
                    context,
                    Icons.speed,
                    'Tempo',
                    '${song.bpm}',
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildMetadataBadge(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isTransposed = false, // Optional param
  }) {
    // Determine colors based on transposed state
    final bgColor = isTransposed
        ? AppColors
              .keyBadgeTransposedBackground // Define this in AppColors
        : AppColors.surface;

    final borderColor = isTransposed
        ? Colors.purple.withOpacity(0.3)
        : AppColors.border;

    final textColor = isTransposed
        ? AppColors
              .keyBadgeTransposedText // Define this in AppColors
        : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: AppConstants.spacingXs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppConstants.spacingXs),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: textColor, // Use dynamic color
            ),
          ),
        ],
      ),
    );
  }
}
