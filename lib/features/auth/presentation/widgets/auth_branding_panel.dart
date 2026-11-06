import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class AuthBrandingPanel extends StatelessWidget {
  final bool isCompact;

  const AuthBrandingPanel({super.key, this.isCompact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 24 : 36,
        vertical: isCompact ? 28 : 44,
      ),
      decoration: const BoxDecoration(
        color: AppColors.midnightNavy,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          bottomLeft: Radius.circular(28),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo Card with Saffron Gold Radiant Aura Glow
          Container(
            width: isCompact ? 100 : 120,
            height: isCompact ? 100 : 120,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.saffronGold.withValues(alpha: 0.65),
                  blurRadius: 36,
                  spreadRadius: 6,
                  offset: const Offset(0, 2),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                AppAssets.appLogo,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(
                      Icons.auto_awesome,
                      size: 48,
                      color: AppColors.saffronGold,
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // App Name in Playfair Display
          Text(
            AppStrings.appName,
            style: AppTypography.headingLG(color: AppColors.pureWhite).copyWith(
              fontSize: isCompact ? 26 : 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle in Saffron Gold
          Text(
            AppStrings.appSubtitle,
            textAlign: TextAlign.center,
            style: AppTypography.captionXS(
              color: AppColors.saffronGold,
              fontWeight: FontWeight.w700,
            ).copyWith(fontSize: isCompact ? 10 : 11, letterSpacing: 1.4),
          ),
          const SizedBox(height: 24),

          // 3 Feature Bullets with Gold Sparkle
          _buildBulletItem(AppStrings.feature1),
          const SizedBox(height: 10),
          _buildBulletItem(AppStrings.feature2),
          const SizedBox(height: 10),
          _buildBulletItem(AppStrings.feature3),

          const SizedBox(height: 28),

          // Brand Pillars Footer
          Text(
            AppStrings.brandPillars,
            textAlign: TextAlign.center,
            style: AppTypography.captionXS(
              color: AppColors.himalayanMist.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ).copyWith(fontSize: isCompact ? 11 : 12, letterSpacing: 0.8),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem(String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.saffronGold.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.auto_awesome,
            size: 11,
            color: AppColors.saffronGold,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            text,
            style: AppTypography.captionSM(
              color: AppColors.pureWhite.withValues(alpha: 0.9),
              fontWeight: FontWeight.w500,
            ).copyWith(fontSize: isCompact ? 12 : 13),
          ),
        ),
      ],
    );
  }
}
