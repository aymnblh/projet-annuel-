import 'package:flutter/material.dart';

/// App-wide spacing and border radius constants
class AppSpacing {
  // Spacing scale
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  // Common paddings
  static const double cardPadding = 16.0;
  static const double screenPadding = 20.0;
  static const double sectionPadding = 24.0;
}

/// Border radius constants
class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 30.0;
  static const double round = 999.0;
}

/// Shadow configurations
class AppShadows {
  // Multi-layer shadows for depth
  static List<BoxShadow> card = [
    BoxShadow(
      color: Color(0xFF000000).withOpacity(0.08),
      blurRadius: 20,
      offset: Offset(0, 8),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Color(0xFF000000).withOpacity(0.04),
      blurRadius: 40,
      offset: Offset(0, 16),
      spreadRadius: -8,
    ),
  ];
  
  static List<BoxShadow> cardHover = [
    BoxShadow(
      color: Color(0xFF000000).withOpacity(0.12),
      blurRadius: 30,
      offset: Offset(0, 12),
      spreadRadius: -4,
    ),
    BoxShadow(
      color: Color(0xFF000000).withOpacity(0.06),
      blurRadius: 50,
      offset: Offset(0, 20),
      spreadRadius: -8,
    ),
  ];
  
  static List<BoxShadow> button = [
    BoxShadow(
      color: Color(0xFF6366F1).withOpacity(0.3),
      blurRadius: 20,
      offset: Offset(0, 10),
    ),
  ];
  
  static List<BoxShadow> bottomSheet = [
    BoxShadow(
      color: Color(0xFF000000).withOpacity(0.2),
      blurRadius: 40,
      offset: Offset(0, -10),
    ),
  ];
  
  // Elevated elements (FABs, floating buttons)
  static List<BoxShadow> elevated = [
    BoxShadow(
      color: Color(0xFF000000).withOpacity(0.15),
      blurRadius: 25,
      offset: Offset(0, 8),
      spreadRadius: -5,
    ),
    BoxShadow(
      color: Color(0xFF000000).withOpacity(0.08),
      blurRadius: 45,
      offset: Offset(0, 15),
      spreadRadius: -10,
    ),
  ];
  
  // Subtle depth (dividers, subtle borders)
  static List<BoxShadow> subtle = [
    BoxShadow(
      color: Color(0xFF000000).withOpacity(0.04),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
  
  // Glow effect for accent elements
  static List<BoxShadow> glow = [
    BoxShadow(
      color: Color(0xFF6366F1).withOpacity(0.4),
      blurRadius: 20,
      offset: Offset(0, 8),
      spreadRadius: 0,
    ),
  ];
  
  // Gold glow for boost badges
  static List<BoxShadow> goldGlow = [
    BoxShadow(
      color: Color(0xFFFBBF24).withOpacity(0.5),
      blurRadius: 15,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];
}

/// Animation timing and curves
class AppAnimations {
  // Durations
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);
  
  // Curves
  static const Curve defaultCurve = Curves.easeInOutCubic;
  static const Curve bounceIn = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeOutCubic;
  static const Curve sharpCurve = Curves.easeInCubic;
}
