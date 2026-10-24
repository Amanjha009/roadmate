import 'dart:ui';
import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 3-Tier Glass Elevation System for RoadMate India.
///
/// Implements Apple's Liquid Glass depth and translucency combined with
/// Instagram's warm content cards and fluid micro-interactions.
enum GlassElevationTier {
  /// Tier 1: Ground Canvas — solid, fully opaque #121212 base.
  base,

  /// Tier 2: Mid-Elevation — secondary info cards, stats, ride history,
  /// settings, floating cards over map/content.
  mid,

  /// Tier 3: Top-Elevation — navigation bars, bottom tab bar, modals,
  /// bottom sheets, and floating action bars.
  top,
}

/// Reusable GlassSurface component with backdrop blur, 1px glass edge,
/// specular sheen highlight, and solid fallback for low-power/unsupported engines.
class GlassSurface extends StatelessWidget {
  /// Surface child contents.
  final Widget child;

  /// Elevation tier governing blur sigma and opacity.
  final GlassElevationTier tier;

  /// Corner radius (defaults to 18dp for Instagram rounded aesthetic).
  final BorderRadius borderRadius;

  /// Inner padding.
  final EdgeInsetsGeometry? padding;

  /// Outer margin.
  final EdgeInsetsGeometry? margin;

  /// Optional tap handler with tactile spring feedback.
  final VoidCallback? onTap;

  /// Whether to render the diagonal specular highlight sheen.
  final bool showSpecularSheen;

  /// Explicit Safety Override: If true, renders 100% solid, fully opaque
  /// with zero blur, guaranteed readable in direct sunlight through tinted visors.
  final bool isSolidSafety;

  /// Explicit border color override.
  final Color? borderColor;

  /// Surface width constraint.
  final double? width;

  /// Surface height constraint.
  final double? height;

