import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import './app_colors.dart';

/// Centralized typographic scale derived from Stitch MCP typography design tokens:
/// - Primary Typeface: Plus Jakarta Sans (humanist geometric clarity)
/// - Telemetry & Data Typeface: Space Grotesk (aviation & clinical telematics fidelity)
///
/// Spec section 8 asks for `.SF Pro Display` "when available/appropriate,
/// otherwise the platform/system sans-serif". `.SF Pro Display` is not a
/// bundled font — it's the reserved name Flutter/Skia resolve to the
/// system font already installed on iOS/macOS, so it only actually
/// renders as SF Pro on Apple platforms and would silently fall back to
/// each OS's default elsewhere anyway. `_isApplePlatform` makes that
/// explicit: Apple platforms get the literal system font, every other
/// platform keeps Plus Jakarta Sans / Space Grotesk, which was already
/// chosen for its Apple-editorial character and renders consistently on
/// Android, Windows, and web.
class AppTextStyles {
  AppTextStyles._();

  static bool get _isApplePlatform =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS);

  static TextStyle get _sans =>
      _isApplePlatform ? const TextStyle(fontFamily: '.SF Pro Display') : GoogleFonts.plusJakartaSans();
  static TextStyle get _mono =>
      _isApplePlatform ? const TextStyle(fontFamily: '.SF Pro Text') : GoogleFonts.spaceGrotesk();

  // Plus Jakarta Sans Display & Headlines
  static TextStyle displayLarge = _sans.copyWith(
    fontSize: 44,
    fontWeight: FontWeight.w800,
    height: 52 / 44,
    letterSpacing: -1.3,
    color: AppColors.textPrimary,
  );

  static TextStyle displaySmall = _sans.copyWith(
    fontSize: 34,
    fontWeight: FontWeight.w700,
    height: 40 / 34,
    letterSpacing: -0.85,
    color: AppColors.textPrimary,
  );

  static TextStyle headlineLarge = _sans.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 34 / 28,
    letterSpacing: -0.56,
    color: AppColors.textPrimary,
  );

  static TextStyle headlineMedium = _sans.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 28 / 22,
    letterSpacing: -0.33,
    color: AppColors.textPrimary,
  );

  static TextStyle headlineSmall = _sans.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 24 / 18,
    letterSpacing: -0.18,
    color: AppColors.textPrimary,
  );

  // Plus Jakarta Sans Body
  static TextStyle bodyLarge = _sans.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    letterSpacing: -0.08,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = _sans.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
    letterSpacing: 0,
    color: AppColors.textPrimary,
  );

  static TextStyle bodySmall = _sans.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    letterSpacing: 0.12,
    color: AppColors.textSecondary,
  );

  // Space Grotesk Telemetry, Routes & Labels
  static TextStyle routeIndicator = _mono.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 24 / 20,
    letterSpacing: -0.4,
    color: AppColors.textPrimary,
  );

  static TextStyle telemetryMetric = _mono.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 18 / 15,
    letterSpacing: 0.3,
    color: AppColors.textPrimary,
  );

  static TextStyle labelMedium = _mono.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 14 / 12,
    letterSpacing: 0.72,
    color: AppColors.textSecondary,
  );

  static TextStyle labelSmall = _mono.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 12 / 10,
    letterSpacing: 0.8,
    color: AppColors.textSecondary,
  );

  // Semantic Aliases for compatibility
  static TextStyle get display => displaySmall;
  static TextStyle get pageTitle => headlineLarge;
  static TextStyle get sectionTitle => headlineMedium;
  static TextStyle get cardTitle => headlineSmall;
  static TextStyle get body => bodyMedium;
  static TextStyle get bodyStrong => bodyMedium.copyWith(fontWeight: FontWeight.w600);
  static TextStyle get supporting => bodySmall;
  static TextStyle get supportingStrong => bodySmall.copyWith(fontWeight: FontWeight.w600);
  static TextStyle get caption => labelSmall;
  static TextStyle get button => _mono.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
        color: AppColors.onPrimary,
      );
}
