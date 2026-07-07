import 'package:flutter/material.dart';

/// App-wide color palette with modern indigo/purple theme
class AppColors {
  // Primary (Indigo/Purple gradient)
  static const primary = Color(0xFF6366F1);
  static const primaryDark = Color(0xFF4F46E5);
  static const primaryLight = Color(0xFF818CF8);
  
  // Secondary (Purple)
  static const secondary = Color(0xFF8B5CF6);
  static const secondaryDark = Color(0xFF7C3AED);
  static const secondaryLight = Color(0xFFA78BFA);
  
  // Accent (Amber for Boost/Premium features)
  static const accent = Color(0xFFFBBF24);
  static const accentDark = Color(0xFFF59E0B);
  static const accentLight = Color(0xFFFCD34D);
  
  // Success/Error/Warning
  static const success = Color(0xFF10B981);
  static const error = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);
  
  // Neutrals
  static const background = Color(0xFFFAFAFA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF1E1E1E);
  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const divider = Color(0xFFE5E7EB);
  
  // Gradients
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const goldGradient = LinearGradient(
    colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const successGradient = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Shadow colors
  static Color shadowLight = Colors.black.withOpacity(0.08);
  static Color shadowMedium = Colors.black.withOpacity(0.12);
  static Color shadowDark = Colors.black.withOpacity(0.16);
  
  // Glassmorphism
  static Color glassWhite = Colors.white.withOpacity(0.2);
  static Color glassBorder = Colors.white.withOpacity(0.3);
}
