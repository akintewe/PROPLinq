import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App Typography based on Figma Design System
class AppTypography {
  AppTypography._();

  // Base font family - update this based on your chosen font
  static const String _fontFamily = 'Gabarito'; // iOS default, can be changed

  /// Heading 1 - This is PropLinq (36px)
  static const TextStyle h1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w700, // Bold
    height: 1.2,
    letterSpacing: -0.5,
    color: AppColors.onBackground,
  );

  /// Heading 2 - This is PropLinq (32px)
  static const TextStyle h2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600, // Semi-bold
    height: 1.25,
    letterSpacing: -0.4,
    color: AppColors.onBackground,
  );

  /// Heading 3 - This is PropLinq (28px)
  static const TextStyle h3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w600, // Semi-bold
    height: 1.3,
    letterSpacing: -0.3,
    color: AppColors.onBackground,
  );

  /// Heading 4 - This is PropLinq (24px)
  static const TextStyle h4 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600, // Semi-bold
    height: 1.35,
    letterSpacing: -0.2,
    color: AppColors.onBackground,
  );

  /// Heading 5 - This is PropLinq (20px)
  static const TextStyle h5 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w500, // Medium
    height: 1.4,
    letterSpacing: -0.1,
    color: AppColors.onBackground,
  );

  /// Heading 6 - This is PropLinq (18px)
  static const TextStyle h6 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w500, // Medium
    height: 1.45,
    letterSpacing: 0,
    color: AppColors.onBackground,
  );

  /// Body Large - Regular body text (16px)
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular
    height: 1.5,
    letterSpacing: 0,
    color: AppColors.onBackground,
  );

  /// Body Medium - Medium body text (14px)
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    height: 1.5,
    letterSpacing: 0,
    color: AppColors.onBackground,
  );

  /// Body Small - Small body text (12px)
  static const TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400, // Regular
    height: 1.5,
    letterSpacing: 0.2,
    color: AppColors.onBackground,
  );

  /// Caption - Caption text (11px)
  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w400, // Regular
    height: 1.4,
    letterSpacing: 0.3,
    color: AppColors.grey600,
  );

  /// Label Large - Button and form labels (14px)
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500, // Medium
    height: 1.4,
    letterSpacing: 0.1,
    color: AppColors.onBackground,
  );

  /// Label Medium - Small button labels (12px)
  static const TextStyle labelMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500, // Medium
    height: 1.3,
    letterSpacing: 0.4,
    color: AppColors.onBackground,
  );

  /// Label Small - Tiny labels (10px)
  static const TextStyle labelSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w500, // Medium
    height: 1.2,
    letterSpacing: 0.5,
    color: AppColors.grey600,
  );

  // Specific text styles for PropLinq branding
  static const TextStyle propLinqLogo = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w700, // Bold
    height: 1.2,
    letterSpacing: -0.2,
    color: AppColors.primary600,
  );

  static const TextStyle propLinqTagline = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular
    height: 1.4,
    letterSpacing: 0,
    color: AppColors.grey600,
  );
} 