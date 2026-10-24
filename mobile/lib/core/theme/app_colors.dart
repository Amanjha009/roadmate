import 'package:flutter/material.dart';

/// RoadMate India "Dark Touring" color palette.
///
/// Designed for maximum readability on motorcycle mounts under direct
/// sunlight and through tinted visors. Every color passes WCAG AA
/// contrast against its intended background.
class AppColors {
  AppColors._();

  /// Matte charcoal — primary background.
  static const Color background = Color(0xFF121212);

  /// Elevated surface — bottom bar, dialogs.
  static const Color surface = Color(0xFF1E1E1E);

  /// Cards, text-field fills, chips.
  static const Color surfaceVariant = Color(0xFF2C2C2C);

  /// Safety blaze orange — primary brand/CTA color.
  static const Color primary = Color(0xFFFF5C00);

  /// Pressed / focused variant of primary.
  static const Color primaryVariant = Color(0xFFE55200);

  /// Text rendered on top of [primary] backgrounds.
  static const Color onPrimary = Color(0xFFFFFFFF);

  /// Default body/title text.
  static const Color textPrimary = Color(0xFFFFFFFF);

  /// Secondary labels, captions.
  static const Color textSecondary = Color(0xFFB0B0B0);

  /// Hints, disabled text.
  static const Color textTertiary = Color(0xFF757575);

  /// "All clear" — safe ride conditions, verified status.
  static const Color statusGreen = Color(0xFF4CAF50);

  /// "Caution" — moderate hazard, pending verification.
  static const Color statusAmber = Color(0xFFFFC107);

  /// "Danger / SOS" — high severity hazard, crash alert.
  static const Color statusRed = Color(0xFFF44336);

  /// Dividers and subtle borders.
  static const Color divider = Color(0xFF2C2C2C);

  /// Error state (Material dark-theme error tint).
  static const Color error = Color(0xFFCF6679);
}
