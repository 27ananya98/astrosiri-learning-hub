import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/app_assets.dart';

/// Renders the signature Vedic Learner Avatar with an intricate golden
/// geometric mandala/halo background as seen in the official design showcase.
class VedicLearnerAvatar extends StatelessWidget {
  final double size;
  final bool showMandalaHalo;

  const VedicLearnerAvatar({
    super.key,
    this.size = 110,
    this.showMandalaHalo = true,
  });

  @override
  Widget build(BuildContext context) {
    final avatarRadius = size * 0.36;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Golden Sacred Geometry Halo / Mandala
          if (showMandalaHalo)
            CustomPaint(
              size: Size(size, size),
              painter: const _MandalaHaloPainter(),
            ),

          // 2. Avatar Container
          Container(
            width: avatarRadius * 2,
            height: avatarRadius * 2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFDE68A), // Warm cream background
              border: Border.all(color: const Color(0xFFF59E0B), width: 2.0),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22F59E0B),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                AppAssets.userAvatar,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const CustomPaint(painter: _FemaleLearnerPainter()),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the golden geometric mandala / 8-pointed star halo
class _MandalaHaloPainter extends CustomPainter {
  const _MandalaHaloPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxR = size.width * 0.48;

    final goldPaint = Paint()
      ..color = const Color(0xFFF59E0B).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final subtleGoldPaint = Paint()
      ..color = const Color(0xFFFCD34D).withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Outer concentric circles
    canvas.drawCircle(center, maxR, goldPaint);
    canvas.drawCircle(center, maxR * 0.88, subtleGoldPaint);
    canvas.drawCircle(center, maxR * 0.76, goldPaint);

    // 8-pointed interlocking star polygons
    const numPoints = 8;
    final path1 = Path();
    final path2 = Path();

    for (int i = 0; i < numPoints; i++) {
      final angle = (i * 2 * math.pi) / numPoints;
      final xOuter = center.dx + maxR * 0.98 * math.cos(angle);
      final yOuter = center.dy + maxR * 0.98 * math.sin(angle);
      final xInner =
          center.dx + maxR * 0.68 * math.cos(angle + math.pi / numPoints);
      final yInner =
          center.dy + maxR * 0.68 * math.sin(angle + math.pi / numPoints);

      if (i == 0) {
        path1.moveTo(xOuter, yOuter);
      } else {
        path1.lineTo(xOuter, yOuter);
      }
      path1.lineTo(xInner, yInner);

      // Offset star
      final angleOffset = angle + (math.pi / (numPoints * 2));
      final xo2 = center.dx + maxR * 0.92 * math.cos(angleOffset);
      final yo2 = center.dy + maxR * 0.92 * math.sin(angleOffset);
      final xi2 =
          center.dx + maxR * 0.64 * math.cos(angleOffset + math.pi / numPoints);
      final yi2 =
          center.dy + maxR * 0.64 * math.sin(angleOffset + math.pi / numPoints);

      if (i == 0) {
        path2.moveTo(xo2, yo2);
      } else {
        path2.lineTo(xo2, yo2);
      }
      path2.lineTo(xi2, yi2);
    }
    path1.close();
    path2.close();

    canvas.drawPath(path1, goldPaint);
    canvas.drawPath(path2, subtleGoldPaint);

    // Decorative rays around perimeter
    for (int i = 0; i < 24; i++) {
      final angle = (i * 2 * math.pi) / 24;
      final p1 = Offset(
        center.dx + maxR * 0.88 * math.cos(angle),
        center.dy + maxR * 0.88 * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + maxR * 0.98 * math.cos(angle),
        center.dy + maxR * 0.98 * math.sin(angle),
      );
      canvas.drawLine(p1, p2, subtleGoldPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for the vector female learner avatar matching the official reference design
class _FemaleLearnerPainter extends CustomPainter {
  const _FemaleLearnerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Warm yellow background
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFEF08A), Color(0xFFFDE047)],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // 2. Neck & Throat (extends down into V-neck)
    final skinColor = const Color(0xFFFEE2D5);
    final skinPaint = Paint()..color = skinColor;
    final neckPath = Path()
      ..moveTo(w * 0.40, h * 0.48)
      ..lineTo(w * 0.40, h * 0.78)
      ..lineTo(w * 0.50, h * 0.82)
      ..lineTo(w * 0.60, h * 0.78)
      ..lineTo(w * 0.60, h * 0.48)
      ..close();
    canvas.drawPath(neckPath, skinPaint);

    // Neck shadow under chin
    final neckShadowPaint = Paint()
      ..color = const Color(0xFFFBC4AB).withValues(alpha: 0.6);
    final neckShadowPath = Path()
      ..moveTo(w * 0.41, h * 0.50)
      ..quadraticBezierTo(w * 0.50, h * 0.60, w * 0.59, h * 0.50)
      ..lineTo(w * 0.59, h * 0.54)
      ..quadraticBezierTo(w * 0.50, h * 0.64, w * 0.41, h * 0.54)
      ..close();
    canvas.drawPath(neckShadowPath, neckShadowPaint);

    // 3. Red Crimson / Terracotta Blouse with V-Neck
    final shirtPaint = Paint()..color = const Color(0xFFB91C1C);
    final shirtPath = Path()
      ..moveTo(0, h)
      ..lineTo(w, h)
      ..lineTo(w * 0.88, h * 0.66)
      ..quadraticBezierTo(w * 0.75, h * 0.62, w * 0.62, h * 0.65)
      // V-neck descent
      ..lineTo(w * 0.50, h * 0.80)
      ..lineTo(w * 0.38, h * 0.65)
      ..quadraticBezierTo(w * 0.25, h * 0.62, w * 0.12, h * 0.66)
      ..close();
    canvas.drawPath(shirtPath, shirtPaint);

    // Subtle collar detail / V-neck lapel highlight
    final collarTrimPaint = Paint()
      ..color = const Color(0xFF991B1B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    final collarPath = Path()
      ..moveTo(w * 0.38, h * 0.65)
      ..lineTo(w * 0.50, h * 0.80)
      ..lineTo(w * 0.62, h * 0.65);
    canvas.drawPath(collarPath, collarTrimPaint);

    // 4. Back / Crown of Hair (behind face)
    final hairPaint = Paint()..color = const Color(0xFF0F172A);
    final backHairPath = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.38),
          width: w * 0.54,
          height: h * 0.58,
        ),
      );
    canvas.drawPath(backHairPath, hairPaint);

