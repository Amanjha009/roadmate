import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Status severity level for [StatusBadge].
enum StatusLevel { green, amber, red }

/// Small pill-shaped badge showing a status level (green / amber / red)
/// with a text label.
///
/// Minimum touch-target width 56 dp; height adjusts to content.
class StatusBadge extends StatelessWidget {
  /// Text displayed inside the badge.
  final String label;

  /// The status level which determines background color.
  final StatusLevel level;

  const StatusBadge({
    super.key,
    required this.label,
    required this.level,
  });

  Color get _backgroundColor {
    switch (level) {
      case StatusLevel.green:
        return AppColors.statusGreen;
      case StatusLevel.amber:
        return AppColors.statusAmber;
      case StatusLevel.red:
        return AppColors.statusRed;
    }
  }

  Color get _textColor {
    if (level == StatusLevel.amber) return Colors.black87;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 56),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _textColor,
        ),
      ),
    );
  }
}
