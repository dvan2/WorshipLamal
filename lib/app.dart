import 'package:flutter/material.dart';
import 'core/routing/app_router.dart';

class WorshipLamal extends StatelessWidget {
  const WorshipLamal({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(routerConfig: appRouter);
  }
}
