import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Dark theme backgrounds - dark blue/black
  static const Color background = Color(0xFF0A0E27); // Very dark blue
  static const Color surface = Color(0xFF1A1F3A); // Dark blue surface
  static const Color surfaceVariant = Color(0xFF252B47); // Slightly lighter dark blue
  static const Color surfaceMuted = Color(0xFF1E2338); // Muted dark surface
  static const Color surfaceHighlight = Color(0xFF2D3455); // Highlighted dark surface
  static const Color border = Color(0xFF3A4166); // Dark blue border

  // Blue accent colors for interactive elements
  static const Color accent = Color(0xFF3B82F6); // Bright blue
  static const Color accentSecondary = Color(0xFF60A5FA); // Lighter blue
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFF43F5E);
  static const Color info = Color(0xFF6366F1);

  // Text colors - white and light colors for dark theme
  static const Color textPrimary = Color(0xFFFFFFFF); // White text
  static const Color textSecondary = Color(0xFFE2E8F0); // Light gray text
  static const Color textMuted = Color(0xFF94A3B8); // Muted light gray text
}
