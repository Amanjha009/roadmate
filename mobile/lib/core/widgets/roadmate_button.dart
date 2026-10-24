import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Full-width elevated button in blaze orange.
///
/// * 56 dp minimum height for gloved-hand tapping.
/// * 12 px corner radius, white bold text.
/// * Shows a [CircularProgressIndicator] when [isLoading] is true.
class RoadmateButton extends StatelessWidget {
  /// Button label.
  final String label;

  /// Callback when pressed. Ignored while [isLoading] is true.
  final VoidCallback? onPressed;

  /// Whether to show a loading spinner instead of [label].
  final bool isLoading;

  /// Optional leading icon.
  final IconData? icon;

  const RoadmateButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.onPrimary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 8),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}
