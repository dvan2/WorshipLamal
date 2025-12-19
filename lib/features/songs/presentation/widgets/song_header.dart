import 'package:flutter/material.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/core/theme/app_constants.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';

/// Reusable song header widget displaying title, artist, and metadata
class SongHeader extends StatelessWidget {
  final Song song;

  const SongHeader({super.key, required this.song});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppConstants.songDetailPadding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primaryLight.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
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
          SizedBox(height: AppConstants.songHeaderSpacing),
          Text(
            song.artistNames,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          if (song.key != null || song.bpm != null)
            SizedBox(height: AppConstants.spacingLg),
          if (song.key != null || song.bpm != null)
            Wrap(
              spacing: AppConstants.spacingMd,
              runSpacing: AppConstants.spacingSm,
              children: [
                if (song.key != null)
                  _buildMetadataBadge(
                    context,
                    Icons.music_note,
                    'Key',
                    song.key!,
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
    String value,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppConstants.spacingMd,
        vertical: AppConstants.spacingSm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          SizedBox(width: AppConstants.spacingXs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: AppConstants.spacingXs),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
