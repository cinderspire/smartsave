import 'package:flutter/material.dart';

/// SmartSave Financial App Color Palette
class AppColors {
  AppColors._();

  // Primary - Trust & Growth
  static const Color primaryGreen = Color(0xFF10B981); // Emerald
  static const Color primaryBlue = Color(0xFF3B82F6); // Blue
  static const Color accentGold = Color(0xFFFFB020); // Gold

  // Gradients
  static const LinearGradient wealthGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFB020), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Status Colors
  static const Color profit = Color(0xFF10B981);
  static const Color loss = Color(0xFFEF4444);
  static const Color neutral = Color(0xFF6B7280);

  // Background - Dark Mode
  static const Color backgroundDark = Color(0xFF0F172A);
  static const Color backgroundDarkCard = Color(0xFF1E293B);
  static const Color backgroundDarkElevated = Color(0xFF334155);

  // Text - Dark Mode
  static const Color textPrimaryDark = Color(0xFFF1F5F9);
  static const Color textSecondaryDark = Color(0xFFCBD5E1);
  static const Color textTertiaryDark = Color(0xFF94A3B8);

  // Glassmorphism
  static final Color glassDark = const Color(0xFF1E293B).withAlpha(179);
  static final Color glassBorder = const Color(0xFFFFFFFF).withAlpha(26);
}
