import 'package:flutter/material.dart';

/// App Color System strictly adhering to the design specifications:
/// - #0B132B : MIDNIGHT NAVY · PRIMARY
/// - #F7F5F0 : MOONLIT IVORY · BACKGROUND
/// - #E5A93C : SAFFRON GOLD · ACCENT
/// - #D9E4EA : HIMALAYAN MIST · SECONDARY
/// - Light Gradient · Atmosphere : #FCFDFF -> #CDDDED -> #6D9BC7
/// - Dark Gradient · Depth : #17264B -> #385F9E -> #FCFDFF
class AppColors {
  AppColors._();

  // Core Brand Colors
  static const Color midnightNavy = Color(0xFF0B132B);
  static const Color moonlitIvory = Color(0xFFF7F5F0);
  static const Color saffronGold = Color(0xFFE5A93C);
  static const Color himalayanMist = Color(0xFFD9E4EA);

  // Login / authentication action colors
  static const Color loginBlue = Color(0xFF3B82F6);
  static const Color loginBlueDark = Color(0xFF2563EB);
  static const Color loginBlueGlow = Color(0xFF60A5FA);

  // Gradient Steps
  static const Color lightGradStart = Color(0xFFFCFDFF);
  static const Color lightGradMid = Color(0xFFCDDDED);
  static const Color lightGradEnd = Color(0xFF6D9BC7);

  static const Color darkGradStart = Color(0xFF17264B);
  static const Color darkGradMid = Color(0xFF385F9E);
  static const Color darkGradEnd = Color(0xFFFCFDFF);

  // Solid & Utility Tones
  static const Color pureBlack = Color(0xFF000000);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color buttonDark = Color(0xFF070B14);
  static const Color buttonBorder = Color(0xFF1E2838);

  // Text Colors
  static const Color textPrimary = Color(0xFF0B132B);
  static const Color textLight = Color(0xFFFCFDFF);
  static const Color textMuted = Color(0xFFD9E4EA);

  // Reference UI Hero Gradient (Dark brown / charcoal into midnight pure black)
  static const LinearGradient referenceHeroGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.45, 0.8, 1.0],
    colors: [
      Color(0xFF3E1E08), // warm rich dark brown from screenshot top
      Color(0xFF231105),
      Color(0xFF100702),
      Color(0xFF000000),
    ],
  );

  /// Official Dark Gradient (Depth) from design sheet:
  /// #17264B -> #385F9E -> #FCFDFF
  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF17264B), Color(0xFF385F9E), Color(0xFFFCFDFF)],
  );

  /// Official Light Gradient (Atmosphere) from design sheet:
  /// #FCFDFF -> #CDDDED -> #6D9BC7
  static const LinearGradient lightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFCFDFF), Color(0xFFCDDDED), Color(0xFF6D9BC7)],
  );

  /// Official White Atmosphere Gradient:
  /// Pure white blending with image light atmosphere gradient:
  /// #FFFFFF -> #E2ECF7 -> #BED7ED -> #6D9BC7
  static const LinearGradient whiteAtmosphereGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.30, 0.65, 1.0],
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFE2ECF7),
      Color(0xFFBED7ED),
      Color(0xFF6D9BC7),
    ],
  );

  /// Midnight Navy Depth Gradient for Splash and Celestial Views
  static const LinearGradient midnightDepthGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF050914),
      Color(0xFF0B132B),
      Color(0xFF17264B),
      Color(0xFF0B132B),
    ],
  );

  /// Authentic Celestial Midnight Gradient from Login Screen
  /// #16254E -> #0D1836 -> #070E22 -> #030712
  static const LinearGradient celestialMidnightGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.0, 0.35, 0.7, 1.0],
    colors: [
      Color(0xFF16254E),
      Color(0xFF0D1836),
      Color(0xFF070E22),
      Color(0xFF030712),
    ],
  );
}
