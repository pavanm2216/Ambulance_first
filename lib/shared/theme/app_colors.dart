import 'package:flutter/material.dart';

/// Ambulance First / AeroMed Customer color system — premium light medical
/// green, per the Apple-inspired healthcare design spec.
///
/// Palette anchors (spec section 1):
/// - Primary Light Green: #62C98A
/// - Primary Green:       #3FAF6A
/// - Deep Green:          #238653
/// - Soft Green:          #E7F7ED
/// - Pale Green:          #F2FBF5
/// - Background:          #F6F8F7
/// - Surface:             #FFFFFF
/// - Elevated Surface:    #FCFEFD
///
/// Every identifier below is unchanged from the previous teal palette so
/// existing widgets (36+ files reference `AppColors.*` directly) keep
/// compiling — only the underlying values move from teal to green.
class AppColors {
  AppColors._();

  // Primary green palette
  static const Color primary = Color(0xFF3FAF6A); // Primary Green
  static const Color primaryFixedDim = Color(0xFF379B62);
  static const Color primaryDark = Color(0xFF238653); // Deep Green
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF163F26);
  static const Color primaryContainer = Color(0xFF62C98A); // Primary Light Green

  // Main canvas & light surface hierarchy
  static const Color appBackground = Color(0xFFF6F8F7); // Background
  static const Color surface = Color(0xFFFFFFFF); // Surface
  static const Color surfaceContainerLowest = Color(0xFFF2FBF5); // Pale Green
  static const Color surfaceContainerLow = Color(0xFFE7F7ED); // Soft Green
  static const Color surfaceContainer = Color(0xFFFCFEFD); // Elevated Surface
  static const Color surfaceContainerHigh = Color(0xFFFFFFFF);
  static const Color surfaceContainerHighest = Color(0xFFE7F7ED); // Soft Green (selected states)
  static const Color surfaceBright = Color(0xFFFFFFFF);

  // Lighter green accents
  static const Color secondary = Color(0xFF62C98A); // Primary Light Green
  static const Color secondaryContainer = Color(0xFFE7F7ED); // Soft Green
  static const Color onSecondary = Color(0xFF238653);
  static const Color onSecondaryContainer = Color(0xFF238653); // Deep Green text on soft-green btn
  static const Color tertiary = Color(0xFFF2FBF5); // Pale Green
  static const Color tertiaryContainer = Color(0xFFE7F7ED); // Soft Green
  static const Color onTertiary = Color(0xFF238653);
  static const Color onTertiaryContainer = Color(0xFF238653);

  // Tactile light cards
  static const Color tactileCard = Color(0xFFFFFFFF); // Surface
  static const Color tactileCardOffWhite = Color(0xFFFCFEFD); // Elevated Surface
  static const Color tactileCardSubtle = Color(0xFFF2FBF5); // Pale Green
  static const Color tactileCardBorder = Color(0xFFE1E9E4); // Border
  static const Color onTactileCard = Color(0xFF14211A); // Primary Text
  static const Color onTactileCardSecondary = Color(0xFF66736C); // Secondary Text
  static const Color onTactileCardMuted = Color(0xFF929D97); // Muted Text

  // Typography and borders
  static const Color textPrimary = Color(0xFF14211A);
  static const Color textSecondary = Color(0xFF66736C);
  static const Color textMuted = Color(0xFF929D97);
  static const Color outline = Color(0xFFE1E9E4); // Border
  static const Color outlineVariant = Color(0xFFEDF2EF);

  // Semantic emergency colors — intentionally not part of the green brand
  static const Color error = Color(0xFFD95353);
  static const Color urgentRed = Color(0xFFD95353);
  static const Color errorContainer = Color(0xFFFBEAEA);
  static const Color errorSoft = Color(0xFFFBEAEA);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF7A2323);

  // Navigation / floating dock
  static const Color navDark = Color(0xFFFFFFFF);
  static const Color navContainer = Color(0xFFFCFEFD);

  // Compatibility aliases
  static const Color white = Color(0xFFFFFFFF);
  static const Color lavender = surfaceContainerLow;
  static const Color surfaceMuted = surfaceContainerLow;
  static const Color border = outline;
  static const Color primarySoft = secondaryContainer;
  static const Color primaryDeep = primaryDark;
  static const Color primaryPale = Color(0xFFF2FBF5); // Pale Green
  static const Color tint = secondaryContainer;
  static const Color medicalGreen = primary;
  static const Color medicalGreenDark = primaryDark;
  static const Color medicalSoft = secondaryContainer;
  static const Color warning = Color(0xFFD99A32);
  static const Color warningSoft = Color(0xFFFCEFDA);
  static const Color success = Color(0xFF32A866);
  static const Color successSoft = Color(0xFFE3F5EA);

  static (Color bg, Color fg) statusColors(String status) {
    switch (status) {
      case 'Confirmed':
      case 'Assigned':
        return (secondaryContainer, primaryDark);
      case 'On the Way':
      case 'Ready to Dispatch':
        return (primary, onPrimary);
      case 'Completed':
        return (successSoft, success);
      case 'Cancelled':
        return (errorSoft, urgentRed);
      case 'Pending':
      case 'Awaiting review':
      default:
        return (warningSoft, warning);
    }
  }
}
