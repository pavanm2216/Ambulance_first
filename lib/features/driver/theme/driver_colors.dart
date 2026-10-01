import 'package:flutter/material.dart';

/// Design tokens extracted directly from Stitch MCP Project 15205856723727982878
/// Design System: "Emergency Response Console"
class DriverColors {
  DriverColors._();

  // Primary Clinical Cobalt Brand Palette
  static const Color primary = Color(0xFF00507D);
  static const Color primaryContainer = Color(0xFF0369A1);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFFCBE4FF);
  static const Color primaryFixed = Color(0xFFCDE5FF);
  static const Color primaryFixedDim = Color(0xFF94CCFF);
  static const Color onPrimaryFixed = Color(0xFF001D32);
  static const Color inversePrimary = Color(0xFF94CCFF);

  // Secondary Operational Emerald Palette
  static const Color secondary = Color(0xFF006C4A);
  static const Color secondaryContainer = Color(0xFF9AF1C6);
  static const Color secondaryContainerDim = Color(0xFF82F5C1);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF002114);
  static const Color secondaryFixed = Color(0xFF85F8C4);
  static const Color secondaryFixedDim = Color(0xFF68DBA9);

  // Tertiary Code Red & Emergency Palette
  static const Color tertiary = Color(0xFFDC2626);
  static const Color tertiaryDark = Color(0xFF9D000D);
  static const Color tertiaryContainer = Color(0xFFC7121A);
  static const Color onTertiary = Color(0xFFFFFFFF);
  static const Color onTertiaryContainer = Color(0xFFFFDAD6);
  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF93000A);

  // Urgent Amber / Warning
  static const Color warning = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarning = Color(0xFFFFFFFF);
  static const Color onWarningContainer = Color(0xFF92400E);

  // Neutral & Clinical Slate Surface Palette
  static const Color background = Color(0xFFF8F9FF);
  static const Color onBackground = Color(0xFF0B1C30);
  static const Color surface = Color(0xFFF8F9FF);
  static const Color onSurface = Color(0xFF0B1C30);
  static const Color onSurfaceVariant = Color(0xFF40474F);
  static const Color surfaceDim = Color(0xFFD3E4FE);
  static const Color surfaceBright = Color(0xFFF8F9FF);
  static const Color surfaceVariant = Color(0xFFDCE9FF);

  // Surface Containers (High Density Layering)
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF4FF);
  static const Color surfaceContainer = Color(0xFFE5EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDCE9FF);
  static const Color surfaceContainerHighest = Color(0xFFD3E4FE);

  // Inverse Surfaces for HUD, Night Telemetry & Map Overlays
  static const Color inverseSurface = Color(0xFF213145);
  static const Color inverseSurfaceDark = Color(0xFF131D2A);
  static const Color inverseOnSurface = Color(0xFFEAF1FF);
  static const Color hudBorder = Color(0xFF2E445F);

  // Hairline Borders & Outlines
  static const Color outline = Color(0xFF707881);
  static const Color outlineVariant = Color(0xFFC0C7D1);
  static const Color surfaceTint = Color(0xFF006399);

  // Status Indicator Colors
  static const Color liveTelemetry = Color(0xFF10B981);
  static const Color staleTelemetry = Color(0xFFF59E0B);
  static const Color unavailableTelemetry = Color(0xFFEF4444);
}
