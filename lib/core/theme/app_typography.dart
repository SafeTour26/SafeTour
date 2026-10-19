import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography hierarchy from Prompts/design.md
class AppTypography {
  // Headlines & Displays (Plus Jakarta Sans)
  static TextStyle displayLg = GoogleFonts.plusJakartaSans(
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.22,
    letterSpacing: -0.02 * 36,
    color: AppColors.onSurface,
  );

  static TextStyle headlineLg = GoogleFonts.plusJakartaSans(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.25,
    letterSpacing: -0.01 * 32,
    color: AppColors.onSurface,
  );

  static TextStyle headlineMd = GoogleFonts.plusJakartaSans(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
    color: AppColors.onSurface,
  );

  static TextStyle headlineSm = GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.onSurface,
  );

  static TextStyle titleLg = GoogleFonts.plusJakartaSans(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.33,
    color: AppColors.onSurface,
  );

  static TextStyle titleMd = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.33,
    color: AppColors.onSurface,
  );

  // Body & Labels (Inter)
  static TextStyle bodyLg = GoogleFonts.inter(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    height: 1.55,
    color: AppColors.onSurface,
  );

  static TextStyle bodyMd = GoogleFonts.inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.onSurface,
  );

  static TextStyle bodySm = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.42,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle labelLg = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.42,
    color: AppColors.onSurface,
  );

  static TextStyle labelMd = GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.33,
    letterSpacing: 0.05 * 12,
    color: AppColors.onSurfaceVariant,
  );

  static TextStyle labelSm = GoogleFonts.inter(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.05 * 10,
    color: AppColors.onSurfaceVariant,
  );
}
