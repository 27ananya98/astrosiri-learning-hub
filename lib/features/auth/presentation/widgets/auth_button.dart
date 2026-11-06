import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

enum AuthButtonType { google, email }

class AuthButton extends StatelessWidget {
  final String text;
  final AuthButtonType type;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AuthButton({
    super.key,
    required this.text,
    required this.type,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: AppColors.pureBlack,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF232D3F), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.saffronGold,
                        ),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildIcon(),
                      const SizedBox(width: 12),
                      Text(
                        text,
                        style: AppTypography.buttonLabel(
                          color: AppColors.pureWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (type == AuthButtonType.google) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CustomPaint(
          painter: GoogleLogoPainter(backgroundColor: AppColors.pureBlack),
        ),
      );
    }
    return const Icon(
      Icons.mail_outline_rounded,
      color: AppColors.pureWhite,
      size: 20,
    );
  }
}

class GoogleLogoPainter extends CustomPainter {
  final Color? backgroundColor;

  const GoogleLogoPainter({this.backgroundColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Official Google "G" vector geometry normalized to 24x24 grid
    final double s = size.width / 24.0;

    // 1. Blue segment (#4285F4)
    final bluePaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final bluePath = Path();
    bluePath.moveTo(s * 22.5600, s * 12.2500);
    bluePath.cubicTo(
      s * 22.5600,
      s * 11.4700,
      s * 22.4900,
      s * 10.7200,
      s * 22.3600,
      s * 10.0000,
    );
    bluePath.lineTo(s * 12.0000, s * 10.0000);
    bluePath.lineTo(s * 12.0000, s * 14.2600);
    bluePath.lineTo(s * 17.9200, s * 14.2600);
    bluePath.cubicTo(
      s * 17.6600,
      s * 15.6300,
      s * 16.8800,
      s * 16.7900,
      s * 15.7100,
      s * 17.5700,
    );
    bluePath.lineTo(s * 15.7100, s * 20.3400);
    bluePath.lineTo(s * 19.2800, s * 20.3400);
    bluePath.cubicTo(
      s * 21.3600,
      s * 18.4200,
      s * 22.5600,
      s * 15.6000,
      s * 22.5600,
      s * 12.2500,
    );
    bluePath.close();
    canvas.drawPath(bluePath, bluePaint);

    // 2. Green segment (#34A853)
    final greenPaint = Paint()
      ..color = const Color(0xFF34A853)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final greenPath = Path();
    greenPath.moveTo(s * 12.0000, s * 23.0000);
    greenPath.cubicTo(
      s * 14.9700,
      s * 23.0000,
      s * 17.4600,
      s * 22.0200,
      s * 19.2800,
      s * 20.3400,
    );
    greenPath.lineTo(s * 15.7100, s * 17.5700);
    greenPath.cubicTo(
      s * 14.7300,
      s * 18.2300,
      s * 13.4800,
      s * 18.6300,
      s * 12.0000,
      s * 18.6300,
    );
    greenPath.cubicTo(
      s * 9.1400,
      s * 18.6300,
      s * 6.7100,
      s * 16.7000,
      s * 5.8400,
      s * 14.1000,
    );
    greenPath.lineTo(s * 2.1800, s * 14.1000);
    greenPath.lineTo(s * 2.1800, s * 16.9400);
    greenPath.cubicTo(
      s * 3.9900,
      s * 20.5300,
      s * 7.7000,
      s * 23.0000,
      s * 12.0000,
      s * 23.0000,
    );
    greenPath.close();
    canvas.drawPath(greenPath, greenPaint);

    // 3. Yellow segment (#FBBC05)
    final yellowPaint = Paint()
      ..color = const Color(0xFFFBBC05)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final yellowPath = Path();
    yellowPath.moveTo(s * 5.8400, s * 14.0900);
    yellowPath.cubicTo(
      s * 5.6200,
      s * 13.4300,
      s * 5.4900,
      s * 12.7300,
      s * 5.4900,
      s * 12.0000,
    );
    yellowPath.cubicTo(
      s * 5.4900,
      s * 11.2700,
      s * 5.6200,
      s * 10.5700,
      s * 5.8400,
      s * 9.9100,
    );
    yellowPath.lineTo(s * 5.8400, s * 7.0600);
    yellowPath.lineTo(s * 2.1800, s * 7.0600);
    yellowPath.cubicTo(
      s * 1.4300,
      s * 8.5500,
      s * 1.0000,
      s * 10.2200,
      s * 1.0000,
      s * 12.0000,
    );
    yellowPath.cubicTo(
      s * 1.0000,
      s * 13.7800,
      s * 1.4300,
      s * 15.4500,
      s * 2.1800,
      s * 16.9400,
    );
    yellowPath.lineTo(s * 5.0300, s * 14.7200);
    yellowPath.lineTo(s * 5.8400, s * 14.0900);
    yellowPath.close();
    canvas.drawPath(yellowPath, yellowPaint);

    // 4. Red segment (#EA4335)
    final redPaint = Paint()
      ..color = const Color(0xFFEA4335)
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final redPath = Path();
    redPath.moveTo(s * 12.0000, s * 5.3800);
    redPath.cubicTo(
      s * 13.6200,
      s * 5.3800,
      s * 15.0600,
      s * 5.9400,
      s * 16.2100,
      s * 7.0200,
    );
    redPath.lineTo(s * 19.3600, s * 3.8700);
    redPath.cubicTo(
      s * 17.4500,
      s * 2.0900,
      s * 14.9700,
      s * 1.0000,
      s * 12.0000,
      s * 1.0000,
    );
    redPath.cubicTo(
      s * 7.7000,
      s * 1.0000,
      s * 3.9900,
      s * 3.4700,
      s * 2.1800,
      s * 7.0600,
    );
    redPath.lineTo(s * 5.8400, s * 9.9000);
    redPath.cubicTo(
      s * 6.7100,
      s * 7.3000,
      s * 9.1400,
      s * 5.3800,
      s * 12.0000,
      s * 5.3800,
    );
    redPath.close();
    canvas.drawPath(redPath, redPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
