import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- LUXURY MONOCHROME PALETTE ---
  static const Color _primaryBlack = Color(0xFF000000);
  static const Color _surfaceWhite = Color(0xFFFFFFFF);
  static const Color _accentSilver = Color(0xFFC0C0C0);
  static const Color _darkSurface = Color(0xFF121212);
  static const Color _textGrey = Color(0xFF757575);

  // --- GRADIENTS (Silver/Metal) ---
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF434343), Color(0xFF000000)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFFE0E0E0), Color(0xFFBDBDBD), Color(0xFFE0E0E0)], // Effet Argent
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // --- LIGHT THEME (Clean Luxury) ---
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: _primaryBlack,
    scaffoldBackgroundColor: _surfaceWhite,
    colorScheme: const ColorScheme.light(
      primary: _primaryBlack,
      secondary: _accentSilver,
      surface: _surfaceWhite,
      onPrimary: Colors.white,
      onSecondary: Colors.black,
      onSurface: Colors.black,
    ),
    
    // TYPOGRAPHY
    textTheme: GoogleFonts.cairoTextTheme().apply(
      bodyColor: Colors.black,
      displayColor: Colors.black,
    ),

    // APP BAR
    appBarTheme: const AppBarTheme(
      backgroundColor: _surfaceWhite,
      foregroundColor: Colors.black, // Icons & Text
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.black),
    ),

    // BUTTONS
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryBlack,
        foregroundColor: Colors.white,
        elevation: 5,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _primaryBlack,
        side: const BorderSide(color: _primaryBlack, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),

    // INPUTS
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _primaryBlack, width: 1.5)),
      prefixIconColor: Colors.grey[600],
      hintStyle: TextStyle(color: Colors.grey[500]),
    ),

    // CARDS
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    
    // ICONS
    iconTheme: const IconThemeData(color: _primaryBlack),
    
    // ANIMATIONS
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
      },
    ),
  );

  // --- DARK THEME (Midnight Luxury) ---
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: Colors.white, // Inversé pour le contraste
    scaffoldBackgroundColor: const Color(0xFF000000), // Pure Black
    colorScheme: const ColorScheme.dark(
      primary: Colors.white,
      secondary: _accentSilver,
      surface: _darkSurface,
      onPrimary: Colors.black, // Texte sur bouton blanc = noir
      onSecondary: Colors.black,
      onSurface: Colors.white,
    ),

    // TYPOGRAPHY
    textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme).apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),

    // APP BAR
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF000000),
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: Colors.white),
    ),

    // BUTTONS
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white, // Boutons blancs sur fond noir
        foregroundColor: Colors.black, // Texte noir
        elevation: 5,
        shadowColor: Colors.white.withOpacity(0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: GoogleFonts.cairo(fontWeight: FontWeight.bold),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    ),

    // INPUTS
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E1E1E),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white, width: 1.5)),
      prefixIconColor: Colors.grey[400],
      hintStyle: TextStyle(color: Colors.grey[600]),
    ),

    // CARDS
    cardTheme: CardThemeData(
      color: _darkSurface,
      elevation: 2,
      shadowColor: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    // ICONS
    iconTheme: const IconThemeData(color: Colors.white),

    // ANIMATIONS
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: ZoomPageTransitionsBuilder(),
      },
    ),
  );
}
