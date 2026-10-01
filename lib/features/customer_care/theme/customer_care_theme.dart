import 'package:flutter/material.dart';
import 'customer_care_colors.dart';
import 'customer_care_text_styles.dart';

class CustomerCareTheme {
  CustomerCareTheme._();

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: CustomerCareColors.background,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: CustomerCareColors.primary,
        onPrimary: CustomerCareColors.onPrimary,
        primaryContainer: CustomerCareColors.primaryContainer,
        onPrimaryContainer: CustomerCareColors.onPrimaryContainer,
        secondary: CustomerCareColors.secondary,
        onSecondary: CustomerCareColors.onSecondary,
        secondaryContainer: CustomerCareColors.secondaryContainer,
        onSecondaryContainer: CustomerCareColors.onSecondaryContainer,
        tertiary: CustomerCareColors.tertiary,
        onTertiary: CustomerCareColors.onTertiary,
        tertiaryContainer: CustomerCareColors.tertiaryContainer,
        onTertiaryContainer: CustomerCareColors.onTertiaryContainer,
        error: CustomerCareColors.error,
        onError: CustomerCareColors.onError,
        errorContainer: CustomerCareColors.errorContainer,
        onErrorContainer: CustomerCareColors.onErrorContainer,
        surface: CustomerCareColors.surface,
        onSurface: CustomerCareColors.onSurface,
        onSurfaceVariant: CustomerCareColors.onSurfaceVariant,
        outline: CustomerCareColors.outline,
        outlineVariant: CustomerCareColors.outlineVariant,
        inverseSurface: CustomerCareColors.inverseSurface,
        onInverseSurface: CustomerCareColors.inverseOnSurface,
        inversePrimary: CustomerCareColors.inversePrimary,
        surfaceTint: CustomerCareColors.surfaceTint,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CustomerCareColors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: CustomerCareColors.outlineVariant, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: CustomerCareColors.primaryContainer, width: 1.5),
        ),
        hintStyle: CustomerCareTextStyles.bodyMd.copyWith(
          color: CustomerCareColors.onSurfaceVariant,
        ),
      ),
      cardTheme: CardThemeData(
        color: CustomerCareColors.surfaceContainerLowest,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: CustomerCareColors.outlineVariant, width: 0.8),
        ),
        margin: EdgeInsets.zero,
      ),
    );
  }
}
