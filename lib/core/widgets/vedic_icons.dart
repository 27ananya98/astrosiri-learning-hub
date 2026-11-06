import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_assets.dart';

/// Flaticon-style Vedic Subject Icon with pastel circular container
class VedicSubjectIcon extends StatelessWidget {
  final String subjectName;
  final double size;

  const VedicSubjectIcon({
    super.key,
    required this.subjectName,
    this.size = 52,
  });

  @override
  Widget build(BuildContext context) {
    final lower = subjectName.toLowerCase().trim();

    Color bgColor;
    Widget iconWidget;

    if (lower.contains('astro')) {
      bgColor = const Color(0xFFFEF9C3); // Soft pastel yellow
      iconWidget = Image.asset(AppAssets.astrologySun, fit: BoxFit.contain);
    } else if (lower.contains('vastu')) {
      bgColor = const Color(0xFFFFEDD5); // Soft pastel orange
      iconWidget = Image.asset(AppAssets.vastuIcon, fit: BoxFit.contain);
    } else if (lower.contains('numer')) {
      bgColor = const Color(0xFFFEF9C3); // Soft pastel yellow
      iconWidget = const _NumerologyBlocksPainterWidget();
    } else if (lower.contains('tarot')) {
      bgColor = const Color(0xFF3A1608);
      iconWidget = Image.asset(AppAssets.tarotCards, fit: BoxFit.contain);
    } else if (lower.contains('palm')) {
      bgColor = const Color(0xFFFFF2D6);
      iconWidget = Image.asset(AppAssets.palmistryHand, fit: BoxFit.contain);
    } else {
      // Testing or Default: Sacred Lotus
      bgColor = const Color(0xFFFEF9C3); // Soft pastel yellow
      iconWidget = const _SacredLotusPainterWidget();
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.8),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.all(size * 0.18),
      child: iconWidget,
    );
  }
}

// ----------------------------------------------------
// 3. NUMEROLOGY: '1 2 3' Blocks / Sacred Yantra
// ----------------------------------------------------
class _NumerologyBlocksPainterWidget extends StatelessWidget {
  const _NumerologyBlocksPainterWidget();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/icons/numerology_yantra.png',
      fit: BoxFit.contain,
    );
  }
}

// ----------------------------------------------------
// 4. TAROT: Mystical Playing Cards Fanned Out
// ----------------------------------------------------
// ignore: unused_element
class _TarotCardsPainterWidget extends StatelessWidget {
  const _TarotCardsPainterWidget();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _TarotCardsPainter());
  }
}

class _TarotCardsPainter extends CustomPainter {
  const _TarotCardsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    void drawCard(Canvas c, double rotation, Offset offset, Color bgColor) {
      c.save();
      c.translate(offset.dx, offset.dy);
      c.rotate(rotation);

      final cardRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w * 0.44, height: h * 0.74),
        const Radius.circular(5),
      );
      c.drawRRect(cardRect, Paint()..color = bgColor);

      // Card border
      c.drawRRect(
        cardRect,
        Paint()
          ..color = const Color(0xFFFED7AA)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );

      // Sun / Star inside card
      c.drawCircle(
        Offset.zero,
        w * 0.08,
        Paint()..color = const Color(0xFFFFFBEB),
      );
      c.restore();
    }

    // Card 1 (tilted left)
    drawCard(
      canvas,
      -0.22,
      Offset(w * 0.40, h * 0.52),
      const Color(0xFFEA580C),
    );
    // Card 2 (tilted right)
    drawCard(canvas, 0.20, Offset(w * 0.62, h * 0.50), const Color(0xFFF97316));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------
// 5. PALMISTRY: Open Hand with Destiny Lines
// ----------------------------------------------------
// ignore: unused_element
class _PalmistryHandPainterWidget extends StatelessWidget {
  const _PalmistryHandPainterWidget();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: const _PalmistryHandPainter());
  }
}

