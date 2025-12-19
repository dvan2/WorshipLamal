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
  static const Color chorusBackground = Color(0xFFFEF3C7); // Light yellow
  static const Color chorusBorder = Color(0xFFFBBF24); // Yellow
  static const Color verseBackground = Color(0xFFF3F4F6); // Light gray
  static const Color verseBorder = Color(0xFFD1D5DB); // Gray
  static const Color bridgeBackground = Color(0xFFDCFCE7); // Light green
  static const Color bridgeBorder = Color(0xFF34D399); // Green
  static const Color preChorusBackground = Color(0xFFE0E7FF); // Light indigo
  static const Color preChorusBorder = Color(0xFF818CF8); // Indigo

  // Surface variants (Material 3 style)
  static const Color surfaceContainerLow = Color(0xFFFAFAFA);
  static const Color surfaceContainer = Color(0xFFF5F5F5);
  static const Color surfaceContainerHigh = Color(0xFFEFEFEF);
}
