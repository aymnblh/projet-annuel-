import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// App-wide typography system using Cairo font
class AppTypography {
  // Headings
  static TextStyle h1 = GoogleFonts.cairo(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.2,
    color: AppColors.textPrimary,
  );
  
  static TextStyle h2 = GoogleFonts.cairo(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.3,
    color: AppColors.textPrimary,
  );
  
  static TextStyle h3 = GoogleFonts.cairo(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );
  
  static TextStyle h4 = GoogleFonts.cairo(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.textPrimary,
  );
  
  // Body text
  static TextStyle body = GoogleFonts.cairo(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: AppColors.textPrimary,
  );
  
  static TextStyle bodyMedium = GoogleFonts.cairo(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    color: AppColors.textPrimary,
  );
  
  static TextStyle bodySmall = GoogleFonts.cairo(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
    color: AppColors.textSecondary,
  );
  
  // Caption & labels
  static TextStyle caption = GoogleFonts.cairo(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  static TextStyle captionSmall = GoogleFonts.cairo(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textTertiary,
  );
  
  static TextStyle label = GoogleFonts.cairo(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  // Special styles
  static TextStyle price = GoogleFonts.cairo(
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: AppColors.primary,
  );
  
  static TextStyle priceLarge = GoogleFonts.cairo(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: AppColors.primary,
  );
  
  static TextStyle button = GoogleFonts.cairo(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
  );
  
  static TextStyle buttonSmall = GoogleFonts.cairo(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
  );
  
  // Badge & chip
  static TextStyle badge = GoogleFonts.cairo(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  static TextStyle chip = GoogleFonts.cairo(
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );
}
