import 'package:flutter/material.dart';

/// App Colors based on Figma Design System
class AppColors {
  AppColors._();

  // PRIMARY Colors (Blue gradient from Figma)
  static const Color primary50 = Color(0xFFEBF3FF);
  static const Color primary100 = Color(0xFFDBEAFF);
  static const Color primary200 = Color(0xFFBFDBFF);
  static const Color primary300 = Color(0xFF98C6FF);
  static const Color primary400 = Color(0xFF70A8FF);
  static const Color primary500 = Color(0xFF4F8CFF);
  static const Color primary600 = Color(0xFF2563EB); // Main primary color
  static const Color primary700 = Color(0xFF1E3A8A);
  static const Color primary800 = Color(0xFF1E3A8A);
  static const Color primary900 = Color(0xFF1E3A8A);

  // SECONDARY Colors (Light blue/cyan gradient from Figma)
  static const Color secondary50 = Color(0xFFF0FDFF);
  static const Color secondary100 = Color(0xFFCCFBF1);
  static const Color secondary200 = Color(0xFF99F6E4);
  static const Color secondary300 = Color(0xFF5EEAD4);
  static const Color secondary400 = Color(0xFF2DD4BF);
  static const Color secondary500 = Color(0xFF14B8A6);
  static const Color secondary600 = Color(0xFF0891B2);
  static const Color secondary700 = Color(0xFF0E7490);
  static const Color secondary800 = Color(0xFF155E75);
  static const Color secondary900 = Color(0xFF164E63);

  // TERTIARY Colors (Green gradient from Figma)
  static const Color tertiary50 = Color(0xFFF0FDF4);
  static const Color tertiary100 = Color(0xFFDCFCE7);
  static const Color tertiary200 = Color(0xFFBBF7D0);
  static const Color tertiary300 = Color(0xFF86EFAC);
  static const Color tertiary400 = Color(0xFF4ADE80);
  static const Color tertiary500 = Color(0xFF22C55E);
  static const Color tertiary600 = Color(0xFF16A34A);
  static const Color tertiary700 = Color(0xFF15803D);
  static const Color tertiary800 = Color(0xFF166534);
  static const Color tertiary900 = Color(0xFF14532D);

  // ERROR Colors (Red gradient from Figma)
  static const Color error50 = Color(0xFFFEF2F2);
  static const Color error100 = Color(0xFFFEE2E2);
  static const Color error200 = Color(0xFFFECACA);
  static const Color error300 = Color(0xFFFCA5A5);
  static const Color error400 = Color(0xFFF87171);
  static const Color error500 = Color(0xFFEF4444);
  static const Color error600 = Color(0xFFDC2626);
  static const Color error700 = Color(0xFFB91C1C);
  static const Color error800 = Color(0xFF991B1B);
  static const Color error900 = Color(0xFF7F1D1D);

  // GREY Colors (Grey scale from Figma)
  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFE5E5E5);
  static const Color grey300 = Color(0xFFD4D4D4);
  static const Color grey400 = Color(0xFFA3A3A3);
  static const Color grey500 = Color(0xFF737373);
  static const Color grey600 = Color(0xFF525252);
  static const Color grey700 = Color(0xFF404040);
  static const Color grey800 = Color(0xFF262626);
  static const Color grey900 = Color(0xFF171717);

  // BLACK & WHITE
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  // Common usage colors
  static const Color background = white;
  static const Color surface = white;
  static const Color onBackground = grey900;
  static const Color onSurface = grey900;
  static const Color onPrimary = white;
  static const Color onSecondary = white;
  static const Color onTertiary = white;
  static const Color onError = white;

  // Additional utility colors
  static const Color divider = grey200;
  static const Color disabled = grey400;
  static const Color placeholder = grey500;
} 