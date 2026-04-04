import 'package:flutter/material.dart';

class AppColors {
  // Brand - light theme
  static const Color primary = Color(0xFFE86C88);
  static const Color primaryDark = Color(0xFFD45474);
  static const Color primaryLight = Color(0xFFFFEEF2);
  static const Color accent = Color(0xFFF7A8B8);

  // Neutral - light theme
  static const Color background = Color(0xFFF8F7FB);
  static const Color surface = Colors.white;
  static const Color card = Colors.white;
  static const Color foreground = Color(0xFF1F1F29);
  static const Color mutedForeground = Color(0xFF7B7B8B);
  static const Color border = Color(0xFFE9E7EF);

  // Status
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFB300);
  static const Color danger = Color(0xFFE53935);

  // Shared
  static const Color shadow = Color(0x14000000);
  static const Color primaryForeground = Colors.white;

  // Dark theme base
  static const Color darkBackground = Color(0xFF0E0E14);
  static const Color darkBackgroundSecondary = Color(0xFF14141D);
  static const Color darkSurface = Color(0xFF181824);
  static const Color darkSurfaceSoft = Color(0xFF202031);
  static const Color darkSurfaceElevated = Color(0xFF25253A);

  static const Color darkBorder = Color(0xFF313149);
  static const Color darkBorderSoft = Color(0xFF2A2A3D);

  static const Color darkForeground = Color(0xFFF4F2FF);
  static const Color darkMutedForeground = Color(0xFFAAA7C4);

  // Purple / neon accents for dark theme
  static const Color purple = Color(0xFF9B7BFF);
  static const Color purpleLight = Color(0xFFC8B8FF);
  static const Color purpleDark = Color(0xFF7B5CFF);
  static const Color neonPink = Color(0xFFFF7AC3);
  static const Color neonBlue = Color(0xFF6EA8FF);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFFE86C88), Color(0xFFF7A8B8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkBrandGradient = LinearGradient(
    colors: [Color(0xFF9B7BFF), Color(0xFFFF7AC3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF1B1B2A), Color(0xFF232338)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}