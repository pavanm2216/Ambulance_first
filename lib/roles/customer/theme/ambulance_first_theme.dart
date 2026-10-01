import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Clinical-Grade Design Tokens for Ambulance First Customer Portal.
/// Sourced directly from Stitch project 5751480897733590618
/// ("Clinical High-Density Operations").
class AmbulanceFirstColors {
  AmbulanceFirstColors._();

  // Primary Clinical Cobalt
  static const Color primary = Color(0xFF00385A);
  static const Color clinicalCobalt = Color(0xFF00507D); // Principal brand & action
  static const Color primaryContainer = Color(0xFF00507D);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF8AC2F5);
  static const Color primaryFixed = Color(0xFFCDE5FF);
  static const Color onPrimaryFixed = Color(0xFF001D32);
  static const Color surfaceTint = Color(0xFF236391);

  // Secondary Operational Emerald
  static const Color secondary = Color(0xFF006C4A);
  static const Color secondaryContainer = Color(0xFF9AF1C6);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF0B714E);
  static const Color secondaryFixed = Color(0xFF9DF4C9);
  static const Color onSecondaryFixed = Color(0xFF002114);

  // Tertiary Specialist Violet
  static const Color tertiary = Color(0xFF2000B5);
  static const Color tertiaryContainer = Color(0xFF392CD1);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFB8B6FF);
  static const Color tertiaryFixed = Color(0xFFE2DFFF);
  static const Color onTertiaryFixed = Color(0xFF0E006A);

  // Critical / Code Red / Error
  static const Color error = Color(0xFFBA1A1A);
  static const Color medicalCrimson = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Urgent Amber / Warning
  static const Color warning = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarning = Color(0xFF92400E);

  // Telemetry States
  static const Color telemetryLive = Color(0xFF10B981);
  static const Color telemetryStale = Color(0xFFF59E0B);
  static const Color telemetryUnavailable = Color(0xFFEF4444);

  // Surface Hierarchy (Clinical Light Mode)
  static const Color surface = Color(0xFFF8F9FF); // Base Canvas
  static const Color surfaceBright = Color(0xFFF8F9FF);
  static const Color surfaceDim = Color(0xFFCBDBF6);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF); // Card interiors, active inputs
  static const Color surfaceContainerLow = Color(0xFFEFF4FF); // Sidebars, sub-panels
  static const Color surfaceContainer = Color(0xFFE6EEFF); // Groupings, inactive rows
  static const Color surfaceContainerHigh = Color(0xFFDDE9FF); // Hover targets, headers
  static const Color surfaceContainerHighest = Color(0xFFD3E3FF);

  // Text & Accents
  static const Color onSurface = Color(0xFF0B1C30);
  static const Color onSurfaceVariant = Color(0xFF41474F);
  static const Color outline = Color(0xFF717880);
  static const Color outlineVariant = Color(0xFFC1C7D0);
  static const Color borderSubtle = Color(0xFFE2E8F0);
  static const Color textMuted = Color(0xFF64748B);
}

class AmbulanceFirstSpacing {
  AmbulanceFirstSpacing._();

  static const double space2xs = 4.0;
  static const double spaceXs = 8.0;
  static const double spaceSm = 12.0;
  static const double spaceMd = 20.0;
  static const double spaceLg = 32.0;
  static const double spaceXl = 48.0;

  static const double gutter = 12.0;
  static const double gutterCompact = 8.0;
  static const double margin = 20.0;
  static const double marginMobile = 12.0;

  // Radii
  static const double radiusSm = 4.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radiusPill = 9999.0;
}

class AmbulanceFirstTypography {
  AmbulanceFirstTypography._();

  // Primary Interface Sans (Inter)
  static TextStyle displayLg({Color color = AmbulanceFirstColors.onSurface}) =>
      GoogleFonts.inter(fontSize: 32, fontWeight: FontWeight.w700, height: 40 / 32, letterSpacing: -0.64, color: color);

