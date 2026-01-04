import 'package:flutter/material.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';

class EmptySetlistState extends StatelessWidget {
  const EmptySetlistState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.queue_music,
            size: 64,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 16),
          const Text(
            "No setlists yet",
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text("Tap the + button to create one"),
        ],
      ),
    );
  }
}