    // 5. Oval Face
    final faceRect = Rect.fromCenter(
      center: Offset(w * 0.50, h * 0.42),
      width: w * 0.38,
      height: h * 0.44,
    );
    canvas.drawOval(faceRect, skinPaint);

    // Cheeks subtle blush
    final blushPaint = Paint()
      ..color = const Color(0xFFFCA5A5).withValues(alpha: 0.35);
    canvas.drawCircle(Offset(w * 0.38, h * 0.47), w * 0.045, blushPaint);
    canvas.drawCircle(Offset(w * 0.62, h * 0.47), w * 0.045, blushPaint);

    // 6. Facial Features
    // Eyebrows (delicate arches)
    final browPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final leftBrow = Path()
      ..moveTo(w * 0.36, h * 0.36)
      ..quadraticBezierTo(w * 0.41, h * 0.33, w * 0.46, h * 0.35);
    canvas.drawPath(leftBrow, browPaint);

    final rightBrow = Path()
      ..moveTo(w * 0.54, h * 0.35)
      ..quadraticBezierTo(w * 0.59, h * 0.33, w * 0.64, h * 0.36);
    canvas.drawPath(rightBrow, browPaint);

    // Eyes (almond shaped with catchlight)
    final eyePaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawCircle(Offset(w * 0.41, h * 0.40), w * 0.032, eyePaint);
    canvas.drawCircle(Offset(w * 0.59, h * 0.40), w * 0.032, eyePaint);

    final catchPaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.42, h * 0.395), w * 0.012, catchPaint);
    canvas.drawCircle(Offset(w * 0.60, h * 0.395), w * 0.012, catchPaint);

    // Nose (minimal subtle stroke)
    final nosePaint = Paint()
      ..color = const Color(0xFFE29578).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final nosePath = Path()
      ..moveTo(w * 0.50, h * 0.42)
      ..lineTo(w * 0.50, h * 0.46)
      ..lineTo(w * 0.48, h * 0.47);
    canvas.drawPath(nosePath, nosePaint);

    // Warm Smile
    final lipPaint = Paint()
      ..color = const Color(0xFFE11D48)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final smilePath = Path()
      ..moveTo(w * 0.44, h * 0.51)
      ..quadraticBezierTo(w * 0.50, h * 0.55, w * 0.56, h * 0.51);
    canvas.drawPath(smilePath, lipPaint);

    // 7. Front Flowing Hair (Drapes symmetrically over shoulders)
    // Left hair strand
    final leftFrontHair = Path()
      ..moveTo(w * 0.50, h * 0.18) // Center part
      ..quadraticBezierTo(w * 0.36, h * 0.20, w * 0.31, h * 0.36)
      ..quadraticBezierTo(w * 0.28, h * 0.52, w * 0.32, h * 0.72)
      ..quadraticBezierTo(w * 0.34, h * 0.82, w * 0.30, h * 0.88)
      ..quadraticBezierTo(w * 0.24, h * 0.78, w * 0.22, h * 0.58)
      ..quadraticBezierTo(w * 0.22, h * 0.34, w * 0.35, h * 0.18)
      ..close();
    canvas.drawPath(leftFrontHair, hairPaint);

    // Right hair strand
    final rightFrontHair = Path()
      ..moveTo(w * 0.50, h * 0.18) // Center part
      ..quadraticBezierTo(w * 0.64, h * 0.20, w * 0.69, h * 0.36)
      ..quadraticBezierTo(w * 0.72, h * 0.52, w * 0.68, h * 0.72)
      ..quadraticBezierTo(w * 0.66, h * 0.82, w * 0.70, h * 0.88)
      ..quadraticBezierTo(w * 0.76, h * 0.78, w * 0.78, h * 0.58)
      ..quadraticBezierTo(w * 0.78, h * 0.34, w * 0.65, h * 0.18)
      ..close();
    canvas.drawPath(rightFrontHair, hairPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
