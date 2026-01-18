import 'package:flutter/material.dart';

/// Application color palette
/// Centralized color definitions for consistent theming
class AppColors {
  AppColors._(); // Private constructor to prevent instantiation

  // Primary Colors
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryLight = Color(0xFF818CF8);
  static const Color primaryDark = Color(0xFF4F46E5);

  // Background Colors
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);

  // Accent Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Song Card Specific
  static const Color iconGradientStart = primary;
  static const Color iconGradientEnd = primaryLight;
  static const Color keyBadgeBackground = Color(0xFFEEF2FF); // Light indigo
  static const Color keyBadgeText = primary;

  // Divider & Borders
  static const Color divider = Color(0xFFE5E7EB);
  static const Color border = Color(0xFFD1D5DB);

  // Song Section Colors
  // Song Section Colors (Polished Material 3 style)

  static const Color verseBackground = Color(0xFFF7F8FA);
  static const Color verseBorder = Color(0xFFE1E4EC);
  static const Color preChorusBackground = Color(0xFFF1F0FF);
  static const Color preChorusBorder = Color(0xFF8C86E8);
  static const Color bridgeBackground = Color(0xFFF0F7F2);
  static const Color bridgeBorder = Color(0xFF6FBF8A);

  static const Color verseText = Color(0xFF374151); // Cool dark gray
  static const Color preChorusText = Color(0xFF4338CA); // Indigo-700
  static const Color bridgeText = Color(0xFF166534);

  static const Color chorusBackground = Color(0xFFFFF7E6); // Soft warm cream
  static const Color chorusBorder = Color(0xFFFFC86B); // Muted amber
  static const Color chorusText = Color(0xFF8A5A00);

  // Surface variants (Material 3 style)
  static const Color surfaceContainerLow = Color(0xFFFAFAFA);
  static const Color surfaceContainer = Color(0xFFF5F5F5);
  static const Color surfaceContainerHigh = Color(0xFFEFEFEF);

  static const Color keyBadgeTransposedBackground = Color(0xFFE8DEF8);
  static const Color keyBadgeTransposedText = Color(0xFF1D192B);

  // === NEW: User Preferred Keys (e.g., Teal/Green) ===
  // Using a distinct color to show it's a user setting
  static const Color keyBadgePreferredBackground = Color(
    0xFFC4E7FF,
  ); // A light teal/blue
  static const Color keyBadgePreferredText = Color(0xFF001E2F);
}