  const GlassSurface({
    super.key,
    required this.child,
    this.tier = GlassElevationTier.mid,
    this.borderRadius = const BorderRadius.all(Radius.circular(18)),
    this.padding,
    this.margin,
    this.onTap,
    this.showSpecularSheen = true,
    this.isSolidSafety = false,
    this.borderColor,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    // ── NON-NEGOTIABLE SAFETY LINE ──────────────────────────────
    // Safety-critical elements (SOS, crash alerts, highway readouts)
    // are strictly rendered 100% solid opaque with zero blur.
    if (isSolidSafety) {
      return Container(
        width: width,
        height: height,
        margin: margin,
        padding: padding,
        decoration: BoxDecoration(
          color: tier == GlassElevationTier.top
              ? const Color(0xFF181A20)
              : const Color(0xFF14161B),
          borderRadius: borderRadius,
          border: Border.all(
            color: borderColor ?? const Color(0xFF383838),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black54,
              blurRadius: 16,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: child,
      );
    }

    // Elevation parameters
    final double sigma;
    final Color bgColor;
    final List<BoxShadow> shadows;

    switch (tier) {
      case GlassElevationTier.base:
        sigma = 0;
        bgColor = AppColors.background;
        shadows = const [];
        break;
      case GlassElevationTier.mid:
        sigma = 20.0;
        bgColor = const Color(0xB8181B22); // rgba(24, 27, 34, 0.72)
        shadows = const [
          BoxShadow(
            color: Color(0x6B000000), // rgba(0, 0, 0, 0.42)
            blurRadius: 32,
            offset: Offset(0, 8),
          ),
        ];
        break;
      case GlassElevationTier.top:
        sigma = 28.0;
        bgColor = const Color(0xC714161C); // rgba(20, 22, 28, 0.78)
        shadows = const [
          BoxShadow(
            color: Color(0x99000000), // rgba(0, 0, 0, 0.60)
            blurRadius: 48,
            offset: Offset(0, 16),
          ),
          BoxShadow(
            color: Color(0x1AFFFFFF), // inset top edge reflection
            blurRadius: 1,
            offset: Offset(0, 1),
          ),
        ];
        break;
    }

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: borderRadius,
        border: Border.all(
          color: borderColor ?? const Color(0x14FFFFFF), // rgba(255, 255, 255, 0.08)
          width: 1.0,
        ),
        boxShadow: shadows,
      ),
      child: Stack(
        children: [
          // Subtle specular highlight: diagonal white sheen (4-8% opacity)
          if (showSpecularSheen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 48,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: borderRadius.topLeft,
                      topRight: borderRadius.topRight,
                    ),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0x17FFFFFF), // 9% white sheen at crest
                        Color(0x05FFFFFF), // 2% white mid sheen
                        Color(0x00FFFFFF), // Transparent fade
                      ],
                      stops: [0.0, 0.4, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );

    // Apply backdrop filter blur
    if (sigma > 0) {
      content = ClipRRect(
        borderRadius: borderRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    if (onTap != null) {
      content = TactileSquishButton(
        onTap: onTap!,
        child: content,
      );
    }

    return content;
  }
}

/// Tactile Spring Squish interaction widget.
/// Scales down to 0.97 on press and springs back with Apple-style damped overshoot.
class TactileSquishButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double squishScale;
  final Duration duration;

  const TactileSquishButton({
    super.key,
    required this.child,
    required this.onTap,
    this.squishScale = 0.97,
    this.duration = const Duration(milliseconds: 320),
  });

  @override
  State<TactileSquishButton> createState() => _TactileSquishButtonState();
}

class _TactileSquishButtonState extends State<TactileSquishButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // Apple-style damped spring curve with slight overshoot
    _scaleAnimation = Tween<double>(begin: 1.0, end: widget.squishScale).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Cubic(0.34, 1.3, 0.64, 1.0),
        reverseCurve: const Cubic(0.16, 1.0, 0.3, 1.0),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

/// Instagram-Influenced Rider Trust Score Ring.
///
/// Circular avatar framed by a thin accent ring that fills proportionally
/// to the rider's trust score (0-100) using a sweep gradient.
/// Exclusively displays trust score and verification status — strictly NO like
/// or follower vanity metrics.
class StoryTrustRing extends StatelessWidget {
  /// Rider trust score from 0 to 100.
  final int trustScore;

  /// Diameter of the avatar.
  final double size;

  /// Avatar image URL or asset.
  final ImageProvider? avatarImage;

  /// Fallback initials or icon.
  final Widget? fallback;

  /// Optional tap callback.
  final VoidCallback? onTap;

  const StoryTrustRing({
    super.key,
    required this.trustScore,
    this.size = 88.0,
    this.avatarImage,
    this.fallback,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Proportional sweep: (trustScore / 100) * 360 deg
    final fillFraction = (trustScore.clamp(0, 100) / 100.0);

    Widget ring = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: SweepGradient(
          startAngle: 0.0,
          endAngle: 6.28318, // 2 * pi
          stops: [0.0, fillFraction, fillFraction, 1.0],
          colors: const [
            AppColors.primary,
            Color(0xFFFFA726),
            Color(0x1FFFFFFF),
            Color(0x1FFFFFFF),
          ],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x66FF5C00),
            blurRadius: 16,
            spreadRadius: 1,
          ),
        ],
      ),
      padding: const EdgeInsets.all(3.5),
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF14161B), // Gap between ring and avatar
        ),
        padding: const EdgeInsets.all(2.5),
        child: ClipOval(
          child: avatarImage != null
              ? Image(
                  image: avatarImage!,
                  fit: BoxFit.cover,
                )
              : (fallback ??
                  const Center(
                    child: Text(
                      '🏍️',
                      style: TextStyle(fontSize: 24),
                    ),
                  )),
        ),
      ),
    );

    if (onTap != null) {
      ring = TactileSquishButton(
        onTap: onTap!,
        child: ring,
      );
    }

    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        ring,
        // Solid floating trust score numeric pill
        Positioned(
          bottom: -2,
          right: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF14161B), width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black87,
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '$trustScore',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ],
    );
  }
}
