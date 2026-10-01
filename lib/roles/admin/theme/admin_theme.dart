import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Stitch Design System Tokens for Emergency Medical Fleet Operations Portal
/// Primary Visual Identity: Clinical Cobalt (#0369a1)
/// Typography: Inter (Headlines & Body), JetBrains Mono (Telemetry & Labels)
class StitchTheme {
  StitchTheme._();

  // Primary Clinical Cobalt Palette
  static const Color primary = Color(0xFF00507D);
  static const Color primaryContainer = Color(0xFF0369A1); // Clinical Cobalt
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFCBE4FF);
  static const Color primaryFixed = Color(0xFFCDE5FF);
  static const Color primaryFixedDim = Color(0xFF94CCFF);
  static const Color onPrimaryFixed = Color(0xFF001D32);

  // Surface Hierarchy (Light Mode Canvas)
  static const Color background = Color(0xFFF8F9FF);
  static const Color surface = Color(0xFFF8F9FF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE5EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color surfaceContainerHighest = Color(0xFFD3E4FE);
  static const Color surfaceDim = Color(0xFFCBDBF5);

  // High-Contrast Content Colors
  static const Color onSurface = Color(0xFF0B1C30);
  static const Color onSurfaceVariant = Color(0xFF40474F);
  static const Color inverseSurface = Color(0xFF213145);
  static const Color inverseOnSurface = Color(0xFFEAF1FF);

  // Borders & Outlines
  static const Color outline = Color(0xFF707881);
  static const Color outlineVariant = Color(0xFFC0C7D1);
  static const Color borderSubtle = Color(0xFFE2E8F0);

  // Operational Telemetry Semantics
  // Tertiary: Available / Verified (Clinical Emerald)
  static const Color tertiary = Color(0xFF00573B);
  static const Color tertiaryContainer = Color(0xFF00724F);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color tertiaryFixed = Color(0xFF85F8C4);
  static const Color tertiaryFixedDim = Color(0xFF68DBA9);
  static const Color onTertiaryFixed = Color(0xFF002114);

  // Secondary: Tactical Slate & Nav Marine
  static const Color secondary = Color(0xFF565D79);
  static const Color secondaryContainer = Color(0xFFD8DEFF);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF5A627E);

  // Error / Alert: Emergency / Code Red (Crimson)
  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Warning / In-Transit (Amber)
  static const Color warning = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFFFBEB);
  static const Color onWarning = Color(0xFF92400E);

  // Central Command Tactical Chrome
  static const Color commandNavDark = Color(0xFF0B132B);
  static const Color commandNavMarine = Color(0xFF1C2541);

  // Spacing Scale
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 12.0;
  static const double spaceLg = 20.0;
  static const double spaceXl = 32.0;
  static const double margin = 16.0;

  // Border Radii
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusPill = 9999.0;

  // Typography Generators using Inter and JetBrains Mono
  static TextStyle headlineLg({Color color = onSurface, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.inter(fontSize: 22, height: 28 / 22, fontWeight: weight, color: color);

  static TextStyle headlineMd({Color color = onSurface, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.inter(fontSize: 18, height: 24 / 18, fontWeight: weight, color: color);

  static TextStyle headlineSm({Color color = onSurface, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.inter(fontSize: 15, height: 20 / 15, fontWeight: weight, color: color);

  static TextStyle displayLgMobile({Color color = onSurface, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.inter(fontSize: 24, height: 32 / 24, fontWeight: weight, color: color);

  static TextStyle displayLg({Color color = onSurface, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.inter(fontSize: 30, height: 38 / 30, fontWeight: weight, color: color);

  static TextStyle bodyLg({Color color = onSurface, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.inter(fontSize: 15, height: 22 / 15, fontWeight: weight, color: color);

  static TextStyle bodyMd({Color color = onSurface, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.inter(fontSize: 13, height: 18 / 13, fontWeight: weight, color: color);

  static TextStyle bodySm({Color color = onSurfaceVariant, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.inter(fontSize: 12, height: 16 / 12, fontWeight: weight, color: color);

  // JetBrains Mono for telemetry, IDs, timestamps, and codes
  static TextStyle labelLg({Color color = onSurface, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.jetBrainsMono(fontSize: 13, height: 16 / 13, fontWeight: weight, letterSpacing: 0.26, color: color);

  static TextStyle labelMd({Color color = onSurface, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.jetBrainsMono(fontSize: 11, height: 14 / 11, fontWeight: weight, letterSpacing: 0.44, color: color);

  static TextStyle labelSm({Color color = onSurfaceVariant, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.jetBrainsMono(fontSize: 10, height: 12 / 10, fontWeight: weight, letterSpacing: 0.6, color: color);

  // ThemeData for the Admin Portal
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primaryContainer,
        onPrimary: onPrimary,
        primaryContainer: primaryFixed,
        onPrimaryContainer: onPrimaryFixed,
        secondary: secondary,
        onSecondary: onSecondary,
        surface: surfaceContainerLowest,
        onSurface: onSurface,
        error: error,
        onError: onError,
      ),
      fontFamily: GoogleFonts.inter().fontFamily,
      cardTheme: CardThemeData(
        color: surfaceContainerLowest,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        foregroundColor: onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
    );
  }
}
