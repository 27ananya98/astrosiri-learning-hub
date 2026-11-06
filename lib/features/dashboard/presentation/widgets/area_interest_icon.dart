import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Small, scalable line-art marks used by the Areas of Interest cards.
///
/// These are intentionally painted in the app rather than loaded from remote
/// artwork, so every subject keeps the same warm-gold visual language and
/// remains sharp on high-density screens.
class AreaInterestIcon extends StatelessWidget {
  final String area;
  final double size;

  const AreaInterestIcon({super.key, required this.area, this.size = 52});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _AreaInterestIconPainter(_iconKindFor(area)),
    );
  }
}

enum _AreaInterestIconKind {
  astrology,
  vastu,
  numerology,
  palmistry,
  tarot,
  other,
}

_AreaInterestIconKind _iconKindFor(String value) {
  final label = value.toLowerCase();
  if (label.contains('astro')) return _AreaInterestIconKind.astrology;
  if (label.contains('vastu')) return _AreaInterestIconKind.vastu;
  if (label.contains('numer')) return _AreaInterestIconKind.numerology;
  if (label.contains('palm')) return _AreaInterestIconKind.palmistry;
  if (label.contains('tarot')) return _AreaInterestIconKind.tarot;
  return _AreaInterestIconKind.other;
}

class _AreaInterestIconPainter extends CustomPainter {
  static const _gold = Color(0xFFD88912);
  static const _softGold = Color(0xFFE6A338);

  final _AreaInterestIconKind kind;

  const _AreaInterestIconPainter(this.kind);

  Paint _stroke({double width = 2.0, Color color = _gold}) {
    return Paint()
      ..color = color
      ..isAntiAlias = true
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
  }

  Paint _fill({Color color = _gold}) {
    return Paint()
      ..color = color
      ..isAntiAlias = true
      ..style = PaintingStyle.fill;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = math.min(size.width, size.height) / 64;
    canvas.save();
    canvas.scale(scale, scale);
    switch (kind) {
      case _AreaInterestIconKind.astrology:
        _drawAstrology(canvas);
      case _AreaInterestIconKind.vastu:
        _drawVastu(canvas);
      case _AreaInterestIconKind.numerology:
        _drawNumerology(canvas);
      case _AreaInterestIconKind.palmistry:
        _drawPalmistry(canvas);
      case _AreaInterestIconKind.tarot:
        _drawTarot(canvas);
      case _AreaInterestIconKind.other:
        _drawLotus(canvas);
    }
    canvas.restore();
  }

