import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ambulance First Clinical-Grade Emergency Medical Transport v2 (Light Mode)
/// Visual source of truth for the Team Lead Portal.
class TeamLeadTheme {
  TeamLeadTheme._();

  // Canvas & Background
  static const Color canvas = Color(0xFFF8F9FF);
  static const Color surface = Color(0xFFF8F9FF);

  // Surface Elevation Hierarchy (Light Tonal Layering)
  static const Color surfaceLowest = Color(0xFFFFFFFF);     // White card/panel floors
  static const Color surfaceLow = Color(0xFFF2F3F9);        // Low contrast container
  static const Color surfaceContainer = Color(0xFFECEEF3);  // Default container
  static const Color surfaceHigh = Color(0xFFE7E8EE);       // Elevated element
  static const Color surfaceHighest = Color(0xFFE1E2E8);    // Highest layer

  // Text & Content Hierarchy
  static const Color onSurface = Color(0xFF191C20);          // Primary text & headings
  static const Color onSurfaceVariant = Color(0xFF41474F);   // Secondary metadata
  static const Color textMuted = Color(0xFF707881);          // Muted labels/placeholders

  // Brand / Clinical Cobalt
  static const Color primary = Color(0xFF00507D);            // Primary brand cobalt
  static const Color primaryDark = Color(0xFF00385A);        // Deep navy
  static const Color clinicalCobalt = Color(0xFF0369A1);     // Vibrant cobalt
  static const Color primaryContainer = Color(0xFFCDE5FF);   // Soft cobalt tint
  static const Color onPrimary = Color(0xFFFFFFFF);          // Text on primary button

  // Secondary / Readiness
  static const Color operationalEmerald = Color(0xFF006C4A); // Available / Ready
  static const Color emeraldBg = Color(0xFFE6F4EA);          // Soft emerald container
  static const Color emeraldText = Color(0xFF004D34);

  // Critical / Code Red
  static const Color medicalCrimson = Color(0xFFDC2626);     // Emergency / Alerts
  static const Color crimsonBg = Color(0xFFFEE2E2);          // Crimson container
  static const Color crimsonText = Color(0xFF991B1B);

  // Warning / Queue
  static const Color urgentAmber = Color(0xFFD97706);        // Pending / Attention
  static const Color amberBg = Color(0xFFFEF3C7);            // Amber container
  static const Color amberText = Color(0xFF92400E);

  // Telemetry Colors
  static const Color telemetryLive = Color(0xFF10B981);       // Live GPS/ETA
  static const Color telemetryStale = Color(0xFFF59E0B);      // Telemetry delayed
  static const Color telemetryUnavailable = Color(0xFFEF4444);// No signal

  // Borders & Dividers
  static const Color outlineVariant = Color(0xFFC1C7D0);     // Structural borders
  static const Color borderSubtle = Color(0xFFE2E8F0);       // Table/card hairlines

  // Spacing Scale
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 16.0;
  static const double spaceXl = 24.0;
  static const double spaceXxl = 32.0;

  // Shapes & Radii
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusPill = 9999.0;

  // Typography Tokens (Inter for UI, JetBrains Mono for Telemetry)
  static TextStyle display({Color color = onSurface, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.inter(fontSize: 30, height: 38 / 30, fontWeight: weight, color: color);

  static TextStyle headline({Color color = onSurface, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.inter(fontSize: 22, height: 28 / 22, fontWeight: weight, color: color);

  static TextStyle titleMedium({Color color = onSurface, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.inter(fontSize: 17, height: 22 / 17, fontWeight: weight, color: color);

  static TextStyle body({Color color = onSurface, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.inter(fontSize: 15, height: 22 / 15, fontWeight: weight, color: color);

  static TextStyle supportingBody({Color color = onSurfaceVariant, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.inter(fontSize: 13, height: 18 / 13, fontWeight: weight, color: color);

  static TextStyle small({Color color = onSurfaceVariant, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.inter(fontSize: 12, height: 16 / 12, fontWeight: weight, color: color);

  static TextStyle micro({Color color = textMuted, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.inter(fontSize: 11, height: 14 / 11, fontWeight: weight, color: color);

  // Telemetry Tokens (JetBrains Mono)
  static TextStyle telemetryPrimary({Color color = onSurface, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.jetBrainsMono(fontSize: 13, height: 18 / 13, fontWeight: weight, color: color);

  static TextStyle telemetrySecondary({Color color = onSurfaceVariant, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.jetBrainsMono(fontSize: 11, height: 14 / 11, fontWeight: weight, color: color);

  static TextStyle telemetryMicro({Color color = textMuted, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.jetBrainsMono(fontSize: 10, height: 14 / 10, fontWeight: weight, color: color);
}
