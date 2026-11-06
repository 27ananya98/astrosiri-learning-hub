import 'package:flutter/material.dart';

/// Offline replacement for the Google Fonts API surface used by the app.
/// Text rendering must not depend on a request to fonts.gstatic.com because
/// login and OTP screens must also work when DNS or internet is unavailable.
class GoogleFonts {
  GoogleFonts._();

  static TextStyle manrope({
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: 'sans-serif',
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }

  static TextStyle playfairDisplay({
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    Color? color,
  }) {
    return TextStyle(
      fontFamily: 'serif',
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
      color: color,
    );
  }
}
