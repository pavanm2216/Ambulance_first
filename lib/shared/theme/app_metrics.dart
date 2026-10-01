import 'package:flutter/material.dart';

/// Corner radius scale (spec section 7). Restrained on purpose — radius
/// communicates hierarchy, it isn't uniform.
class AppRadius {
  AppRadius._();
  static const double small = 8; // small controls
  static const double compact = 12; // compact cards
  static const double card = 16; // normal cards (was 28 — over-rounded)
  static const double large = 20; // large cards
  static const double hero = 24; // hero/feature cards (was 28)
  static const double button = 22; // primary/secondary buttons — 20–24px, NOT a pill
  static const double input = 18;
  static const double dialog = 24;
  static const double nav = 28; // major floating surfaces
  static const double sheet = 32; // large modal/sheet surfaces
  static const double chip = 9999; // status chips stay fully rounded, per spec
  static const double pill = 9999; // filter pills stay fully rounded, per spec
  static const double ticketNotch = 12;
}

/// Spacing scale (spec section 6). Base unit 4px.
class AppSpacing {
  AppSpacing._();
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double margin = 20; // standard horizontal screen padding
  static const double lg = 24; // major sections
  static const double hero = 28; // around hero areas (28–32)
  static const double xl = 32;
  static const double xxl = 40;
  static const double xxxl = 48;
  static const double giant = 64;
}

/// Subtle, layered shadows (spec section 10). Depth should be felt, not
/// noticed — no dark/black shadows, no dramatic floating cards.
///
/// `softShadow` keeps its old name/signature for the ~30 call sites that
/// already use it, but its *defaults* now match the spec's "large card"
/// tier (blur 20–30, opacity 8–14%, offset 0–8) instead of the old,
/// much heavier 45%-opacity version.
List<BoxShadow> softShadow({Color color = const Color(0xFF14211A), double opacity = 0.10}) {
  return [
    BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: 24,
      offset: const Offset(0, 6),
      spreadRadius: -6,
    ),
    BoxShadow(
      color: color.withValues(alpha: opacity * 0.5),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
}

/// Shadow tier for small controls (buttons, chips, compact cards):
/// blur 8–16, opacity 5–10%, offset 0–3.
List<BoxShadow> controlShadow({Color color = const Color(0xFF14211A), double opacity = 0.07}) {
  return [
    BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: 12,
      offset: const Offset(0, 2),
      spreadRadius: -4,
    ),
  ];
}

/// Explicit alias for the "large card" tier, for new code — same values as
/// `softShadow`'s defaults, kept as a separate name so intent is clear at
/// the call site.
List<BoxShadow> cardShadow({Color color = const Color(0xFF14211A), double opacity = 0.10}) {
  return softShadow(color: color, opacity: opacity);
}

/// Restrained green glow for primary CTAs — toned down from the previous
/// 0.28 opacity so it reads as a hint of depth, not a halo.
List<BoxShadow> mintGlow({Color color = const Color(0xFF3FAF6A), double opacity = 0.14}) {
  return [
    BoxShadow(
      color: color.withValues(alpha: opacity),
      blurRadius: 20,
      offset: const Offset(0, 4),
      spreadRadius: -6,
    ),
  ];
}
