import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/offline_google_fonts.dart';
import '../../../../core/utils/contact_validator.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../domain/models/user.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/auth_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _inputController = TextEditingController();
  final _inputFocusNode = FocusNode();
  bool _isEmailMode = false;

  @override
  void dispose() {
    _inputController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _handleGoogleAuth(BuildContext context) {
    context.read<AuthCubit>().loginWithGoogle();
  }

  void _handleContinue(BuildContext context, String input) {
    context.read<AuthCubit>().sendOtp(input);
  }

  void _showLoginValidationError(ValidationResult validation) {
    AppToast.error(
      context,
      validation.errorMessage ??
          (_isEmailMode
              ? 'Please enter a valid email address.'
              : 'Please enter a valid mobile number.'),
      title: _isEmailMode ? 'Invalid Email' : 'Invalid Contact',
    );
  }

  ValidationResult _validateLoginInput(String input) {
    return _isEmailMode
        ? ContactValidator.validateEmailInput(input)
        : ContactValidator.validateLocalPhoneInput(input);
  }

  void _selectLoginMode(bool isEmail) {
    if (_isEmailMode == isEmail) return;
    setState(() {
      _isEmailMode = isEmail;
      _inputController.clear();
    });

    // Recreate the input connection after switching modes so Android and iOS
    // replace the numeric keyboard with the email keyboard immediately.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _inputFocusNode.requestFocus();
    });
  }

  Widget _buildLoginModeTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.loginBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.loginBlue.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? AppColors.pureWhite
                    : AppColors.himalayanMist,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected
                      ? AppColors.pureWhite
                      : AppColors.himalayanMist,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onAuthenticated(User user, bool needsProfileSetup) {
    if (needsProfileSetup) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.profileSetup,
        arguments: user,
      );
    } else {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.dashboard,
        arguments: user,
      );
    }
  }

  void _showFeedbackSnackBar(String message, {bool isError = false}) {
    if (message.toLowerCase().contains('cancel')) {
      AppToast.info(
        context,
        'Google sign-in was cancelled. Please try again when you are ready.',
        title: 'Sign-In Cancelled',
      );
    } else if (isError) {
      AppToast.error(context, message, title: 'Error');
    } else {
      AppToast.info(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        // Only react if LoginScreen is currently the active route on top
        if (ModalRoute.of(context)?.isCurrent != true) {
          return;
        }

        if (state is Authenticated) {
          _onAuthenticated(state.user, state.needsProfileSetup);
        } else if (state is AuthOtpSent) {
          Navigator.pushNamed(
            context,
            AppRoutes.otpVerification,
            arguments: state.identifier,
          );
        } else if (state is AuthError) {
          _showFeedbackSnackBar(state.message, isError: true);
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.celestialMidnightGradient,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: -42,
                  right: -38,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.09,
                      child: Image.asset(
                        AppAssets.bigLotus,
                        width: 260,
                        height: 260,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 132,
                  left: -28,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.10,
                      child: Image.asset(
                        AppAssets.astrologySun,
                        width: 96,
                        height: 96,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 38,
                  left: -42,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: 0.08,
                      child: Transform.rotate(
                        angle: -0.12,
                        child: Image.asset(
                          AppAssets.celestialBook,
                          width: 180,
                          height: 180,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 24,
                      ),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(milliseconds: 650),
                          curve: Curves.easeOutCubic,
                          builder: (context, progress, child) {
                            return Opacity(
                              opacity: progress,
                              child: Transform.translate(
                                offset: Offset(0, 18 * (1 - progress)),
                                child: child,
                              ),
                            );
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // White logo card with the login blue aura.
                              Center(
                                child: Container(
                                  width: 104,
                                  height: 104,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: AppColors.saffronGold.withValues(
                                        alpha: 0.65,
                                      ),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.loginBlueGlow
                                            .withValues(alpha: 0.42),
                                        blurRadius: 32,
                                        spreadRadius: 2,
                                        offset: const Offset(0, 4),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        child: Image.asset(
                                          AppAssets.appLogo,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      Positioned(
                                        right: -12,
                                        bottom: -12,
                                        child: Container(
                                          width: 34,
                                          height: 34,
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppColors.midnightNavy,
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: AppColors.saffronGold,
                                              width: 1.2,
                                            ),
                                          ),
                                          child: Image.asset(
                                            AppAssets.goldenLotusSmall,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 22),

                              Text(
                                'WELCOME BACK',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.saffronGold,
                                  letterSpacing: 2.4,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // App Title
                              Text(
                                AppStrings.appName,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),

                              // Subtitle
                              Text(
                                AppStrings.appSubtitle,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.loginBlueGlow,
                                  letterSpacing: 2.0,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Value proposition
                              Text(
                                'Your next lesson starts here.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.himalayanMist.withValues(
                                    alpha: 0.78,
                                  ),
                                  letterSpacing: 0.1,
                                ),
                              ),

                              const SizedBox(height: 38),

                              // Login mode tabs
                              Container(
                                height: 46,
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF101B33,
                                  ).withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.12),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    _buildLoginModeTab(
                                      label: 'Mobile Number',
                                      icon: Icons.phone_rounded,
                                      isSelected: !_isEmailMode,
                                      onTap: () => _selectLoginMode(false),
                                    ),
                                    _buildLoginModeTab(
                                      label: 'Email',
                                      icon: Icons.email_outlined,
                                      isSelected: _isEmailMode,
                                      onTap: () => _selectLoginMode(true),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Contact input field without an @ icon.
                              Text(
                                _isEmailMode
                                    ? 'EMAIL ADDRESS'
                                    : 'MOBILE NUMBER',
                                style: GoogleFonts.manrope(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.himalayanMist,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(height: 8),

                              TextField(
                                key: ValueKey(
                                  _isEmailMode ? 'email-input' : 'mobile-input',
                                ),
                                controller: _inputController,
                                focusNode: _inputFocusNode,
                                keyboardType: _isEmailMode
                                    ? TextInputType.emailAddress
                                    : TextInputType.phone,
                                inputFormatters: _isEmailMode
                                    ? null
                                    : [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(10),
                                      ],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: const Color(
                                    0xFF101B33,
                                  ).withValues(alpha: 0.8),
                                  hintText: _isEmailMode
                                      ? 'Enter your email address'
                                      : 'Enter your 10-digit mobile number',
                                  prefixIcon: _isEmailMode
                                      ? null
                                      : Padding(
                                          padding: const EdgeInsets.only(
                                            left: 16,
                                            right: 10,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Text(
                                                '🇮🇳',
                                                style: TextStyle(fontSize: 20),
                                              ),
                                              const SizedBox(width: 7),
                                              Text(
                                                '+91',
                                                style: GoogleFonts.manrope(
                                                  color: AppColors.pureWhite,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Container(
                                                width: 1,
                                                height: 22,
                                                color: Colors.white.withValues(
                                                  alpha: 0.2,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                  hintStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.35),
                                    fontSize: 14,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 16,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.16,
                                      ),
                                      width: 1.2,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Colors.white.withValues(
                                        alpha: 0.16,
                                      ),
                                      width: 1.2,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: AppColors.saffronGold,
                                      width: 1.6,
                                    ),
                                  ),
                                ),
                                onSubmitted: (val) {
                                  final validation = _validateLoginInput(val);
                                  if (!validation.isValid) {
                                    _showLoginValidationError(validation);
                                    return;
                                  }
                                  _handleContinue(
                                    context,
                                    validation.sanitizedValue,
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              // Primary login action in blue.
                              SizedBox(
                                height: 52,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.loginBlue,
                                    foregroundColor: AppColors.pureWhite,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 4,
                                    shadowColor: AppColors.loginBlue.withValues(
                                      alpha: 0.42,
                                    ),
                                  ),
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          final text = _inputController.text;
                                          final validation =
                                              _validateLoginInput(text);
                                          if (!validation.isValid) {
                                            _showLoginValidationError(
                                              validation,
                                            );
                                            return;
                                          }
                                          _handleContinue(
                                            context,
                                            validation.sanitizedValue,
                                          );
                                        },
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.pureWhite,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Continue',
                                              style: GoogleFonts.manrope(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.pureWhite,
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

                              const SizedBox(height: 24),

                              // OR Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                    ),
                                    child: Text(
                                      'OR',
                                      style: GoogleFonts.manrope(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white.withValues(
                                          alpha: 0.4,
                                        ),
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: Colors.white.withValues(
                                        alpha: 0.12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // Google sign-in only.
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: isLoading
                                            ? null
                                            : () => _handleGoogleAuth(context),
                                        borderRadius: BorderRadius.circular(16),
                                        child: Ink(
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF101B33),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.22,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const SizedBox(
                                                width: 24,
                                                height: 24,
                                                child: CustomPaint(
                                                  painter: GoogleLogoPainter(),
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                'Continue with Google',
                                                style: GoogleFonts.manrope(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 36),

                              // Legal Disclaimer Footer
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Text.rich(
                                  TextSpan(
                                    text: 'By continuing, you agree to our ',
                                    style: GoogleFonts.manrope(
                                      fontSize: 11,
                                      color: Colors.white.withValues(
                                        alpha: 0.45,
                                      ),
                                      height: 1.5,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Terms of Service',
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.loginBlueGlow,
                                        ),
                                      ),
                                      const TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: GoogleFonts.manrope(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.loginBlueGlow,
                                        ),
                                      ),
                                      const TextSpan(text: '.'),
                                    ],
                                  ),
                                  textAlign: TextAlign.center,
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
        );
      },
    );
  }
}
