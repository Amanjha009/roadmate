import 'package:flutter/material.dart';

/// RoadMate India — "Vintage Touring Soul × Modern Navy Precision"
/// Design Tokens & Palette specification.
///
/// Combines vintage motorcycle instrumentation with modern high-precision
/// touring digital standards.
class AppColors {
  AppColors._();

  // ── Core Brand Palette ────────────────────────────────────────────────
  /// Midnight Navy — primary brand canvas & dark background.
  static const Color midnightNavy = Color(0xFF101C2C);

  /// Deep Navy — elevated surface, cards, headers, containers.
  static const Color deepNavy = Color(0xFF17283D);

  /// Instrument Black — cockpit displays, HUD panels, deep contrast areas.
  static const Color instrumentBlack = Color(0xFF101318);

  /// Graphite — secondary telemetry wells, subtle borders, card tracks.
  static const Color graphite = Color(0xFF202630);

  /// Warm Ivory — light theme canvas, clean reading surfaces, emblem strokes.
  static const Color warmIvory = Color(0xFFF7F6F2);

  /// Pure White — crisp typography, icon foregrounds, high-contrast markers.
  static const Color pureWhite = Color(0xFFFFFFFF);

  /// Steel Blue — dividers, inactive icon states, contour accents.
  static const Color steelBlue = Color(0xFF62758A);

  /// Heritage Copper — iconic warm touring accent, primary CTAs, road stamps.
  static const Color heritageCopper = Color(0xFFC47B46);

  /// Heritage Copper Pressed/Active state.
  static const Color heritageCopperDark = Color(0xFFA66434);

  /// Touring Amber — caution, upcoming turns, pending checkpoints.
  static const Color touringAmber = Color(0xFFF2B544);

  /// Safe Green — verified passes, rider online status, safe corridors.
  static const Color safeGreen = Color(0xFF3E9B70);

  /// Alert Red — SOS emergency triggers, active rockfalls, impassable hazards.
  static const Color alertRed = Color(0xFFD74743);

  /// Muted Text — metadata, secondary telemetry, subtle timestamps.
  static const Color mutedText = Color(0xFFA5AFBC);

  // ── Backwards-Compatible Semantic Mappings ─────────────────────────────
  static const Color background = midnightNavy;
  static const Color surface = deepNavy;
  static const Color surfaceVariant = graphite;
  static const Color primary = heritageCopper;
  static const Color primaryVariant = heritageCopperDark;
  static const Color onPrimary = pureWhite;
  static const Color textPrimary = pureWhite;
  static const Color textSecondary = mutedText;
  static const Color textTertiary = steelBlue;
  static const Color statusGreen = safeGreen;
  static const Color statusAmber = touringAmber;
  static const Color statusRed = alertRed;
  static const Color divider = steelBlue;
  static const Color error = alertRed;
}
