import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// App Typography based on Figma Design System
class AppTypography {
  AppTypography._();

  /// Heading 1 - This is PropLinq (36px)
  static TextStyle h1 = GoogleFonts.gabarito(
    fontSize: 36,
    fontWeight: FontWeight.w700, // Bold
    height: 1.2,
    letterSpacing: -0.5,
    color: AppColors.onBackground,
  );

  /// Heading 2 - This is PropLinq (32px)
  static TextStyle h2 = GoogleFonts.gabarito(
    fontSize: 32,
    fontWeight: FontWeight.w600, // Semi-bold
    height: 1.25,
    letterSpacing: -0.4,
    color: AppColors.onBackground,
  );

  /// Heading 3 - This is PropLinq (28px)
  static TextStyle h3 = GoogleFonts.gabarito(
    fontSize: 24,
    fontWeight: FontWeight.w700, // Semi-bold
    height: 1.3,
    letterSpacing: -0.3,
    color: AppColors.onBackground,
  );

  /// Heading 4 - This is PropLinq (24px)
  static TextStyle h4 = GoogleFonts.gabarito(
    fontSize: 24,
    fontWeight: FontWeight.w600, // Semi-bold
    height: 1.35,
    letterSpacing: -0.2,
    color: AppColors.onBackground,
  );

  /// Heading 5 - This is PropLinq (20px)
  static TextStyle h5 = GoogleFonts.gabarito(
    fontSize: 20,
    fontWeight: FontWeight.w500, // Medium
    height: 1.4,
    letterSpacing: -0.1,
    color: AppColors.onBackground,
  );

  /// Heading 6 - This is PropLinq (18px)
  static TextStyle h6 = GoogleFonts.gabarito(
    fontSize: 18,
    fontWeight: FontWeight.w500, // Medium
    height: 1.45,
    letterSpacing: 0,
    color: AppColors.onBackground,
  );

  /// Body Large - Regular body text (16px)
  static TextStyle bodyLarge = GoogleFonts.gabarito(
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular
    height: 1.5,
    letterSpacing: 0,
    color: AppColors.onBackground,
  );

  /// Body Medium - Medium body text (14px)
  static TextStyle bodyMedium = GoogleFonts.gabarito(
    fontSize: 14,
    fontWeight: FontWeight.w400, // Regular
    height: 1.5,
    letterSpacing: 0,
    color: AppColors.onBackground,
  );

  /// Body Small - Small body text (12px)
  static TextStyle bodySmall = GoogleFonts.gabarito(
    fontSize: 12,
    fontWeight: FontWeight.w400, // Regular
    height: 1.5,
    letterSpacing: 0.2,
    color: AppColors.onBackground,
  );

  /// Caption - Caption text (11px)
  static TextStyle caption = GoogleFonts.gabarito(
    fontSize: 11,
    fontWeight: FontWeight.w400, // Regular
    height: 1.4,
    letterSpacing: 0.3,
    color: AppColors.grey600,
  );

  /// Label Large - Button and form labels (14px)
  static TextStyle labelLarge = GoogleFonts.gabarito(
    fontSize: 14,
    fontWeight: FontWeight.w500, // Medium
    height: 1.4,
    letterSpacing: 0.1,
    color: AppColors.onBackground,
  );

  /// Label Medium - Small button labels (12px)
  static TextStyle labelMedium = GoogleFonts.gabarito(
    fontSize: 12,
    fontWeight: FontWeight.w500, // Medium
    height: 1.3,
    letterSpacing: 0.4,
    color: AppColors.onBackground,
  );

  /// Label Small - Tiny labels (10px)
  static TextStyle labelSmall = GoogleFonts.gabarito(
    fontSize: 10,
    fontWeight: FontWeight.w500, // Medium
    height: 1.2,
    letterSpacing: 0.5,
    color: AppColors.grey600,
  );

  // Specific text styles for PropLinq branding
  static TextStyle propLinqLogo = GoogleFonts.gabarito(
    fontSize: 24,
    fontWeight: FontWeight.w700, // Bold
    height: 1.2,
    letterSpacing: -0.2,
    color: AppColors.primary600,
  );

  static TextStyle propLinqTagline = GoogleFonts.gabarito(
    fontSize: 16,
    fontWeight: FontWeight.w400, // Regular
    height: 1.4,
    letterSpacing: 0,
    color: AppColors.grey600,
  );
} 