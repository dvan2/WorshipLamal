import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/features/songs/data/models/song_model.dart';
import 'package:worship_lamal/features/userkey/presentation/providers/user_keys_provider.dart';

class SongPickerItem extends ConsumerWidget {
  final Song song;
  final bool isSelected;
  final bool isAlreadyInSetlist;
  final VoidCallback onTap;

  const SongPickerItem({
    super.key,
    required this.song,
    required this.isSelected,
    required this.isAlreadyInSetlist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Check if the user has a custom key saved for this song
    final userKeysMap = ref.watch(userPreferredKeysMapProvider);
    final isUserPreferred = userKeysMap.containsKey(song.id);

    // (Assuming you have a provider or logic for female mode, otherwise default to false for the badge color)
    // For this example, we'll keep it simple and focus on User vs Original
    final isAutoTransposed = false;

    // 2. Opacity Effect for already-added songs
    final double opacity = isAlreadyInSetlist ? 0.4 : 1.0;

    return InkWell(
      // Disable tapping entirely if it's already in the setlist
      onTap: isAlreadyInSetlist ? null : onTap,
      child: Opacity(
        opacity: opacity,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              // ZONE 1: The Selection Action
              _buildSelectionIndicator(),
              const SizedBox(width: 16),

              // ZONE 2: The Context (Title & Smart Subtitle)
              Expanded(child: _buildContextZone(context)),
              const SizedBox(width: 16),

              // ZONE 3: The Static Key Badge
              _buildStaticKeyBadge(
                context,
                song.key ?? '?',
                isUserPreferred,
                isAutoTransposed,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- ZONE 1: SELECTION INDICATOR ---
  Widget _buildSelectionIndicator() {
    if (isAlreadyInSetlist) {
      // Locked State
      return Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 16, color: Colors.white),
      );
    }

    if (isSelected) {
      // Queued State
      return Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 16, color: Colors.white),
      );
    }

    // Unselected State
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400, width: 2),
        shape: BoxShape.circle,
      ),
    );
  }

  // --- ZONE 2: CONTEXT ---
  Widget _buildContextZone(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          song.title,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),

        // Smart Subtitle (Lyrics vs Metadata)
        if (song.searchSnippet != null && song.searchSnippet!.isNotEmpty)
          Text(
            '“…${song.searchSnippet}…”',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.primary,
              fontStyle: FontStyle.italic,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        else
          Text(
            _buildMetadataString(),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
      ],
    );
  }

  String _buildMetadataString() {
    final buffer = StringBuffer(song.artistNames);
    if (song.bpm != null) buffer.write(' • ${song.bpm} BPM');
    if (song.type != SongType.other)
      buffer.write(' • ${song.type.label.toUpperCase()}');
    return buffer.toString();
  }

  // --- ZONE 3: STATIC KEY BADGE ---
  Widget _buildStaticKeyBadge(
    BuildContext context,
    String keyText,
    bool isUserPreferred,
    bool isAutoTransposed,
  ) {
    final Color baseColor;

    if (isUserPreferred) {
      baseColor = Colors.amber.shade800; // Custom Key
    } else if (isAutoTransposed) {
      baseColor = const Color(0xFFE91E63); // Vocal Mode
    } else {
      baseColor = AppColors.primary; // Original Key
    }

    return Container(
      width: 36,
      height: 36,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: baseColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        keyText,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: baseColor,
        ),
      ),
    );
  }
}
