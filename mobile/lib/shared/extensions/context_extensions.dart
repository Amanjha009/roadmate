import 'package:flutter/material.dart';

/// Convenience extensions on [BuildContext] for quick access to
/// theme data, text styles, color scheme, and screen dimensions.
extension ContextExtensions on BuildContext {
  /// Shortcut for `Theme.of(this)`.
  ThemeData get theme => Theme.of(this);

  /// Shortcut for `Theme.of(this).textTheme`.
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Shortcut for `Theme.of(this).colorScheme`.
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Screen width via [MediaQuery].
  double get screenWidth => MediaQuery.sizeOf(this).width;

  /// Screen height via [MediaQuery].
  double get screenHeight => MediaQuery.sizeOf(this).height;

  /// Horizontal padding that accounts for notches / punch-holes.
  EdgeInsets get safeArea => MediaQuery.paddingOf(this);

  /// Whether the device is in landscape orientation.
  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;

  /// Show a quick [SnackBar] with [message].
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
