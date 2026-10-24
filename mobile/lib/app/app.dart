import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';
import 'router.dart';

/// Root application widget.
///
/// Configures [MaterialApp.router] with the "Dark Touring" theme and
/// the [GoRouter]-backed navigation.
class RoadMateApp extends StatelessWidget {
  const RoadMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'RoadMate India',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
    );
  }
}
