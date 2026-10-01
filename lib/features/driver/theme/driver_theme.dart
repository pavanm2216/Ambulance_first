import 'package:flutter/material.dart';
import 'driver_colors.dart';
import 'driver_text_styles.dart';

class DriverTheme {
  DriverTheme._();

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: DriverColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: DriverColors.primary,
        onPrimary: DriverColors.onPrimary,
        primaryContainer: DriverColors.primaryContainer,
        onPrimaryContainer: DriverColors.onPrimaryContainer,
        secondary: DriverColors.secondary,
        onSecondary: DriverColors.onSecondary,
        secondaryContainer: DriverColors.secondaryContainer,
        onSecondaryContainer: DriverColors.onSecondaryContainer,
        tertiary: DriverColors.tertiary,
        onTertiary: DriverColors.onTertiary,
        error: DriverColors.error,
        onError: DriverColors.onError,
        surface: DriverColors.surface,
        onSurface: DriverColors.onSurface,
        onSurfaceVariant: DriverColors.onSurfaceVariant,
        outline: DriverColors.outline,
        outlineVariant: DriverColors.outlineVariant,
      ),
      cardTheme: CardThemeData(
        color: DriverColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: DriverColors.surfaceContainerHigh, width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: DriverColors.primaryContainer,
          foregroundColor: Colors.white,
          textStyle: DriverTextStyles.button,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: DriverColors.primaryContainer,
          textStyle: DriverTextStyles.button,
          side: const BorderSide(color: DriverColors.outlineVariant, width: 1.2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: DriverColors.surfaceContainerLow,
        hintStyle: DriverTextStyles.bodyMedium,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DriverColors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DriverColors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: DriverColors.primaryContainer, width: 1.8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: DriverColors.surfaceContainerHigh,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
