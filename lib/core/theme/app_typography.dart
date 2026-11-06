import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'offline_google_fonts.dart';

/// App Typography strictly based on the design specification:
/// - Playfair Display: Editorial and spiritual authority in headlines
///   - DISPLAY XL : Playfair 48px
///   - HEADING LG : Playfair 32px
/// - Manrope: Functional UI, body copy, labels, prices, and technical data
///   - BODY MD : Manrope 18px
///   - CAPTION SM : Manrope 14px
class AppTypography {
  AppTypography._();

  // Playfair Display Styles
  static TextStyle displayXL({
    Color color = AppColors.midnightNavy,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: 48,
      fontWeight: fontWeight,
      letterSpacing: -0.5,
      height: 1.15,
      color: color,
    );
  }

  static TextStyle headingLG({
    Color color = AppColors.midnightNavy,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: 32,
      fontWeight: fontWeight,
      letterSpacing: -0.2,
      height: 1.25,
      color: color,
    );
  }

  static TextStyle headingMD({
    Color color = AppColors.midnightNavy,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: 22,
      fontWeight: fontWeight,
      height: 1.3,
      color: color,
    );
  }

  // Manrope Styles
  static TextStyle bodyMD({
    Color color = AppColors.midnightNavy,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.manrope(
      fontSize: 18,
      fontWeight: fontWeight,
      height: 1.45,
      color: color,
    );
  }

  static TextStyle bodyRegular({
    Color color = const Color(0xFF334155),
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return GoogleFonts.manrope(
      fontSize: 15,
      fontWeight: fontWeight,
      height: 1.45,
      color: color,
    );
  }

  static TextStyle buttonLabel({
    Color color = AppColors.midnightNavy,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return GoogleFonts.manrope(
      fontSize: 15,
      fontWeight: fontWeight,
      letterSpacing: 0.2,
      color: color,
    );
  }

  static TextStyle captionSM({
    Color color = const Color(0xFF506078),
    FontWeight fontWeight = FontWeight.w400,
  }) {
    return GoogleFonts.manrope(
      fontSize: 13,
      fontWeight: fontWeight,
      height: 1.4,
      color: color,
    );
  }

  static TextStyle captionXS({
    Color color = const Color(0xFF6D7D93),
    FontWeight fontWeight = FontWeight.w500,
  }) {
    return GoogleFonts.manrope(
      fontSize: 11.5,
      fontWeight: fontWeight,
      height: 1.35,
      color: color,
    );
  }
}
