import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _glowAnimation;
  Timer? _navigationTimer;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.75, curve: Curves.easeIn),
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.forward();

    // Auto-navigate to Next Screen (Dashboard if authenticated, otherwise Login)
    _navigationTimer = Timer(const Duration(milliseconds: 2800), () {
      if (mounted) {
        _navigateNext();
      }
    });
  }

  Future<void> _navigateNext() async {
    if (!mounted) return;
    var authState = context.read<AuthCubit>().state;
    if (authState is AuthInitial || authState is AuthLoading) {
      await context.read<AuthCubit>().checkCurrentUser();
      if (!mounted) return;
      authState = context.read<AuthCubit>().state;
    }
    if (authState is Authenticated) {
      if (authState.needsProfileSetup) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.profileSetup,
          arguments: authState.user,
        );
      } else {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.dashboard,
          arguments: authState.user,
        );
      }
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _navigationTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.midnightNavy,
      body: GestureDetector(
        onTap: _navigateNext, // Tap anywhere to skip
        child: Stack(
          children: [
            // Midnight Depth Gradient Background
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: AppColors.midnightDepthGradient,
                ),
              ),
            ),

            // Animated Celestial Glow
            AnimatedBuilder(
              animation: _glowAnimation,
              builder: (context, child) {
                return Center(
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.saffronGold.withValues(
                            alpha: _glowAnimation.value * 0.4,
                          ),
                          AppColors.darkGradMid.withValues(
                            alpha: _glowAnimation.value * 0.2,
                          ),
                          Colors.transparent,
                        ],
                        stops: const [0.0, 0.55, 1.0],
                      ),
                    ),
                  ),
                );
              },
            ),

            // Decorative Geometric Chakra Outline
            Center(
              child: Opacity(
                opacity: 0.08,
                child: Container(
                  width: 360,
                  height: 360,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.saffronGold,
                      width: 1.5,
                    ),
                  ),
                  child: CustomPaint(painter: _VastuWheelChakraPainter()),
                ),
              ),
            ),

            // Foreground Content
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Logo Card with golden shadow
                        Container(
                          width: 125,
                          height: 125,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.pureWhite,
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.saffronGold.withValues(
                                  alpha: 0.35,
                                ),
                                blurRadius: 28,
                                spreadRadius: 3,
                                offset: const Offset(0, 6),
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Image.asset(
                              AppAssets.appLogo,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return const Center(
                                  child: Icon(
                                    Icons.auto_awesome,
                                    size: 54,
                                    color: AppColors.saffronGold,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Title in Playfair Display (Display XL 48px)
                        Text(
                          AppStrings.appName,
                          textAlign: TextAlign.center,
                          style: AppTypography.displayXL(
                            color: AppColors.pureWhite,
                          ).copyWith(fontSize: 32, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle & Tagline in Manrope (Caption SM 14px)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 16,
                              height: 1.5,
                              color: AppColors.saffronGold,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Text(
                                AppStrings.appTagline,
                                style: AppTypography.captionSM(
                                  color: AppColors.himalayanMist,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            Container(
                              width: 16,
                              height: 1.5,
                              color: AppColors.saffronGold,
                            ),
                          ],
                        ),

                        const SizedBox(height: 44),

                        // Progress line in Saffron Gold
                        SizedBox(
                          width: 110,
                          child: LinearProgressIndicator(
                            backgroundColor: AppColors.himalayanMist.withValues(
                              alpha: 0.15,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.saffronGold,
                            ),
                            minHeight: 2.5,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom skip prompt
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Tap anywhere to continue',
                  style: AppTypography.captionXS(
                    color: AppColors.himalayanMist.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VastuWheelChakraPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final paint = Paint()
      ..color = AppColors.saffronGold
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 16; i++) {
      final angle = (i * 22.5) * (math.pi / 180);
      final dest = center + Offset.fromDirection(angle, radius);
      canvas.drawLine(center, dest, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
