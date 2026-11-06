import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/contact_validator.dart';
import '../../../../core/widgets/app_toast.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Full-Screen OTP Verification Screen.
/// Provides edge-to-edge celestial theme, normal back button, 6-digit numeric input,
/// resend countdown timer, and inline error feedback.
class OtpVerificationScreen extends StatefulWidget {
  final String contact;

  const OtpVerificationScreen({super.key, required this.contact});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  Timer? _resendTimer;
  int _resendCountdown = 30;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _resendCountdown = 30;
      _canResend = false;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCountdown > 1) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
        setState(() {
          _resendCountdown = 0;
          _canResend = true;
        });
      }
    });
  }

  void _handleResend() {
    if (!_canResend) return;
    context.read<AuthCubit>().sendOtp(widget.contact);
    _startResendTimer();
    AppToast.info(
      context,
      'A new verification code has been dispatched.',
      title: 'Code Sent',
    );
  }

  void _handleVerify(BuildContext context) {
    final validation = ContactValidator.validateOtp(_otpController.text);
    if (!validation.isValid) {
      final errorMessage =
          validation.errorMessage ??
          'Please enter the 6-digit verification code.';
      AppToast.error(
        context,
        errorMessage,
        title:
            errorMessage.contains('digits only') ||
                errorMessage.contains('cannot exceed')
            ? 'Invalid OTP'
            : 'Incomplete OTP',
      );
      _otpFocusNode.requestFocus();
      return;
    }

    context.read<AuthCubit>().verifyOtp(
      widget.contact,
      validation.sanitizedValue,
    );
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedContact = ContactValidator.formatContactForOtp(
      widget.contact,
    );

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          AppToast.success(
            context,
            'Verification successful! Welcome to Astrosiri Learning Hub.',
            title: 'Verified',
          );

          if (state.needsProfileSetup) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.profileSetup,
              (route) => false,
              arguments: state.user,
            );
          } else {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.dashboard,
              (route) => false,
              arguments: state.user,
            );
          }
        }
      },
      builder: (context, state) {
        final isVerifying = state is AuthLoading;

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.celestialMidnightGradient,
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Top Navigation Bar: Normal back button (no circular container)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          visualDensity: VisualDensity.compact,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                          ),
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.black,
                            size: 16,
                          ),
                          tooltip: 'Back to Login',
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.saffronGold.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.saffronGold.withValues(
                                alpha: 0.3,
                              ),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.shield_outlined,
                                color: AppColors.saffronGold,
                                size: 14,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'SECURE AUTH',
                                style: TextStyle(
                                  color: AppColors.saffronGold,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Main Scrollable Content
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 16,
                        ),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 550),
                          curve: Curves.easeOutCubic,
                          builder: (context, progress, child) {
                            return Opacity(
                              opacity: progress,
                              child: Transform.translate(
                                offset: Offset(0, 16 * (1 - progress)),
                                child: child,
                              ),
                            );
                          },
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 420),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Celestial Astro Siri Logo Card
                                Center(
                                  child: Container(
                                    width: 90,
                                    height: 90,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppColors.saffronGold
                                              .withValues(alpha: 0.35),
                                          blurRadius: 28,
                                          spreadRadius: 2,
                                          offset: const Offset(0, 4),
                                        ),
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.45,
                                          ),
                                          blurRadius: 18,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.asset(
                                        AppAssets.appLogo,
                                        fit: BoxFit.contain,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                                  Icons.auto_awesome_rounded,
                                                  color: AppColors.saffronGold,
                                                  size: 44,
                                                ),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 28),

                                // Screen Title
                                Text(
                                  'Enter Verification Code',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.headingLG(
                                    color: AppColors.pureWhite,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 10),

                                // Subtitle with Formatted Contact
                                Text(
                                  'We have sent a 6-digit security code to',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.captionSM(
                                    color: AppColors.himalayanMist,
                                  ),
                                ),
                                const SizedBox(height: 6),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      formattedContact,
                                      style: const TextStyle(
                                        color: AppColors.saffronGold,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: const Text(
                                          'Edit',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 32),

                                // OTP 6-Digit Input Field
                                Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF162032),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _otpFocusNode.hasFocus
                                          ? AppColors.saffronGold
                                          : const Color(0xFF2E3D59),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 14,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: TextField(
                                    controller: _otpController,
                                    focusNode: _otpFocusNode,
                                    autofocus: true,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(6),
                                    ],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 26,
                                      letterSpacing: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                    cursorColor: AppColors.saffronGold,
                                    decoration: const InputDecoration(
                                      hintText: '• • • • • •',
                                      hintStyle: TextStyle(
                                        color: Colors.white30,
                                        letterSpacing: 12,
                                        fontSize: 24,
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                        vertical: 18,
                                      ),
                                      border: InputBorder.none,
                                    ),
                                    onChanged: (val) {
                                      // The input formatter keeps the value to
                                      // exactly the six digits accepted by the
                                      // OTP validator and API.
                                    },
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // Inline Error Message (if any)
                                if (state is AuthError) ...[
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 20),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(
                                        0xFFEF4444,
                                      ).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: const Color(
                                          0xFFEF4444,
                                        ).withValues(alpha: 0.4),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          color: Color(0xFFEF4444),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            state.message.isNotEmpty
                                                ? state.message
                                                : 'The verification code entered is incorrect.',
                                            style: const TextStyle(
                                              color: Color(0xFFFCA5A5),
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // Verify & Continue Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 54,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.saffronGold,
                                      foregroundColor: AppColors.midnightNavy,
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    onPressed: isVerifying
                                        ? null
                                        : () => _handleVerify(context),
                                    child: isVerifying
                                        ? const SizedBox(
                                            width: 22,
                                            height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: AppColors.midnightNavy,
                                            ),
                                          )
                                        : Text(
                                            'Verify & Continue',
                                            style: AppTypography.buttonLabel(
                                              color: AppColors.midnightNavy,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),

                                const SizedBox(height: 26),

                                // Resend Code Countdown
                                Center(
                                  child: _canResend
                                      ? TextButton.icon(
                                          onPressed: _handleResend,
                                          icon: const Icon(
                                            Icons.refresh_rounded,
                                            color: AppColors.saffronGold,
                                            size: 18,
                                          ),
                                          label: const Text(
                                            'Resend Code',
                                            style: TextStyle(
                                              color: AppColors.saffronGold,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              "Didn't receive the code? ",
                                              style: TextStyle(
                                                color: AppColors.himalayanMist,
                                                fontSize: 13,
                                              ),
                                            ),
                                            Text(
                                              'Resend in ${_resendCountdown}s',
                                              style: const TextStyle(
                                                color: AppColors.saffronGold,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
