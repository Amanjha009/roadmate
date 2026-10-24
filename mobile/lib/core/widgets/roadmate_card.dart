import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/glass_surface.dart';

/// Surface card supporting Apple Liquid Glass depth with Instagram rounded aesthetic.
///
/// Can be rendered as [GlassElevationTier.mid] with frosted blur and specular
/// sheen, or [isSolidSafety] = true for safety-critical HUD elements.
class RoadmateCard extends StatelessWidget {
  /// Card contents.
  final Widget child;

  /// Optional tap handler with tactile spring squish.
  final VoidCallback? onTap;

  /// Override the default padding.
  final EdgeInsetsGeometry padding;

  /// Optional border color override (defaults to glass edge or [AppColors.divider]).
  final Color? borderColor;

  /// Whether to apply the Apple Liquid Glass surface treatment.
  final bool isGlass;

  /// Glass elevation tier (mid by default).
  final GlassElevationTier glassTier;

  /// Non-negotiable safety line: forces 100% solid, fully opaque rendering with zero blur.
  final bool isSolidSafety;

  const RoadmateCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderColor,
    this.isGlass = true,
    this.glassTier = GlassElevationTier.mid,
    this.isSolidSafety = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isGlass) {
      return GlassSurface(
        tier: glassTier,
        isSolidSafety: isSolidSafety,
        padding: padding,
        borderColor: borderColor,
        onTap: onTap,
        child: child,
      );
    }

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor ?? AppColors.divider,
              width: 0.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
