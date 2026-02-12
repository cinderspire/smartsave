import 'package:flutter/material.dart';

/// SmartSave Financial App Color Palette - Neon Fintech with Corporate Blend
class AppColors {
  AppColors._();

  // Primary - Dark Navy Base
  static const Color primary = Color(0xFF0A1628);
  static const Color primaryLight = Color(0xFF162240);
  static const Color primaryDark = Color(0xFF060E1A);

  // Accent - Neon Green
  static const Color accentGreen = Color(0xFF39FF14);
  static const Color accentGreenDim = Color(0xFF2BCC10);

  // Accent - Electric Blue
  static const Color accentBlue = Color(0xFF00E5FF);
  static const Color accentBlueDim = Color(0xFF00B8CC);

  // Secondary - Corporate Blue (subtle blend)
  static const Color secondary = Color(0xFF3B82F6);
  static const Color secondaryLight = Color(0xFF60A5FA);

  // Gradients
  static const LinearGradient wealthGradient = LinearGradient(
    colors: [Color(0xFF39FF14), Color(0xFF00E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient neonGradient = LinearGradient(
    colors: [Color(0xFF39FF14), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient corporateGradient = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF00E5FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Status Colors
  static const Color profit = Color(0xFF39FF14);
  static const Color loss = Color(0xFFEF4444);
  static const Color neutral = Color(0xFF6B7280);

  // Background - Dark Mode (Primary)
  static const Color backgroundDark = Color(0xFF0A1628);
  static const Color backgroundDarkCard = Color(0xFF122036);
  static const Color backgroundDarkElevated = Color(0xFF1A2D4A);

  // Text - Dark Mode
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textTertiaryDark = Color(0xFF94A3B8);

  // Glassmorphism
  static final Color glassDark = const Color(0xFF122036).withAlpha(179);
  static final Color glassBorder = const Color(0xFF39FF14).withAlpha(26);
  static final Color glassNeon = const Color(0xFF39FF14).withAlpha(13);

  // ── Legacy aliases (backward compatibility) ──
  static const Color primaryGreen = accentGreen;
  static const Color primaryBlue = accentBlue;
  static const Color accentGold = Color(0xFFFFD700);

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