class _PalmistryHandPainter extends CustomPainter {
  const _PalmistryHandPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final fillPaint = Paint()..color = const Color(0xFFEA580C);
    final linePaint = Paint()
      ..color = const Color(0xFFFFF7ED)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Palm base
    final palmRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.22, h * 0.38, w * 0.56, h * 0.52),
      const Radius.circular(10),
    );
    canvas.drawRRect(palmRect, fillPaint);

    // 4 Fingers
    void drawFinger(double x, double topH, double fWidth) {
      final fRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, topH, fWidth, h * 0.42),
        const Radius.circular(5),
      );
      canvas.drawRRect(fRect, fillPaint);
    }

    drawFinger(w * 0.23, h * 0.12, w * 0.11); // Index
    drawFinger(w * 0.37, h * 0.06, w * 0.11); // Middle
    drawFinger(w * 0.51, h * 0.09, w * 0.11); // Ring
    drawFinger(w * 0.65, h * 0.18, w * 0.10); // Pinky

    // Thumb
    final thumbPath = Path()
      ..moveTo(w * 0.24, h * 0.58)
      ..lineTo(w * 0.08, h * 0.45)
      ..arcToPoint(Offset(w * 0.14, h * 0.36), radius: const Radius.circular(5))
      ..lineTo(w * 0.24, h * 0.44)
      ..close();
    canvas.drawPath(thumbPath, fillPaint);

    // Destiny Palm Lines (Heart line & Life line)
    final heartLine = Path()
      ..moveTo(w * 0.30, h * 0.52)
      ..quadraticBezierTo(w * 0.48, h * 0.58, w * 0.68, h * 0.50);
    canvas.drawPath(heartLine, linePaint);

    final lifeLine = Path()
      ..moveTo(w * 0.32, h * 0.54)
      ..quadraticBezierTo(w * 0.42, h * 0.68, w * 0.44, h * 0.82);
    canvas.drawPath(lifeLine, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------
// 6. SACRED LOTUS FLOWER: (For Testing / Vedic Science)
// ----------------------------------------------------
class _SacredLotusPainterWidget extends StatelessWidget {
  const _SacredLotusPainterWidget();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/icons/golden_lotus.png',
      fit: BoxFit.contain,
    );
  }
}

// ----------------------------------------------------
// 7. GOLDEN MANDALA LINE ART (Drawer Bottom & Artwork)
// ----------------------------------------------------
class VedicMandalaLineArt extends StatelessWidget {
  final double width;
  final double height;

  const VedicMandalaLineArt({
    super.key,
    this.width = double.infinity,
    this.height = 110,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(
        AppAssets.bigLotus,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const CustomPaint(painter: _MandalaLineArtPainter()),
      ),
    );
  }
}

class _MandalaLineArtPainter extends CustomPainter {
  const _MandalaLineArtPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h * 0.92);

    final goldStroke = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    final subtleGold = Paint()
      ..color = const Color(0xFFFCD34D).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Symmetrical blooming lotus petals radiating upward
    void drawPetalPair(
      double apexX,
      double apexY,
      double controlX,
      double controlY,
    ) {
      final pathRight = Path()
        ..moveTo(center.dx, center.dy)
        ..quadraticBezierTo(
          center.dx + controlX,
          center.dy + controlY,
          center.dx + apexX,
          center.dy + apexY,
        )
        ..quadraticBezierTo(
          center.dx + controlX * 0.45,
          center.dy + controlY * 0.45,
          center.dx,
          center.dy,
        );
      canvas.drawPath(pathRight, goldStroke);

      final pathLeft = Path()
        ..moveTo(center.dx, center.dy)
        ..quadraticBezierTo(
          center.dx - controlX,
          center.dy + controlY,
          center.dx - apexX,
          center.dy + apexY,
        )
        ..quadraticBezierTo(
          center.dx - controlX * 0.45,
          center.dy + controlY * 0.45,
          center.dx,
          center.dy,
        );
      canvas.drawPath(pathLeft, goldStroke);
    }

    // Tall central petal
    final centerPath = Path()
      ..moveTo(center.dx, center.dy)
      ..quadraticBezierTo(
        center.dx + w * 0.08,
        center.dy - h * 0.45,
        center.dx,
        center.dy - h * 0.85,
      )
      ..quadraticBezierTo(
        center.dx - w * 0.08,
        center.dy - h * 0.45,
        center.dx,
        center.dy,
      );
    canvas.drawPath(centerPath, goldStroke);

    // Inner central bud
    canvas.drawCircle(
      Offset(center.dx, center.dy - h * 0.45),
      3,
      Paint()..color = const Color(0xFFF59E0B),
    );

    // Mid petals
    drawPetalPair(w * 0.18, -h * 0.65, w * 0.22, -h * 0.25);
    // Outer wide petals
    drawPetalPair(w * 0.34, -h * 0.40, w * 0.38, -h * 0.12);
    // Bottom grounding flares
    drawPetalPair(w * 0.42, -h * 0.15, w * 0.44, 0);

    // Arcs / Concentric base circles
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: h * 0.32),
      math.pi,
      math.pi,
      false,
      subtleGold,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: h * 0.50),
      math.pi,
      math.pi,
      false,
      subtleGold,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------