  static TextStyle displayMd({Color color = AmbulanceFirstColors.onSurface}) =>
      GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w700, height: 32 / 24, letterSpacing: -0.36, color: color);

  static TextStyle headlineLg({Color color = AmbulanceFirstColors.onSurface}) =>
      GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, height: 28 / 20, letterSpacing: -0.2, color: color);

  static TextStyle headlineMd({Color color = AmbulanceFirstColors.onSurface}) =>
      GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, height: 24 / 18, letterSpacing: -0.18, color: color);

  static TextStyle headlineSm({Color color = AmbulanceFirstColors.onSurface}) =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, height: 22 / 16, color: color);

  static TextStyle bodyLg({Color color = AmbulanceFirstColors.onSurface}) =>
      GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w400, height: 24 / 16, color: color);

  static TextStyle bodyMd({Color color = AmbulanceFirstColors.onSurface}) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, height: 20 / 14, color: color);

  static TextStyle bodySm({Color color = AmbulanceFirstColors.onSurfaceVariant}) =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, height: 16 / 12, color: color);

  static TextStyle labelLg({Color color = AmbulanceFirstColors.onSurface}) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, height: 20 / 14, color: color);

  static TextStyle labelMd({Color color = AmbulanceFirstColors.onSurface}) =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, height: 16 / 12, color: color);

  static TextStyle labelSm({Color color = AmbulanceFirstColors.onSurfaceVariant}) =>
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, height: 14 / 11, color: color);

  // Operational Telemetry Monospace (JetBrains Mono)
  static TextStyle codeLg({Color color = AmbulanceFirstColors.onSurface, FontWeight weight = FontWeight.w600}) =>
      GoogleFonts.jetBrainsMono(fontSize: 14, fontWeight: weight, height: 20 / 14, color: color);

  static TextStyle codeMd({Color color = AmbulanceFirstColors.onSurface, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.jetBrainsMono(fontSize: 12, fontWeight: weight, height: 16 / 12, color: color);

  static TextStyle codeSm({Color color = AmbulanceFirstColors.onSurfaceVariant, FontWeight weight = FontWeight.w500}) =>
      GoogleFonts.jetBrainsMono(fontSize: 11, fontWeight: weight, height: 14 / 11, color: color);

  static TextStyle telemetryNum({Color color = AmbulanceFirstColors.onSurface, double size = 20}) =>
      GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: FontWeight.w700, height: 24 / 20, letterSpacing: -0.6, color: color);
}

class AmbulanceFirstTheme {
  AmbulanceFirstTheme._();

  static ThemeData lightTheme() {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AmbulanceFirstColors.surface,
      colorScheme: const ColorScheme.light(
        primary: AmbulanceFirstColors.clinicalCobalt,
        onPrimary: AmbulanceFirstColors.onPrimary,
        primaryContainer: AmbulanceFirstColors.primaryContainer,
        onPrimaryContainer: AmbulanceFirstColors.onPrimaryContainer,
        secondary: AmbulanceFirstColors.secondary,
        onSecondary: AmbulanceFirstColors.onSecondary,
        secondaryContainer: AmbulanceFirstColors.secondaryContainer,
        onSecondaryContainer: AmbulanceFirstColors.onSecondaryContainer,
        tertiary: AmbulanceFirstColors.tertiaryContainer,
        surface: AmbulanceFirstColors.surface,
        onSurface: AmbulanceFirstColors.onSurface,
        onSurfaceVariant: AmbulanceFirstColors.onSurfaceVariant,
        error: AmbulanceFirstColors.medicalCrimson,
        errorContainer: AmbulanceFirstColors.errorContainer,
        onError: AmbulanceFirstColors.onError,
        onErrorContainer: AmbulanceFirstColors.onErrorContainer,
        outline: AmbulanceFirstColors.outline,
        outlineVariant: AmbulanceFirstColors.outlineVariant,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AmbulanceFirstColors.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AmbulanceFirstTypography.headlineSm(color: AmbulanceFirstColors.onSurface),
        iconTheme: const IconThemeData(color: AmbulanceFirstColors.onSurfaceVariant),
      ),
      cardTheme: CardThemeData(
        color: AmbulanceFirstColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusMd),
          side: const BorderSide(color: AmbulanceFirstColors.borderSubtle, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AmbulanceFirstColors.borderSubtle,
        thickness: 1,
        space: 1,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AmbulanceFirstColors.clinicalCobalt,
          foregroundColor: AmbulanceFirstColors.onPrimary,
          textStyle: AmbulanceFirstTypography.labelLg(color: AmbulanceFirstColors.onPrimary),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusSm),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AmbulanceFirstColors.clinicalCobalt,
          side: const BorderSide(color: AmbulanceFirstColors.outlineVariant),
          textStyle: AmbulanceFirstTypography.labelLg(color: AmbulanceFirstColors.clinicalCobalt),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusSm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AmbulanceFirstColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusSm),
          borderSide: const BorderSide(color: AmbulanceFirstColors.borderSubtle),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusSm),
          borderSide: const BorderSide(color: AmbulanceFirstColors.borderSubtle),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusSm),
          borderSide: const BorderSide(color: AmbulanceFirstColors.clinicalCobalt, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AmbulanceFirstSpacing.radiusSm),
          borderSide: const BorderSide(color: AmbulanceFirstColors.medicalCrimson),
        ),
        labelStyle: AmbulanceFirstTypography.bodyMd(color: AmbulanceFirstColors.onSurfaceVariant),
        hintStyle: AmbulanceFirstTypography.bodyMd(color: AmbulanceFirstColors.textMuted),
      ),
    );
  }
}
