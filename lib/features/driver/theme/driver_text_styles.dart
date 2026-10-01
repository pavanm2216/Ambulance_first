import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'driver_colors.dart';

/// Driver typography using Public Sans for UI controls and JetBrains Mono for telemetry & IDs
class DriverTextStyles {
  DriverTextStyles._();

  static TextStyle get _sans => GoogleFonts.publicSans();
  static TextStyle get _mono => GoogleFonts.jetBrainsMono();

  // Primary UI Typography (Public Sans)
  static TextStyle headlineLarge = _sans.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: DriverColors.onSurface,
    letterSpacing: -0.5,
    height: 1.25,
  );

  static TextStyle headlineMedium = _sans.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: DriverColors.onSurface,
    letterSpacing: -0.3,
    height: 1.3,
  );

  static TextStyle headlineSmall = _sans.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: DriverColors.onSurface,
    letterSpacing: -0.2,
    height: 1.35,
  );

  static TextStyle titleMedium = _sans.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: DriverColors.onSurface,
    height: 1.3,
  );

  static TextStyle titleSmall = _sans.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: DriverColors.onSurface,
    height: 1.3,
  );

  static TextStyle bodyLarge = _sans.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: DriverColors.onSurface,
    height: 1.45,
  );

  static TextStyle bodyMedium = _sans.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: DriverColors.onSurfaceVariant,
    height: 1.4,
  );

  static TextStyle bodySmall = _sans.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: DriverColors.onSurfaceVariant,
    height: 1.35,
  );

  static TextStyle button = _sans.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.2,
  );

  // Operational Telemetry & Identifiers (JetBrains Mono)
  static TextStyle telemetryLarge = _mono.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    height: 1.1,
  );

  static TextStyle telemetryMedium = _mono.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    height: 1.2,
  );

  static TextStyle telemetrySmall = _mono.copyWith(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
  );

  static TextStyle telemetryMicro = _mono.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static TextStyle bookingId = _mono.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  static TextStyle timestamp = _mono.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );
}