// 8. SOCIAL MEDIA ICONS (Drawer: FB, IG, LinkedIn, X, YT)
// ----------------------------------------------------
class SocialMediaIcon extends StatelessWidget {
  final String platform;
  final double size;

  const SocialMediaIcon({super.key, required this.platform, this.size = 32});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Widget content;

    switch (platform.toLowerCase()) {
      case 'facebook':
      case 'fb':
        bgColor = const Color(0xFF1877F2);
        content = const Text(
          'f',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
            fontFamily: 'sans-serif',
          ),
        );
        break;
      case 'instagram':
      case 'ig':
        bgColor = Colors.transparent;
        content = Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCB045)],
              begin: Alignment.bottomLeft,
              end: Alignment.topRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(
              Icons.camera_alt_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
        );
        break;
      case 'linkedin':
      case 'in':
        bgColor = const Color(0xFF0A66C2);
        content = const Text(
          'in',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
            fontFamily: 'sans-serif',
          ),
        );
        break;
      case 'x':
      case 'twitter':
        bgColor = const Color(0xFF000000);
        content = const Text(
          '𝕏',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 16,
          ),
        );
        break;
      case 'youtube':
      case 'yt':
        bgColor = const Color(0xFFFF0000);
        content = const Icon(
          Icons.play_arrow_rounded,
          color: Colors.white,
          size: 20,
        );
        break;
      default:
        bgColor = const Color(0xFF64748B);
        content = const Icon(Icons.share, color: Colors.white, size: 16);
    }

    if (platform.toLowerCase() == 'instagram' ||
        platform.toLowerCase() == 'ig') {
      return SizedBox(width: size, height: size, child: content);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(child: content),
    );
  }
}

// ----------------------------------------------------
// 9. VEDIC COURSE BOOK BANNER (Bottom of Course Overview)
// ----------------------------------------------------
class VedicCourseBookBanner extends StatelessWidget {
  final double height;

