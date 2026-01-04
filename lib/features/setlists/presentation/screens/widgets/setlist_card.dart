import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';
import 'package:worship_lamal/features/songs/data/models/setlist_model.dart'; // Adjust path if needed

class SetlistCard extends StatelessWidget {
  final Setlist setlist;
  final bool isOwner;

  const SetlistCard({super.key, required this.setlist, required this.isOwner});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      // Use your AppColors here
      color: isOwner ? AppColors.surfaceVariant : Colors.blue.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isOwner
              ? Colors.grey.withOpacity(0.1)
              : Colors.blue.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isOwner ? Colors.white : Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isOwner ? Icons.queue_music : Icons.bookmark,
            color: isOwner ? AppColors.primary : Colors.blue,
            size: 20,
          ),
        ),
        title: Text(setlist.title),
        subtitle: Row(
          children: [
            Text(
              '${setlist.items.length} songs',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (!isOwner) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "View Only",
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          context.pushNamed(
            'setlistDetail',
            pathParameters: {'id': setlist.id},
          );
        },
      ),
    );
  }
}
