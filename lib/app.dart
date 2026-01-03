import 'package:flutter/material.dart';
import 'package:worship_lamal/core/theme/app_theme.dart';
import 'core/routing/app_router.dart';

class WorshipLamal extends StatelessWidget {
  const WorshipLamal({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: appRouter,
      theme: AppTheme.lightTheme,
    );
  }
}