  const VedicCourseBookBanner({super.key, this.height = 130});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFEF3C7), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background soft dunes sloping from right
          Positioned(
            right: -30,
            bottom: -20,
            width: 180,
            height: 100,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFEFF6FF).withValues(alpha: 0.8),
                    const Color(0xFFFEF3C7).withValues(alpha: 0.5),
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(80),
                ),
              ),
            ),
          ),

          // Astrological Chart Wheel + Open Holy Scripture Book Banner Painter
          CustomPaint(
            size: Size(double.infinity, height),
            painter: const _ZodiacBookBannerPainter(),
          ),

          // 3D Realistic Golden Scripture Book on Right
          Positioned(
            right: 14,
            top: 8,
            bottom: 8,
            child: Image.asset(
              'assets/images/icons/golden_book.png',
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}

class _ZodiacBookBannerPainter extends CustomPainter {
  const _ZodiacBookBannerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Astrological Horoscope Wheel / Kundli Chakra (Left Side)
    final wheelCenter = Offset(w * 0.28, h * 0.52);
    final wheelR = h * 0.42;

    final goldStroke = Paint()
      ..color = const Color(0xFFF59E0B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    final subtleGold = Paint()
      ..color = const Color(0xFFFCD34D).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Outer & inner concentric rings
    canvas.drawCircle(wheelCenter, wheelR, goldStroke);
    canvas.drawCircle(wheelCenter, wheelR * 0.84, subtleGold);
    canvas.drawCircle(wheelCenter, wheelR * 0.62, goldStroke);
    canvas.drawCircle(wheelCenter, wheelR * 0.32, subtleGold);

    // 12 Zodiac House division rays
    for (int i = 0; i < 12; i++) {
      final angle = (i * 2 * math.pi) / 12;
      final p1 = Offset(
        wheelCenter.dx + wheelR * 0.32 * math.cos(angle),
        wheelCenter.dy + wheelR * 0.32 * math.sin(angle),
      );
      final p2 = Offset(
        wheelCenter.dx + wheelR * math.cos(angle),
        wheelCenter.dy + wheelR * math.sin(angle),
      );
      canvas.drawLine(p1, p2, subtleGold);
    }

    // Small star dots in zodiac sectors
    for (int i = 0; i < 12; i++) {
      final angle = ((i + 0.5) * 2 * math.pi) / 12;
      final dot = Offset(
        wheelCenter.dx + wheelR * 0.73 * math.cos(angle),
        wheelCenter.dy + wheelR * 0.73 * math.sin(angle),
      );
      canvas.drawCircle(dot, 1.4, Paint()..color = const Color(0xFFF59E0B));
    }

    // Radiating sparkle rays around the wheel
    for (int i = 0; i < 8; i++) {
      final angle = (i * 2 * math.pi) / 8 + 0.2;
      final sp = Offset(
        wheelCenter.dx + (wheelR + 10) * math.cos(angle),
        wheelCenter.dy + (wheelR + 10) * math.sin(angle),
      );
      canvas.drawCircle(sp, 1.5, Paint()..color = const Color(0xFFF59E0B));
    }

    // 2. Open Vedic Scripture Book (Granth) (Center/Right Foreground)
    final bookCenter = Offset(w * 0.54, h * 0.72);
    final bookW = h * 0.68;
    final bookH = h * 0.36;

    // Hardcover base / binding
    final coverPaint = Paint()
      ..color = const Color(0xFF78350F)
      ..style = PaintingStyle.fill;
    final coverPath = Path()
      ..moveTo(bookCenter.dx - bookW * 0.52, bookCenter.dy + bookH * 0.44)
      ..quadraticBezierTo(
        bookCenter.dx,
        bookCenter.dy + bookH * 0.62,
        bookCenter.dx + bookW * 0.52,
        bookCenter.dy + bookH * 0.44,
      )
      ..lineTo(bookCenter.dx + bookW * 0.50, bookCenter.dy - bookH * 0.14)
      ..quadraticBezierTo(
        bookCenter.dx,
        bookCenter.dy + bookH * 0.05,
        bookCenter.dx - bookW * 0.50,
        bookCenter.dy - bookH * 0.14,
      )
      ..close();
    canvas.drawPath(coverPath, coverPaint);

    // Book page stack thickness (fanning effect)
    final stackPaint = Paint()..color = const Color(0xFFFEF3C7);
    final stackPath = Path()
      ..moveTo(bookCenter.dx - bookW * 0.50, bookCenter.dy + bookH * 0.40)
      ..quadraticBezierTo(
        bookCenter.dx,
        bookCenter.dy + bookH * 0.56,
        bookCenter.dx + bookW * 0.50,
        bookCenter.dy + bookH * 0.40,
      )
      ..lineTo(bookCenter.dx + bookW * 0.49, bookCenter.dy + bookH * 0.24)
      ..quadraticBezierTo(
        bookCenter.dx,
        bookCenter.dy + bookH * 0.42,
        bookCenter.dx - bookW * 0.49,
        bookCenter.dy + bookH * 0.24,
      )
      ..close();
    canvas.drawPath(stackPath, stackPaint);

    // Crisp white/cream open pages
    final pagePaint = Paint()..color = Colors.white;
    final pageBorderPaint = Paint()
      ..color = const Color(0xFFFDE68A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Left open page
    final leftPage = Path()
      ..moveTo(bookCenter.dx, bookCenter.dy + bookH * 0.14)
      ..quadraticBezierTo(
        bookCenter.dx - bookW * 0.25,
        bookCenter.dy + bookH * 0.02,
        bookCenter.dx - bookW * 0.48,
        bookCenter.dy - bookH * 0.10,
      )
      ..lineTo(bookCenter.dx - bookW * 0.48, bookCenter.dy + bookH * 0.32)
      ..quadraticBezierTo(
        bookCenter.dx - bookW * 0.25,
        bookCenter.dy + bookH * 0.46,
        bookCenter.dx,
        bookCenter.dy + bookH * 0.56,
      )
      ..close();
    canvas.drawPath(leftPage, pagePaint);
    canvas.drawPath(leftPage, pageBorderPaint);

    // Right open page
    final rightPage = Path()
      ..moveTo(bookCenter.dx, bookCenter.dy + bookH * 0.14)
      ..quadraticBezierTo(
        bookCenter.dx + bookW * 0.25,
        bookCenter.dy + bookH * 0.02,
        bookCenter.dx + bookW * 0.48,
        bookCenter.dy - bookH * 0.10,
      )
      ..lineTo(bookCenter.dx + bookW * 0.48, bookCenter.dy + bookH * 0.32)
      ..quadraticBezierTo(
        bookCenter.dx + bookW * 0.25,
        bookCenter.dy + bookH * 0.46,
        bookCenter.dx,
        bookCenter.dy + bookH * 0.56,
      )
      ..close();
    canvas.drawPath(rightPage, pagePaint);
    canvas.drawPath(rightPage, pageBorderPaint);

    // Sacred Sloka horizontal text lines on pages
    final textLinePaint = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.5)
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 3; i++) {
      final yOff = bookH * 0.06 + i * (bookH * 0.09);
      // Left lines
      canvas.drawLine(
        Offset(bookCenter.dx - bookW * 0.40, bookCenter.dy + yOff),
        Offset(
          bookCenter.dx - bookW * 0.10,
          bookCenter.dy + yOff + bookH * 0.04,
        ),
        textLinePaint,
      );
      // Right lines
      canvas.drawLine(
        Offset(
          bookCenter.dx + bookW * 0.10,
          bookCenter.dy + yOff + bookH * 0.04,
        ),
        Offset(bookCenter.dx + bookW * 0.40, bookCenter.dy + yOff),
        textLinePaint,
      );
    }

    // Red bookmark ribbon hanging from spine
    final ribbonPaint = Paint()
      ..color = const Color(0xFFDC2626)
      ..style = PaintingStyle.fill;
    final ribbonPath = Path()
      ..moveTo(bookCenter.dx - 3, bookCenter.dy + bookH * 0.54)
      ..lineTo(bookCenter.dx + 3, bookCenter.dy + bookH * 0.54)
      ..lineTo(bookCenter.dx + 4, bookCenter.dy + bookH * 0.72)
      ..lineTo(bookCenter.dx, bookCenter.dy + bookH * 0.67)
      ..lineTo(bookCenter.dx - 4, bookCenter.dy + bookH * 0.72)
      ..close();
    canvas.drawPath(ribbonPath, ribbonPaint);

    // 3. Floating Sacred Light & 4-Pointed Diamond Sparkles Rising Up
    void drawDiamondSparkle(double x, double y, double r) {
      final p = Path()
        ..moveTo(x, y - r)
        ..quadraticBezierTo(x, y, x + r, y)
        ..quadraticBezierTo(x, y, x, y + r)
        ..quadraticBezierTo(x, y, x - r, y)
        ..quadraticBezierTo(x, y, x, y - r)
        ..close();
      canvas.drawPath(p, Paint()..color = const Color(0xFFF59E0B));
    }

    drawDiamondSparkle(w * 0.52, h * 0.38, 5.0);
    drawDiamondSparkle(w * 0.65, h * 0.32, 6.5);
    drawDiamondSparkle(w * 0.76, h * 0.42, 4.5);
    drawDiamondSparkle(w * 0.45, h * 0.28, 4.0);
    drawDiamondSparkle(w * 0.38, h * 0.18, 5.5);

    // Stardust golden micro dots
    final dotPaint = Paint()..color = const Color(0xFFFCD34D);
    canvas.drawCircle(Offset(w * 0.58, h * 0.22), 2.0, dotPaint);
    canvas.drawCircle(Offset(w * 0.70, h * 0.20), 1.8, dotPaint);
    canvas.drawCircle(Offset(w * 0.48, h * 0.46), 2.2, dotPaint);
    canvas.drawCircle(Offset(w * 0.80, h * 0.30), 2.0, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ----------------------------------------------------
// 10. REALISTIC VEDIC BOOK ICON (Upcoming Activities)
// ----------------------------------------------------
class RealisticVedicBookIcon extends StatelessWidget {
  final double size;

  const RealisticVedicBookIcon({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/icons/golden_book.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }
}

// ----------------------------------------------------
// 11. REALISTIC CHIP ICON (Areas of Interest on Dashboard)
// ----------------------------------------------------
class RealisticChipIcon extends StatelessWidget {
  final String area;
  final double size;

  const RealisticChipIcon({super.key, required this.area, this.size = 18});

  @override
  Widget build(BuildContext context) {
    final lower = area.toLowerCase().trim();

    if (lower.contains('astro')) {
      return Image.asset(
        AppAssets.astrologySun,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    } else if (lower.contains('vastu')) {
      return Image.asset(
        AppAssets.vastuIcon,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    } else if (lower.contains('numer')) {
      return Image.asset(
        'assets/images/icons/numerology_yantra.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    } else if (lower.contains('tarot')) {
      return Image.asset(
        AppAssets.tarotCards,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    } else if (lower.contains('palm')) {
      return Image.asset(
        AppAssets.palmistryHand,
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    } else if (lower.contains('test') ||
        lower.contains('vedic') ||
        (!lower.contains('astro') &&
            !lower.contains('vastu') &&
            !lower.contains('tarot') &&
            !lower.contains('palm'))) {
      return Image.asset(
        'assets/images/icons/golden_lotus.png',
        width: size,
        height: size,
        fit: BoxFit.contain,
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _RealisticChipIconPainter(lower)),
    );
  }
}

class _RealisticChipIconPainter extends CustomPainter {
  final String slug;

  const _RealisticChipIconPainter(this.slug);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);

    if (slug.contains('astro')) {
      // Radiant Golden Sun
      final sunPaint = Paint()..color = const Color(0xFFD97706);
      canvas.drawCircle(center, w * 0.26, sunPaint);

      final rayPaint = Paint()
        ..color = const Color(0xFFD97706)
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;

      for (int i = 0; i < 8; i++) {
        final angle = (i * 2 * math.pi) / 8;
        final p1 = Offset(
          center.dx + w * 0.36 * math.cos(angle),
          center.dy + h * 0.36 * math.sin(angle),
        );
        final p2 = Offset(
          center.dx + w * 0.48 * math.cos(angle),
          center.dy + h * 0.48 * math.sin(angle),
        );
        canvas.drawLine(p1, p2, rayPaint);
      }
    } else if (slug.contains('vastu')) {
      // Sacred Peaked House / Temple
      final fillPaint = Paint()..color = const Color(0xFFD97706);
      final roof = Path()
        ..moveTo(w * 0.50, h * 0.12)
        ..lineTo(w * 0.90, h * 0.46)
        ..lineTo(w * 0.10, h * 0.46)
        ..close();
      canvas.drawPath(roof, fillPaint);

      final wallRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.22, h * 0.46, w * 0.56, h * 0.44),
        const Radius.circular(2),
      );
      canvas.drawRRect(wallRect, fillPaint);

      // Door cutout
      final doorPaint = Paint()..color = Colors.white;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.38, h * 0.58, w * 0.24, h * 0.32),
          const Radius.circular(2),
        ),
        doorPaint,
      );
    } else if (slug.contains('numer')) {
      // 123 Tiles
      final tilePaint = Paint()..color = const Color(0xFFD97706);
      final tile1 = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.22, w * 0.26, h * 0.56),
        const Radius.circular(3),
      );
      final tile2 = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.37, h * 0.16, w * 0.26, h * 0.68),
        const Radius.circular(3),
      );
      final tile3 = RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.66, h * 0.22, w * 0.26, h * 0.56),
        const Radius.circular(3),
      );
      canvas.drawRRect(tile1, tilePaint);
      canvas.drawRRect(tile2, tilePaint);
      canvas.drawRRect(tile3, tilePaint);
    } else if (slug.contains('tarot')) {
      // Two fanned cards
      final cardPaint = Paint()..color = const Color(0xFFD97706);
      canvas.save();
      canvas.translate(w * 0.40, h * 0.50);
      canvas.rotate(-0.2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: w * 0.38,
            height: h * 0.68,
          ),
          const Radius.circular(2),
        ),
        cardPaint,
      );
      canvas.restore();

      canvas.save();
      canvas.translate(w * 0.62, h * 0.50);
      canvas.rotate(0.2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset.zero,
            width: w * 0.38,
            height: h * 0.68,
          ),
          const Radius.circular(2),
        ),
        cardPaint,
      );
      canvas.restore();
    } else if (slug.contains('palm')) {
      // Open hand
      final handPaint = Paint()..color = const Color(0xFFD97706);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.25, h * 0.40, w * 0.50, h * 0.50),
          const Radius.circular(4),
        ),
        handPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.26, h * 0.15, w * 0.10, h * 0.35),
          const Radius.circular(3),
        ),
        handPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.39, h * 0.10, w * 0.10, h * 0.40),
          const Radius.circular(3),
        ),
        handPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.52, h * 0.12, w * 0.10, h * 0.38),
          const Radius.circular(3),
        ),
        handPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.65, h * 0.20, w * 0.09, h * 0.30),
          const Radius.circular(3),
        ),
        handPaint,
      );
    } else {
      // Lotus flower
      final lotusPaint = Paint()
        ..color = const Color(0xFFD97706)
        ..style = PaintingStyle.fill;
      final p = Path()
        ..moveTo(w * 0.50, h * 0.15)
        ..quadraticBezierTo(w * 0.62, h * 0.45, w * 0.50, h * 0.78)
        ..quadraticBezierTo(w * 0.38, h * 0.45, w * 0.50, h * 0.15)
        ..close();
      canvas.drawPath(p, lotusPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
