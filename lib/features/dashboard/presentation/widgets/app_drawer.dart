import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/logout_confirmation.dart';
import '../../../../core/widgets/vedic_icons.dart';
import '../../../../domain/models/user.dart';
import '../cubit/dashboard_nav_cubit.dart';

class AppDrawer extends StatelessWidget {
  final User user;
  final VoidCallback? onProfileTap;

  const AppDrawer({super.key, required this.user, this.onProfileTap});

  Future<void> _launchExternalUrl(
    BuildContext context,
    String urlString,
  ) async {
    final uri = Uri.parse(urlString);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        AppToast.error(
          context,
          'Could not open link: $urlString',
          title: 'Link Error',
        );
      }
    } catch (e) {
      if (context.mounted) {
        AppToast.error(
          context,
          'Error opening link: $e',
          title: 'Navigation Error',
        );
      }
    }
  }

  void _openWhatsApp(BuildContext context) {
    _launchExternalUrl(context, 'https://onboarding.astrosiri.com/about-us');
  }

  void _showUnavailableSocialLink(BuildContext context, String platform) {
    AppToast.info(
      context,
      '$platform link is not available yet.',
      title: 'Social Link Unavailable',
    );
  }

  Widget _buildSocialLinkButton(BuildContext context, String platform) {
    return Tooltip(
      message: '$platform link is not available',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => _showUnavailableSocialLink(context, platform),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: SocialMediaIcon(platform: platform, size: 30),
        ),
      ),
    );
  }

  void _showAboutUsDialog(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const _AboutAstroSiriScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: AppColors.midnightNavy,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Drawer(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
        ),
        backgroundColor: AppColors.moonlitIvory,
        elevation: 14,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFF7FAFF), Color(0xFFF7F5F0), Color(0xFFFFF3E2)],
            ),
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // Subtle Vedic artwork gives the drawer the same illustrated
              // atmosphere as the navy reference design without competing
              // with the menu text.
              Positioned(
                top: 10,
                right: -42,
                child: Opacity(
                  opacity: 0.16,
                  child: VedicMandalaLineArt(width: 210, height: 190),
                ),
              ),
              Positioned(
                left: -72,
                bottom: 155,
                child: Opacity(
                  opacity: 0.045,
                  child: Image.asset(
                    AppAssets.bigLotus,
                    width: 190,
                    height: 190,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(
                      20,
                      MediaQuery.paddingOf(context).top + 18,
                      20,
                      20,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.midnightNavy, Color(0xFF1E3A67)],
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: AppColors.saffronGold,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildProfileAvatar(),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'WELCOME BACK',
                                    style: TextStyle(
                                      color: Color(0xFFF8D487),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.3,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    user.fullName.isNotEmpty
                                        ? user.fullName
                                        : 'Learner',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user.mobile?.isNotEmpty == true
                                        ? user.mobile!
                                        : (user.email?.isNotEmpty == true
                                              ? user.email!
                                              : 'Contact unavailable'),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFC7D7F0),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(
                              Icons.auto_awesome_rounded,
                              color: Color(0xFFF8D487),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                user.experience?.isNotEmpty == true
                                    ? '${user.role}  •  ${user.experience}'
                                    : user.role,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.verified_rounded,
                              color: Color(0xFF8BC6FF),
                              size: 17,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Drawer Navigation Items List
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(12, 16, 12, 10),
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(left: 8, bottom: 8),
                          child: Text(
                            'LEARN & EXPLORE',
                            style: TextStyle(
                              color: Color(0xFF7B879B),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        _buildDrawerItem(
                          icon: Icons.person_outline_rounded,
                          iconColor: AppColors.loginBlue,
                          leadingBgColor: const Color(0xFFDCEBFF),
                          title: 'My Profile',
                          subtitle: 'View your personal details',
                          onTap: () {
                            Navigator.pop(context);
                            try {
                              context.read<DashboardNavCubit>().goToProfile();
                            } catch (_) {}
                            onProfileTap?.call();
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.info_outline_rounded,
                          iconColor: const Color(0xFFC47D0A),
                          leadingBgColor: const Color(0xFFFFEBC2),
                          title: 'About Us',
                          subtitle: 'Vedic Academy mission & mentors',
                          onTap: () {
                            Navigator.pop(context);
                            _showAboutUsDialog(context);
                          },
                        ),
                        _buildDrawerItem(
                          icon: Icons.chat_rounded,
                          iconColor: const Color(0xFF15803D),
                          leadingBgColor: const Color(0xFFDCFCE7),
                          badgeText: 'WhatsApp',
                          badgeColor: const Color(0xFF166534),
                          badgeBgColor: const Color(0xFFDCFCE7),
                          title: 'Chat with Us',
                          subtitle: 'Direct support & consultation',
                          onTap: () {
                            Navigator.pop(context);
                            _openWhatsApp(context);
                          },
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(8, 18, 8, 8),
                          child: Text(
                            'ACCOUNT',
                            style: TextStyle(
                              color: Color(0xFF7B879B),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        _buildDrawerItem(
                          icon: Icons.logout_rounded,
                          iconColor: const Color(0xFFDC2626),
                          leadingBgColor: const Color(0xFFFEE2E2),
                          title: 'Log Out',
                          titleColor: const Color(0xFFB91C1C),
                          subtitle: 'Sign out of current account',
                          trailingColor: const Color(0xFFDC2626),
                          onTap: () => showLogoutConfirmation(
                            context,
                            closeDrawerAfterConfirmation: true,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Social Media Section
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                        decoration: BoxDecoration(
                          color: AppColors.midnightNavy,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.saffronGold.withValues(
                              alpha: 0.65,
                            ),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x220B132B),
                              blurRadius: 16,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'CONNECT WITH US',
                              style: TextStyle(
                                color: Color(0xFFB87508),
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSocialLinkButton(context, 'Facebook'),
                                _buildSocialLinkButton(context, 'Instagram'),
                                _buildSocialLinkButton(context, 'LinkedIn'),
                                _buildSocialLinkButton(context, 'X'),
                                _buildSocialLinkButton(context, 'YouTube'),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Center(
                              child: Text(
                                'Astrosiri Learning Hub  •  v1.0.0',
                                style: TextStyle(
                                  color: Color(0xFFD9E4EA),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 58,
                              width: double.infinity,
                              child: Image.asset(
                                AppAssets.bigLotus,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return SizedBox(
      width: 78,
      height: 84,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 74,
            height: 74,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF60A5FA), Color(0xFF1E3A8A)],
              ),
              border: Border.all(color: const Color(0xFFF3CC83), width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x553B82F6),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                AppAssets.userAvatar,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),
          Positioned(
            right: 0,
            bottom: 3,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.saffronGold,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.midnightNavy, width: 2),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.midnightNavy,
                size: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    Color? leadingBgColor,
    Color? titleColor,
    Color? tileColor,
    Color? trailingColor,
    String? badgeText,
    Color? badgeColor,
    Color? badgeBgColor,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      minVerticalPadding: 7,
      horizontalTitleGap: 12,
      tileColor: tileColor ?? Colors.transparent,
      shape: const RoundedRectangleBorder(),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color:
              leadingBgColor ??
              (iconColor ?? const Color(0xFFE5A93C)).withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          icon,
          color: iconColor ?? const Color(0xFFE5A93C),
          size: 20,
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                color: titleColor ?? AppColors.midnightNavy,
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (badgeText != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color:
                    badgeBgColor ??
                    (badgeColor ?? const Color(0xFFE5A93C)).withValues(
                      alpha: 0.18,
                    ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeText,
                style: TextStyle(
                  color: badgeColor ?? const Color(0xFFE5A93C),
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF7B879B), fontSize: 11.5),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: (trailingColor ?? const Color(0xFF8A9AB4)).withValues(
            alpha: 0.10,
          ),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.chevron_right_rounded,
          color: trailingColor ?? const Color(0xFF8A9AB4),
          size: 19,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _AboutAstroSiriScreen extends StatelessWidget {
  const _AboutAstroSiriScreen();

  Widget _buildValueCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.himalayanMist.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.midnightNavy.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.saffronGold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.saffronGold, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.headingMD(
                    fontWeight: FontWeight.w600,
                  ).copyWith(fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTypography.captionSM(
                    color: const Color(0xFF506078),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.moonlitIvory,
      appBar: AppBar(
        title: const Text('About AstroSiri'),
        backgroundColor: AppColors.moonlitIvory,
        foregroundColor: AppColors.midnightNavy,
        elevation: 0,
        titleTextStyle: AppTypography.buttonLabel(
          color: AppColors.midnightNavy,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
                decoration: BoxDecoration(
                  gradient: AppColors.celestialMidnightGradient,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.midnightNavy.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -28,
                      top: -26,
                      child: Opacity(
                        opacity: 0.18,
                        child: Image.asset(
                          AppAssets.bigLotus,
                          width: 150,
                          height: 150,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Image.asset(
                              AppAssets.goldenLotusSmall,
                              width: 34,
                              height: 34,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'ASTROSIRI LEARNING HUB',
                              style: AppTypography.captionXS(
                                color: AppColors.saffronGold,
                                fontWeight: FontWeight.w700,
                              ).copyWith(letterSpacing: 1.2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text(
                          'Ancient wisdom,\nclearly learned.',
                          style: AppTypography.headingLG(
                            color: AppColors.pureWhite,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'A calm, focused space for exploring authentic subjects through structured courses and guided video lessons.',
                          style: AppTypography.bodyRegular(
                            color: AppColors.himalayanMist,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'A thoughtful way to learn',
                  style: AppTypography.headingMD(
                    color: AppColors.midnightNavy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Learn at your own pace with a clear path from subject discovery to deeper practice.',
                  style: AppTypography.bodyRegular(
                    color: const Color(0xFF506078),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              _buildValueCard(
                icon: Icons.auto_stories_rounded,
                title: 'Learn with context',
                description:
                    'Move through organized subjects and lessons designed to make every idea easier to follow.',
              ),
              const SizedBox(height: 12),
              _buildValueCard(
                icon: Icons.play_circle_outline_rounded,
                title: 'Study at your pace',
                description:
                    'Return to focused video lessons whenever you are ready to continue your practice.',
              ),
              const SizedBox(height: 12),
              _buildValueCard(
                icon: Icons.verified_outlined,
                title: 'Rooted in authenticity',
                description:
                    'A modern learning experience shaped around respect for traditional knowledge.',
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    AppAssets.goldenLotusSmall,
                    width: 20,
                    height: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Learn clearly. Practice deeply.',
                    style: AppTypography.captionSM(
                      color: AppColors.midnightNavy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
