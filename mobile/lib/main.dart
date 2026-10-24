import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';

/// Entry point for RoadMate India.
///
/// Initializes Riverpod [ProviderScope] and launches the app.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: RoadMateApp(),
    ),
  );
}
