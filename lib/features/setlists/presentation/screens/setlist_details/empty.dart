import 'package:flutter/material.dart';
import 'package:worship_lamal/core/theme/app_colors.dart';

class EmptySetlistState extends StatelessWidget {
  final String title;

  const EmptySetlistState({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 32),
          Icon(Icons.playlist_add, size: 64, color: AppColors.textTertiary),
          const SizedBox(height: 16),
          Text(
            "This setlist is empty",
            style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          const Text("Tap 'Add Song' to start building your set"),
        ],
      ),
    );
  }
}
