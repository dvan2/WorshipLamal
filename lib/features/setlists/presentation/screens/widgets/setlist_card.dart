import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/features/songs/data/models/setlist_model.dart';

class SetlistCard extends StatelessWidget {
  final Setlist setlist;
  final bool isOwner;

  const SetlistCard({super.key, required this.setlist, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      // Distinguish owned vs shared setlists visually
      color: isOwner ? AppColors.surface : AppColors.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOwner
              ? AppColors.border
              : AppColors.primary.withOpacity(0.3),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          context.pushNamed(
            'setlistDetail',
            pathParameters: {'id': setlist.id},
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 1. Icon Box
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isOwner
                      ? AppColors.primary.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isOwner ? Icons.queue_music : Icons.lock_person,
                  color: isOwner ? AppColors.primary : Colors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),

              // 2. Title & Count
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      setlist.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          '${setlist.items.length} songs',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        if (!isOwner) ...[
                          const SizedBox(width: 8),
                          _buildBadge("Read Only", Colors.orange),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // 3. Chevron
              const Icon(Icons.chevron_right, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