  void _drawAstrology(Canvas canvas) {
    final center = const Offset(32, 32);
    final line = _stroke(width: 1.5);
    canvas.drawCircle(center, 22, line);
    canvas.drawCircle(center, 16.5, line);
    canvas.drawCircle(center, 7, line);
    canvas.drawLine(const Offset(32, 10), const Offset(32, 54), line);
    canvas.drawLine(const Offset(10, 32), const Offset(54, 32), line);
    canvas.drawLine(const Offset(16.5, 16.5), const Offset(47.5, 47.5), line);
    canvas.drawLine(const Offset(47.5, 16.5), const Offset(16.5, 47.5), line);
    canvas.drawCircle(center, 4.2, _fill(color: const Color(0xFFFFD26A)));
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 9),
      -math.pi * 0.2,
      math.pi * 1.15,
      false,
      _stroke(width: 1.3, color: _softGold),
    );
    for (var i = 0; i < 12; i++) {
      final angle = (math.pi * 2 * i) / 12;
      final point = Offset(
        32 + math.cos(angle) * 24,
        32 + math.sin(angle) * 24,
      );
      canvas.drawCircle(point, 1.35, _fill());
    }
    _drawFourPointStar(canvas, const Offset(8, 13), 2.5);
    _drawFourPointStar(canvas, const Offset(56, 49), 2.5);
  }

  void _drawVastu(Canvas canvas) {
    final line = _stroke(width: 1.8);
    final inner = _stroke(width: 1.4, color: _softGold);
    final square = Path()
      ..moveTo(20, 20)
      ..lineTo(44, 20)
      ..lineTo(44, 44)
      ..lineTo(20, 44)
      ..close();
    canvas.drawPath(square, line);
    canvas.drawPath(
      Path()
        ..moveTo(25, 25)
        ..lineTo(39, 25)
        ..lineTo(39, 39)
        ..lineTo(25, 39)
        ..close(),
      inner,
    );
    final house = Path()
      ..moveTo(25, 32)
      ..lineTo(32, 26)
      ..lineTo(39, 32)
      ..moveTo(27.5, 31)
      ..lineTo(27.5, 38)
      ..lineTo(36.5, 38)
      ..lineTo(36.5, 31);
    canvas.drawPath(house, line);
    canvas.drawLine(const Offset(32, 9), const Offset(32, 17), line);
    canvas.drawLine(const Offset(32, 47), const Offset(32, 55), line);
    canvas.drawLine(const Offset(9, 32), const Offset(17, 32), line);
    canvas.drawLine(const Offset(47, 32), const Offset(55, 32), line);
    _drawArrow(canvas, const Offset(32, 7), const Offset(32, 13));
    _drawArrow(canvas, const Offset(32, 57), const Offset(32, 51));
    _drawArrow(canvas, const Offset(7, 32), const Offset(13, 32));
    _drawArrow(canvas, const Offset(57, 32), const Offset(51, 32));
  }

  void _drawNumerology(Canvas canvas) {
    final center = const Offset(32, 32);
    final line = _stroke(width: 1.6);
    canvas.drawCircle(center, 20, line);
    canvas.drawCircle(center, 13, line);
    canvas.drawCircle(center, 8.5, _fill(color: const Color(0xFFFFD26A)));
    for (var i = 0; i < 8; i++) {
      final angle = (math.pi * 2 * i) / 8 - math.pi / 2;
      final start = Offset(
        32 + math.cos(angle) * 21,
        32 + math.sin(angle) * 21,
      );
      final end = Offset(32 + math.cos(angle) * 27, 32 + math.sin(angle) * 27);
      canvas.drawLine(start, end, line);
      canvas.drawCircle(end, 1.5, _fill());
    }
    final numberStyle = const TextStyle(
      color: _gold,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      height: 1,
    );
    final painter = TextPainter(
      text: TextSpan(text: '7', style: numberStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(32 - painter.width / 2, 32 - painter.height / 2),
    );
  }

  void _drawPalmistry(Canvas canvas) {
    final line = _stroke(width: 1.8);
    final palm = Path()
      ..moveTo(26, 51)
      ..cubicTo(22, 47, 20, 43, 20, 38)
      ..lineTo(20, 25)
      ..cubicTo(20, 23, 23, 23, 24, 25)
      ..lineTo(25, 36)
      ..lineTo(26, 19)
      ..cubicTo(26, 16, 30, 16, 30, 19)
      ..lineTo(30.5, 35)
      ..lineTo(31, 15)
      ..cubicTo(31, 12, 35, 12, 35, 15)
      ..lineTo(35, 35)
      ..lineTo(36, 18)
      ..cubicTo(36, 15, 40, 16, 40, 19)
      ..lineTo(40, 36)
      ..lineTo(42, 24)
      ..cubicTo(42.5, 21, 46, 22, 46, 25)
      ..lineTo(45, 40)
      ..cubicTo(45, 46, 40, 51, 35, 53)
      ..close();
    canvas.drawPath(palm, line);
    canvas.drawLine(const Offset(25, 38), const Offset(39, 34), line);
    canvas.drawArc(Rect.fromLTWH(27, 33, 14, 15), 0.35, 2.1, false, line);
    canvas.drawArc(
      Rect.fromLTWH(28, 38, 13, 9),
      0.2,
      1.8,
      false,
      _stroke(width: 1.2, color: _softGold),
    );
    _drawFourPointStar(canvas, const Offset(12, 20), 2.2);
    _drawFourPointStar(canvas, const Offset(52, 46), 2.2);
  }

  void _drawTarot(Canvas canvas) {
    final line = _stroke(width: 1.5);
    _drawCard(canvas, const Offset(11, 18), -0.18, line, true);
    _drawCard(canvas, const Offset(22, 12), 0, line, false);
    _drawCard(canvas, const Offset(33, 18), 0.18, line, true);
    _drawFourPointStar(canvas, const Offset(9, 10), 2.2);
    _drawFourPointStar(canvas, const Offset(55, 10), 2.2);
  }

  void _drawCard(
    Canvas canvas,
    Offset origin,
    double angle,
    Paint line,
    bool moon,
  ) {
    canvas.save();
    canvas.translate(origin.dx + 9, origin.dy + 17);
    canvas.rotate(angle);
    final rect = RRect.fromRectAndRadius(
      const Rect.fromLTWH(-9, -17, 18, 34),
      const Radius.circular(2),
    );
    canvas.drawRRect(rect, line);
    canvas.drawCircle(const Offset(0, -2), 4.5, line);
    if (moon) {
      canvas.drawArc(
        const Rect.fromLTWH(-2, -4, 6, 8),
        -math.pi / 2,
        math.pi,
        false,
        _stroke(width: 1.1, color: _softGold),
      );
    } else {
      canvas.drawLine(const Offset(0, -6), const Offset(0, 2), line);
      canvas.drawLine(const Offset(-4, -2), const Offset(4, -2), line);
    }
    canvas.drawLine(const Offset(-5, 9), const Offset(5, 9), line);
    canvas.restore();
  }

  void _drawLotus(Canvas canvas) {
    final line = _stroke(width: 1.6);
    canvas.drawArc(
      const Rect.fromLTWH(17, 35, 30, 16),
      math.pi,
      math.pi,
      false,
      line,
    );
    canvas.drawPath(
      Path()
        ..moveTo(32, 47)
        ..cubicTo(24, 40, 24, 30, 32, 24)
        ..cubicTo(40, 30, 40, 40, 32, 47)
        ..moveTo(32, 47)
        ..cubicTo(20, 44, 16, 37, 18, 31)
        ..cubicTo(26, 32, 30, 38, 32, 47)
        ..moveTo(32, 47)
        ..cubicTo(44, 44, 48, 37, 46, 31)
        ..cubicTo(38, 32, 34, 38, 32, 47),
      line,
    );
  }

  void _drawArrow(Canvas canvas, Offset tip, Offset tail) {
    final line = _stroke(width: 1.4);
    canvas.drawLine(tail, tip, line);
    final direction = (tip - tail);
    final unit = direction / direction.distance;
    final perpendicular = Offset(-unit.dy, unit.dx);
    final left = tip - unit * 4 + perpendicular * 2.2;
    final right = tip - unit * 4 - perpendicular * 2.2;
    canvas.drawLine(tip, left, line);
    canvas.drawLine(tip, right, line);
  }

  void _drawFourPointStar(Canvas canvas, Offset center, double radius) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius * 0.34, center.dy - radius * 0.34)
      ..lineTo(center.dx + radius, center.dy)
      ..lineTo(center.dx + radius * 0.34, center.dy + radius * 0.34)
      ..lineTo(center.dx, center.dy + radius)
      ..lineTo(center.dx - radius * 0.34, center.dy + radius * 0.34)
      ..lineTo(center.dx - radius, center.dy)
      ..lineTo(center.dx - radius * 0.34, center.dy - radius * 0.34)
      ..close();
    canvas.drawPath(path, _fill(color: _softGold));
  }

  @override
  bool shouldRepaint(covariant _AreaInterestIconPainter oldDelegate) {
    return oldDelegate.kind != kind;
  }
}
