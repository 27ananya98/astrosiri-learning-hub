import 'package:flutter/material.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'auth_button.dart';

class AuthFormPanel extends StatefulWidget {
  final bool isCompact;
  final ValueChanged<String>? onContinue;
  final VoidCallback? onGoogleAuth;
  final bool isGoogleLoading;
  final bool isContinueLoading;

  const AuthFormPanel({
    super.key,
    this.isCompact = false,
    this.onContinue,
    this.onGoogleAuth,
    this.isGoogleLoading = false,
    this.isContinueLoading = false,
  });

  @override
  State<AuthFormPanel> createState() => _AuthFormPanelState();
}

class _AuthFormPanelState extends State<AuthFormPanel> {
  final _inputController = TextEditingController();
  bool _hasInput = false;

  @override
  void initState() {
    super.initState();
    _inputController.addListener(() {
      final hasText = _inputController.text.trim().isNotEmpty;
      if (hasText != _hasInput) {
        setState(() => _hasInput = hasText);
      }
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: widget.isCompact ? 24 : 40,
        vertical: widget.isCompact ? 28 : 44,
      ),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: widget.isCompact
            ? const BorderRadius.vertical(bottom: Radius.circular(28))
            : const BorderRadius.only(
                topRight: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header in Playfair Display
          Text(
            AppStrings.welcomeTitle,
            style: AppTypography.headingLG(color: AppColors.midnightNavy)
                .copyWith(
                  fontSize: widget.isCompact ? 26 : 30,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),

          // Subheader in Manrope
          Text(
            AppStrings.welcomeSubtitle,
            style: AppTypography.captionSM(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w400,
            ).copyWith(fontSize: widget.isCompact ? 13 : 14),
          ),
          const SizedBox(height: 28),

          // Label: MOBILE / EMAIL
          Text(
            AppStrings.mobileOrEmailLabel,
            style: AppTypography.captionXS(
              color: const Color(0xFF475569),
              fontWeight: FontWeight.w700,
            ).copyWith(fontSize: 11, letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),

          // Input Field (without @ or leading icon)
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.4),
            ),
            child: TextField(
              controller: _inputController,
              keyboardType: TextInputType.emailAddress,
              style: AppTypography.bodyRegular(color: AppColors.midnightNavy),
              decoration: InputDecoration(
                hintText: AppStrings.mobileOrEmailHint,
                hintStyle: AppTypography.captionSM(
                  color: const Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onSubmitted: (val) {
                if (!widget.isContinueLoading) {
                  widget.onContinue?.call(val.trim());
                }
              },
            ),
          ),
          const SizedBox(height: 18),

          // Continue → Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _hasInput
                    ? AppColors.loginBlue
                    : const Color(0xFF78889E),
                foregroundColor: AppColors.pureWhite,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: widget.isContinueLoading
                  ? null
                  : () {
                      widget.onContinue?.call(_inputController.text.trim());
                    },
              child: widget.isContinueLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          AppStrings.continueText,
                          style: AppTypography.buttonLabel(
                            color: AppColors.pureWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: AppColors.pureWhite,
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 22),

          // OR Divider
          Row(
            children: [
              const Expanded(
                child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  AppStrings.orDivider,
                  style: AppTypography.captionXS(
                    color: const Color(0xFF94A3B8),
                    fontWeight: FontWeight.w600,
                  ).copyWith(letterSpacing: 1.0),
                ),
              ),
              const Expanded(
                child: Divider(color: Color(0xFFE2E8F0), thickness: 1),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Continue with Google Button
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.pureWhite,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: widget.isGoogleLoading ? null : widget.onGoogleAuth,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: widget.isGoogleLoading
                      ? const Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: AppColors.midnightNavy,
                            ),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CustomPaint(
                                painter: GoogleLogoPainter(
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              AppStrings.continueWithGoogle,
                              style: AppTypography.buttonLabel(
                                color: const Color(0xFF1E293B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 26),

          // Legal Disclaimer
          Center(
            child: Text.rich(
              TextSpan(
                text: AppStrings.legalPrefix,
                style: AppTypography.captionXS(
                  color: const Color(0xFF64748B),
                ).copyWith(fontSize: 11),
                children: [
                  TextSpan(
                    text: AppStrings.termsOfService,
                    style: AppTypography.captionXS(
                      color: AppColors.midnightNavy,
                      fontWeight: FontWeight.w700,
                    ).copyWith(fontSize: 11),
                  ),
                  TextSpan(
                    text: AppStrings.and,
                    style: AppTypography.captionXS(
                      color: const Color(0xFF64748B),
                    ).copyWith(fontSize: 11),
                  ),
                  TextSpan(
                    text: AppStrings.privacyPolicy,
                    style: AppTypography.captionXS(
                      color: AppColors.midnightNavy,
                      fontWeight: FontWeight.w700,
                    ).copyWith(fontSize: 11),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
