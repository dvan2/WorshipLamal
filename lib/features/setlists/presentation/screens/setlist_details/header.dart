import 'package:flutter/material.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/features/songs/data/models/setlist_model.dart';

// The Setlist details header showing title, date
class SetlistHeader extends StatelessWidget {
  final Setlist setlist;

  const SetlistHeader({required this.setlist});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: AppColors.surfaceVariant.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            setlist.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                _formatDate(setlist.createdAt),
                style: TextStyle(color: AppColors.textTertiary),
              ),
              const SizedBox(width: 16),
              Icon(
                setlist.isPublic ? Icons.public : Icons.lock,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
              Text(
                setlist.isPublic ? 'Public' : 'Private',
                style: TextStyle(color: AppColors.textTertiary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}
