import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'customer_care_colors.dart';

/// Typography extracted from Stitch MCP Project 1449624092268908152:
/// - Inter for UI headlines, body copy, clinical narrative, and forms.
/// - JetBrains Mono for telemetry, booking IDs, timers, coordinates, and vital readouts.
class CustomerCareTextStyles {
  CustomerCareTextStyles._();

  static TextStyle get _sans => GoogleFonts.inter();
  static TextStyle get _mono => GoogleFonts.jetBrainsMono();

  // Telemetry & Code Readouts (JetBrains Mono)
  static TextStyle telemetryDisplay = _mono.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 20 / 18,
    letterSpacing: -0.01 * 18,
    color: CustomerCareColors.primary,
  );

  static TextStyle labelLg = _mono.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    height: 16 / 13,
    letterSpacing: 0.02 * 13,
    color: CustomerCareColors.onSurface,
  );

  static TextStyle labelMd = _mono.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 14 / 11,
    letterSpacing: 0.03 * 11,
    color: CustomerCareColors.onSurfaceVariant,
  );

  static TextStyle labelSm = _mono.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    height: 12 / 10,
    letterSpacing: 0.04 * 10,
    color: CustomerCareColors.onSurfaceVariant,
  );

  // Headlines (Inter)
  static TextStyle headlineLg = _sans.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 36 / 28,
    letterSpacing: -0.02 * 28,
    color: CustomerCareColors.onSurface,
  );

  static TextStyle headlineLgMobile = _sans.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 28 / 22,
    letterSpacing: -0.01 * 22,
    color: CustomerCareColors.onSurface,
  );

  static TextStyle headlineMd = _sans.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 26 / 20,
    letterSpacing: -0.01 * 20,
    color: CustomerCareColors.onSurface,
  );

  static TextStyle headlineSm = _sans.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 22 / 16,
    color: CustomerCareColors.onSurface,
  );

  // Body Narrative (Inter)
  static TextStyle bodyLg = _sans.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    height: 22 / 15,
    color: CustomerCareColors.onSurface,
  );

  static TextStyle bodyMd = _sans.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 18 / 13,
    color: CustomerCareColors.onSurface,
  );

  static TextStyle bodySm = _sans.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 16 / 12,
    color: CustomerCareColors.onSurfaceVariant,
  );
}
