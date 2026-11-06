import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/offline_google_fonts.dart';
import '../../../../core/utils/contact_validator.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../domain/models/user.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

class ProfileSetupScreen extends StatefulWidget {
  final User user;

  const ProfileSetupScreen({super.key, required this.user});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _mobileController;

  bool _isEmailLocked = false;
  bool _isMobileLocked = false;

  @override
  void initState() {
    super.initState();
    final initialName = widget.user.fullName == 'Learner'
        ? ''
        : widget.user.fullName;
    _nameController = TextEditingController(text: initialName);
    _emailController = TextEditingController(text: widget.user.email ?? '');
    _mobileController = TextEditingController(text: widget.user.mobile ?? '');

    // Lock if the field was the source of authentication
    if (widget.user.loginContact == 'EMAIL' &&
        (widget.user.email?.isNotEmpty ?? false)) {
      _isEmailLocked = true;
    } else if (widget.user.loginContact == 'MOBILE' &&
        (widget.user.mobile?.isNotEmpty ?? false)) {
      _isMobileLocked = true;
    } else if (widget.user.email?.isNotEmpty ?? false) {
      _isEmailLocked = true;
    } else if (widget.user.mobile?.isNotEmpty ?? false) {
      _isMobileLocked = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _handleSaveProfile(BuildContext context) {
    if (!_formKey.currentState!.validate()) return;

    final updatedUser = widget.user.copyWith(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      mobile: _mobileController.text.trim(),
      isNewUser: false,
      isProfileCompleted: true,
    );

    context.read<AuthCubit>().updateProfile(updatedUser);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Authenticated) {
          AppToast.success(
            context,
            'Profile completed! Welcome, ${state.user.fullName}.',
            title: 'Welcome',
          );

          Navigator.pushReplacementNamed(
            context,
            AppRoutes.dashboard,
            arguments: state.user,
          );
        } else if (state is AuthError) {
          AppToast.error(
            context,
            'Failed to save profile: ${state.message}',
            title: 'Save Failed',
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF16254E),
                  Color(0xFF0D1836),
                  Color(0xFF070E22),
                  Color(0xFF030712),
                ],
                stops: [0.0, 0.35, 0.7, 1.0],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Normal Back Button
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
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
                              tooltip: 'Back',
                              onPressed: () {
                                if (Navigator.canPop(context)) {
                                  Navigator.pop(context);
                                } else {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    AppRoutes.login,
                                  );
                                }
                              },
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Header Tag
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.saffronGold.withValues(
                                  alpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.saffronGold.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'FIRST-TIME SETUP',
                                style: GoogleFonts.manrope(
                                  fontSize: 10,
                                  color: AppColors.saffronGold,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Heading in Playfair Display
                          Text(
                            'Complete Your Profile',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Text(
                            'Please provide your name and contact details to set up your Vedic Learner account.',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              color: AppColors.himalayanMist.withValues(
                                alpha: 0.8,
                              ),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Full Name Field
                          _buildFieldLabel('FULL NAME', isRequired: true),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: _buildInputDecoration(
                              hintText: 'e.g. Ananya Srivastava',
                              prefixIcon: Icons.person_outline_rounded,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),

                          // Mobile Field
                          _buildFieldLabel(
                            'MOBILE NUMBER',
                            isRequired: true,
                            isLocked: _isMobileLocked,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _mobileController,
                            readOnly: _isMobileLocked,
                            keyboardType: TextInputType.phone,
                            maxLength: 10,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            style: TextStyle(
                              color: _isMobileLocked
                                  ? Colors.white70
                                  : Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: _buildInputDecoration(
                              hintText: '10-digit mobile number',
                              prefixIcon: Icons.phone_android_rounded,
                              isLocked: _isMobileLocked,
                            ),
                            validator: validateMobileNumber,
                          ),
                          const SizedBox(height: 22),

                          // Email Field
                          _buildFieldLabel(
                            'EMAIL ADDRESS',
                            isRequired: true,
                            isLocked: _isEmailLocked,
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            readOnly: _isEmailLocked,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                              color: _isEmailLocked
                                  ? Colors.white70
                                  : Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: _buildInputDecoration(
                              hintText: 'name@example.com',
                              prefixIcon: Icons.email_outlined,
                              isLocked: _isEmailLocked,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Please enter your email address';
                              }
                              if (!val.contains('@') || !val.contains('.')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 36),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.saffronGold,
                                foregroundColor: AppColors.midnightNavy,
                                elevation: 4,
                                shadowColor: AppColors.saffronGold.withValues(
                                  alpha: 0.4,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: isLoading
                                  ? null
                                  : () => _handleSaveProfile(context),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              AppColors.midnightNavy,
                                            ),
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Continue to Vedic Hub',
                                          style: GoogleFonts.manrope(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.midnightNavy,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.arrow_forward_rounded,
                                          size: 18,
                                          color: AppColors.midnightNavy,
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFieldLabel(
    String label, {
    bool isRequired = false,
    bool isLocked = false,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.himalayanMist,
            letterSpacing: 1.0,
          ),
        ),
        if (isRequired) ...[
          const SizedBox(width: 4),
          const Text(
            '*',
            style: TextStyle(
              color: Color(0xFFF87171),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
        if (isLocked) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF16A34A).withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 12,
                  color: Color(0xFF4ADE80),
                ),
                SizedBox(width: 4),
                Text(
                  'VERIFIED',
                  style: TextStyle(
                    fontSize: 9,
                    color: Color(0xFF4ADE80),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    bool isLocked = false,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.35),
        fontSize: 14,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: isLocked ? Colors.white38 : AppColors.saffronGold,
        size: 20,
      ),
      filled: true,
      fillColor: isLocked
          ? const Color(0xFF0A1224).withValues(alpha: 0.8)
          : const Color(0xFF101B33).withValues(alpha: 0.8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1.2,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.16),
          width: 1.2,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.saffronGold, width: 1.6),
      ),
    );
  }
}
