import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/logout_confirmation.dart';
import '../../../../domain/models/learning_subject.dart';
import '../../../../domain/models/user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../cubit/dashboard_nav_cubit.dart';
import '../cubit/learning_cubit.dart';
import '../cubit/learning_state.dart';
import '../widgets/app_drawer.dart';
import '../widgets/area_interest_icon.dart';
import '../widgets/subject_cards.dart';
import '../widgets/subject_image_widget.dart';
import 'subject_selection_screen.dart';

class DashboardScreen extends StatefulWidget {
  final User? user;

  const DashboardScreen({super.key, this.user});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late User _currentUser;
  bool _isRefreshingSubjects = false;
  String? _recentSubjectId;
  final ScrollController _subjectsScrollController = ScrollController();
  final PageController _heroPageController = PageController();
  Timer? _heroAutoScrollTimer;
  int _heroPageIndex = 0;
  int _subjectsCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _subjectsScrollController.addListener(_updateSubjectsCarouselIndex);
    _heroAutoScrollTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || !_heroPageController.hasClients) return;
      final nextPage = (_heroPageIndex + 1) % 3;
      _heroPageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
      );
    });
    final initialUser = widget.user ?? context.read<AuthCubit>().currentUser;
    _currentUser = initialUser ?? const User(id: '', fullName: '');

    // Trigger initial load via LearningCubit
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DashboardNavCubit>().goToHome();
        final userId = _currentUser.id.isNotEmpty
            ? _currentUser.id
            : context.read<AuthCubit>().currentUser?.id ?? '';
        final token =
            _currentUser.accessToken ??
            context.read<AuthCubit>().currentUser?.accessToken;
        context.read<LearningCubit>().fetchSubjects(userId, token: token);
      }
    });
  }

  @override
  void dispose() {
    _subjectsScrollController
      ..removeListener(_updateSubjectsCarouselIndex)
      ..dispose();
    _heroAutoScrollTimer?.cancel();
    _heroPageController.dispose();
    super.dispose();
  }

  void _updateSubjectsCarouselIndex() {
    if (!mounted || !_subjectsScrollController.hasClients) return;

    final maxScroll = _subjectsScrollController.position.maxScrollExtent;
    final dotCount = _subjectsIndicatorCount;
    final nextIndex = maxScroll <= 0 || dotCount <= 1
        ? 0
        : (_subjectsScrollController.offset / maxScroll * (dotCount - 1))
              .round();
    final clampedIndex = nextIndex.clamp(0, dotCount - 1);
    if (clampedIndex != _subjectsCarouselIndex) {
      setState(() => _subjectsCarouselIndex = clampedIndex);
    }
  }

  int get _subjectsIndicatorCount {
    final state = context.read<LearningCubit>().state;
    final count = state is LearningLoaded
        ? state.userSubjects.length
        : state is LearningError
        ? state.fallbackSubjects.length
        : 0;
    return count.clamp(1, 4);
  }

  Future<void> _scrollToSubjectIndicator(int index, int dotCount) async {
    if (!_subjectsScrollController.hasClients || dotCount <= 1) return;
    final maxScroll = _subjectsScrollController.position.maxScrollExtent;
    final target = maxScroll * index / (dotCount - 1);
    await _subjectsScrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _onStartSubject(LearningSubject subject) async {
    if (mounted) {
      setState(() => _recentSubjectId = subject.id);
    }
    await Navigator.of(
      context,
    ).pushNamed(AppRoutes.courses, arguments: subject);
    if (!mounted) return;
    await context.read<LearningCubit>().refresh(
      _currentUser.id,
      token:
          context.read<AuthCubit>().currentUser?.accessToken ??
          _currentUser.accessToken,
    );
  }

  Future<void> _openAllSubjects() async {
    if (_isRefreshingSubjects) return;
    setState(() => _isRefreshingSubjects = true);
    try {
      await context.read<LearningCubit>().fetchSubjects(
        _currentUser.id,
        token: _currentUser.accessToken,
      );
    } catch (_) {
      // LearningCubit exposes the API error state; the Subjects tab still
      // opens so the user can see any previously loaded catalogue.
    } finally {
      if (mounted) setState(() => _isRefreshingSubjects = false);
    }
    if (!mounted) return;
    context.read<DashboardNavCubit>().goToSubjects();
  }

  Future<void> _openSubjectSelectionScreen(
    BuildContext context,
    List<LearningSubject> subjects,
  ) async {
    final learningCubit = context.read<LearningCubit>();
    final authCubit = context.read<AuthCubit>();
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            SubjectSelectionScreen(user: _currentUser, subjects: subjects),
      ),
    );
    if (!mounted) return;
    if (updated == true) {
      final savedUser = authCubit.currentUser;
      if (savedUser != null) _currentUser = savedUser;
      await learningCubit.refresh(
        _currentUser.id,
        token: _currentUser.accessToken,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, authState) {
        if (authState is Unauthenticated) {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        } else if (authState is Authenticated) {
          setState(() {
            _currentUser = authState.user;
          });
        }
      },
      child: BlocBuilder<DashboardNavCubit, int>(
        builder: (context, currentTabIndex) {
          return BlocBuilder<LearningCubit, LearningState>(
            builder: (context, learningState) {
              // Update user profile if learning state provides updated profile
              if (learningState is LearningLoaded &&
                  learningState.userProfile != null) {
                final profile = learningState.userProfile!;
                _currentUser = profile.copyWith(
                  accessToken:
                      (profile.accessToken != null &&
                          profile.accessToken!.isNotEmpty)
                      ? profile.accessToken
                      : _currentUser.accessToken,
                  refreshToken:
                      _currentUser.refreshToken ?? profile.refreshToken,
                );
              }

              return Scaffold(
                key: _scaffoldKey,
                backgroundColor: const Color(0xFFFFF0DC),
                drawer: AppDrawer(
                  user: _currentUser,
                  onProfileTap: () {
                    context.read<DashboardNavCubit>().goToProfile();
                  },
                ),
                body: Container(
                  color: const Color(0xFFFFF0DC),
                  child: SafeArea(
                    child: Stack(
                      children: [
                        Positioned(
                          top: 52,
                          right: -34,
                          child: IgnorePointer(
                            child: Opacity(
                              opacity: 0.16,
                              child: Image.asset(
                                AppAssets.bigLotus,
                                width: 190,
                                height: 190,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 320),
                          reverseDuration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeInCubic,
                          transitionBuilder: (child, animation) {
                            final slide =
                                Tween<Offset>(
                                  begin: const Offset(0.035, 0),
                                  end: Offset.zero,
                                ).animate(
                                  CurvedAnimation(
                                    parent: animation,
                                    curve: Curves.easeOutCubic,
                                  ),
                                );
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: slide,
                                child: child,
                              ),
                            );
                          },
                          child: KeyedSubtree(
                            key: ValueKey(currentTabIndex),
                            child: _buildCurrentTab(
                              currentTabIndex,
                              learningState,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                bottomNavigationBar: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF4),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.midnightNavy.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: BottomNavigationBar(
                    currentIndex: currentTabIndex,
                    onTap: (index) =>
                        context.read<DashboardNavCubit>().setTab(index),
                    backgroundColor: const Color(0xFFFFFBF4),
                    selectedItemColor: AppColors.saffronGold,
                    unselectedItemColor: const Color(0xFF64748B),
                    selectedLabelStyle: AppTypography.captionXS(
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: AppTypography.captionXS(),
                    type: BottomNavigationBarType.fixed,
                    elevation: 0,
                    items: [
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.home_outlined),
                        label: 'Home',
                      ),
                      const BottomNavigationBarItem(
                        icon: Icon(Icons.menu_book_outlined),
                        label: 'Subjects',
                      ),
                      BottomNavigationBarItem(
                        icon: _buildProfileNavigationIcon(),
                        label: 'Profile',
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCurrentTab(int tabIndex, LearningState learningState) {
    switch (tabIndex) {
      case 0:
        return _buildHomeTab(learningState);
      case 1:
        return _buildSubjectsCatalogTab(learningState);
      case 2:
        return _buildProfileTab(learningState);
      default:
        return _buildHomeTab(learningState);
    }
  }

  // ==========================================
  // TAB 0: HOME / DASHBOARD TAB (DYNAMIC & READABLE)
  // ==========================================

  Widget _buildHomeTab(LearningState learningState) {
    final List<LearningSubject> allSubjects = learningState is LearningLoaded
        ? learningState.allSubjects
        : (learningState is LearningError
              ? learningState.fallbackSubjects
              : []);
    final List<LearningSubject> userSubjects = learningState is LearningLoaded
        ? learningState.userSubjects
        : (learningState is LearningError
              ? learningState.fallbackSubjects
              : []);

    final user =
        (learningState is LearningLoaded && learningState.userProfile != null)
        ? learningState.userProfile!
        : _currentUser;

    return RefreshIndicator(
      color: AppColors.saffronGold,
      backgroundColor: const Color(0xFFFFF0DC),
      onRefresh: () => context.read<LearningCubit>().refresh(
        _currentUser.id,
        token: _currentUser.accessToken,
      ),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Mobile Header App Bar
            _buildMobileHeader(),

            if (learningState is LearningError) ...[
              const SizedBox(height: 12),
              _buildLearningErrorNotice(learningState.message),
            ],

            const SizedBox(height: 32),

            _buildExploreSubjectsHero(),

            const SizedBox(height: 24),

            // Personal subject interests appear before the curated course path.
            _buildAreasOfInterestSection(user, allSubjects),

            const SizedBox(height: 24),

            _buildFeaturedLearningHero(
              userSubjects.isNotEmpty ? userSubjects : allSubjects,
            ),

            const SizedBox(height: 24),

            _buildStudyFormatsSection(),

            const SizedBox(height: 28),

            // The subject catalogue follows the same order as the reference.
            Row(
              children: [
                Expanded(
                  child: Text(
                    'My Learning Subjects',
                    style: AppTypography.headingMD(
                      color: AppColors.midnightNavy,
                      fontWeight: FontWeight.w600,
                    ).copyWith(fontSize: 20),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(50, 30),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: _openAllSubjects,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isRefreshingSubjects)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else ...[
                        Text(
                          'View All (${allSubjects.length})',
                          style: AppTypography.buttonLabel(
                            color: const Color(0xFFD88912),
                            fontWeight: FontWeight.w700,
                          ).copyWith(fontSize: 13),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 11,
                          color: Color(0xFFD88912),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // 5. Horizontal Subjects Carousel (Unboxed Editorial Items)
            _buildSubjectsCarousel(learningState, userSubjects),

            const SizedBox(height: 32),

            // 6. API-backed learning continuation
            _buildContinueLearningSection(
              user,
              userSubjects,
              recentSubjectId: _recentSubjectId,
            ),

            const SizedBox(height: 28),

            // 7. Verified Certificates or Active Certification Track (Card matching user specification)
            _buildApiCertificatesSection(user),

            const SizedBox(height: 36),

            // Sacred Celestial Book Artwork at the bottom in dashboard
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    AppAssets.celestialBook,
                    height: 140,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'ASTROSIRI VEDIC ACADEMY',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFD97706),
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Authentic Ancient Wisdom ✦ Guidance ✦ Modern Precision',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerMenuButton() {
    return Builder(
      builder: (scaffoldCtx) => InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Scaffold.of(scaffoldCtx).openDrawer(),
        child: Container(
          width: 44,
          height: 44,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF8E9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFFFE3AF), width: 1),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE5A93C).withValues(alpha: 0.16),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Image.asset(AppAssets.drawerLotusMenu, fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildProfileNavigationIcon() {
    return const Icon(Icons.person_outline_rounded);
  }

  Widget _buildMobileHeader() {
    final firstName = _currentUser.fullName.isNotEmpty
        ? _currentUser.fullName.split(' ').first
        : 'Learner';

    return Row(
      children: [
        // Drawer Menu Button with Custom Golden Lotus Menu Icon
        _buildDrawerMenuButton(),
        const SizedBox(width: 14),

        // Welcome Greeting (Initial Removed per brand spec)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, $firstName',
                style: AppTypography.headingMD(
                  color: AppColors.midnightNavy,
                  fontWeight: FontWeight.w600,
                ).copyWith(fontSize: 21, letterSpacing: -0.3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Keep learning, keep growing',
                style: AppTypography.bodyRegular(
                  color: const Color(0xFF756E6A),
                  fontWeight: FontWeight.w400,
                ).copyWith(fontSize: 13.5),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.saffronGold.withValues(alpha: 0.45),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.midnightNavy.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: AppColors.saffronGold,
            size: 23,
          ),
        ),
      ],
    );
  }

  Widget _buildExploreSubjectsHero() {
    return SizedBox(
      height: 180,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.read<DashboardNavCubit>().goToSubjects(),
          child: Stack(
            children: [
              PageView.builder(
                controller: _heroPageController,
                itemCount: 3,
                onPageChanged: (index) {
                  if (mounted) setState(() => _heroPageIndex = index);
                },
                itemBuilder: (context, index) => _buildExploreHeroSlide(index),
              ),
              Positioned(
                bottom: 9,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) {
                    final isActive = index == _heroPageIndex;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: isActive ? 16 : 6,
                      height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFFD88912)
                            : const Color(0xFFE4DED4),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExploreHeroSlide(int index) {
    final isFirst = index == 0;
    final isSecond = index == 1;
    final assetPath = isFirst
        ? AppAssets.celestialBook
        : isSecond
        ? AppAssets.goldenBook
        : AppAssets.bigLotus;
    final label = isFirst
        ? 'YOUR LEARNING SPACE'
        : isSecond
        ? 'BUILD YOUR PRACTICE'
        : 'A MOMENT TO REFLECT';
    final title = isFirst
        ? 'Learn with clarity.'
        : isSecond
        ? 'Discover your path.'
        : 'Grow one step at a time.';
    final body = isFirst
        ? 'Choose a subject, open a lesson, and grow one step at a time.'
        : isSecond
        ? 'Explore visual lessons and useful notes at your own pace.'
        : 'Make space for learning, reflection, and steady progress.';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9ED),
        border: Border.all(color: const Color(0xFFF2E2C4)),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -20,
            child: Container(
              width: 205,
              height: 205,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEBC5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            right: -8,
            bottom: -12,
            child: Image.asset(
              assetPath,
              width: 208,
              height: 158,
              fit: BoxFit.contain,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 150, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE7B7),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    label,
                    style: AppTypography.captionXS(
                      color: const Color(0xFF9A5B13),
                      fontWeight: FontWeight.w800,
                    ).copyWith(letterSpacing: 0.5, fontSize: 9.5),
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.headingMD(
                    color: const Color(0xFF171717),
                    fontWeight: FontWeight.w700,
                  ).copyWith(fontSize: 21, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyRegular(
                    color: const Color(0xFF756E6A),
                    fontWeight: FontWeight.w400,
                  ).copyWith(fontSize: 11.5, height: 1.3),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD88912),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Explore Subjects',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 17,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedLearningHero(List<LearningSubject> subjects) {
    final featuredSubject = subjects.isNotEmpty ? subjects.first : null;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: featuredSubject == null
            ? null
            : () => _onStartSubject(featuredSubject),
        child: SizedBox(
          height: 132,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (featuredSubject != null)
                SubjectImageWidget(
                  iconUrl: featuredSubject.iconUrl,
                  imageUrl: featuredSubject.imageUrl,
                  slug: featuredSubject.slug,
                  title: featuredSubject.title,
                  width: double.infinity,
                  height: 132,
                  borderRadius: 0,
                )
              else
                Container(
                  color: const Color(0xFF17112E),
                  padding: const EdgeInsets.all(20),
                  child: Image.asset(
                    AppAssets.celestialBook,
                    fit: BoxFit.contain,
                  ),
                ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF0F172A).withValues(alpha: 0.08),
                      const Color(0xFF0F172A).withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 13,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8C15C),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Text(
                              'CURATED LESSON PATH',
                              style: AppTypography.captionXS(
                                color: const Color(0xFF2A1609),
                                fontWeight: FontWeight.w800,
                              ).copyWith(letterSpacing: 0.7, fontSize: 9.5),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            featuredSubject?.title ?? 'Begin your study path',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.headingMD(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ).copyWith(fontSize: 20, letterSpacing: -0.3),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            featuredSubject == null
                                ? 'Choose a subject and start with a guided lesson.'
                                : 'Open the course and continue with your next video lesson.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.bodyRegular(
                              color: const Color(0xFFE2E8F0),
                              fontWeight: FontWeight.w400,
                            ).copyWith(fontSize: 10.5, height: 1.25),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8C15C),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Color(0xFF2A1609),
                        size: 19,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudyFormatsSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0E2CF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D8B5E24),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildDashboardSectionIcon(Icons.auto_awesome_rounded, const [
                Color(0xFFD88912),
                Color(0xFFF4B13D),
              ]),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'A considered way to learn',
                  style: AppTypography.headingMD(
                    color: AppColors.midnightNavy,
                    fontWeight: FontWeight.w600,
                  ).copyWith(fontSize: 21),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Move between visual lessons and quiet study time at your own pace.',
            style: AppTypography.bodyRegular(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w400,
            ).copyWith(fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStudyFormatCard(
                  assetPath: AppAssets.celestialBook,
                  title: 'Video lessons',
                  subtitle: 'Explore a new perspective',
                  colors: const [Color(0xFFFFE8BE), Color(0xFFFFF5E4)],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStudyFormatCard(
                  assetPath: AppAssets.goldenBook,
                  title: 'Study notes',
                  subtitle: 'Build your practice',
                  colors: const [Color(0xFFFFEFD5), Color(0xFFFFF8EA)],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudyFormatCard({
    required String assetPath,
    required String title,
    required String subtitle,
    required List<Color> colors,
  }) {
    final isVideoCard = title.toLowerCase().contains('video');
    final isLightCard = colors.first.computeLuminance() > 0.5;
    final foregroundColor = isLightCard
        ? const Color(0xFF27211A)
        : Colors.white;
    final secondaryColor = isLightCard
        ? const Color(0xFF756E6A)
        : const Color(0xFFDDE7F4);
    final cardIcon = isVideoCard
        ? Icons.play_circle_fill_rounded
        : Icons.menu_book_rounded;

    return Container(
      height: 104,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.24),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -36,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: -10,
            right: -18,
            child: Opacity(
              opacity: isLightCard ? 0.72 : 0.94,
              child: Transform.rotate(
                angle: isVideoCard ? 0.04 : -0.05,
                child: Image.asset(assetPath, width: 104, height: 104),
              ),
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    colors.last.withValues(alpha: 0.12),
                    colors.last.withValues(alpha: 0.82),
                  ],
                  stops: const [0.0, 0.42, 1.0],
                ),
              ),
            ),
          ),
          Positioned(
            top: 13,
            left: 13,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isLightCard
                    ? Colors.white.withValues(alpha: 0.78)
                    : Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: isLightCard
                      ? Colors.white.withValues(alpha: 0.9)
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cardIcon, color: const Color(0xFFD88912), size: 14),
                  const SizedBox(width: 5),
                  Text(
                    isVideoCard ? 'WATCH' : 'READ',
                    style: AppTypography.captionXS(
                      color: const Color(0xFF8B5E24),
                      fontWeight: FontWeight.w800,
                    ).copyWith(letterSpacing: 0.9, fontSize: 9.5),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 13,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.buttonLabel(
                          color: foregroundColor,
                          fontWeight: FontWeight.w700,
                        ).copyWith(fontSize: 14.5),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.captionSM(
                          color: secondaryColor,
                          fontWeight: FontWeight.w400,
                        ).copyWith(fontSize: 10.5, height: 1.25),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueLearningSection(
    User user,
    List<LearningSubject> subjects, {
    String? recentSubjectId,
  }) {
    final selectedSubjects = subjects
        .where((subject) {
          final values = user.areasOfInterest
              .map((value) => value.toLowerCase())
              .toSet();
          return values.isEmpty ||
              values.contains(subject.id.toLowerCase()) ||
              values.contains(subject.slug.toLowerCase()) ||
              values.contains(subject.title.toLowerCase());
        })
        .take(3)
        .toList();
    final visibleSubjects = selectedSubjects.isEmpty
        ? subjects.take(3).toList()
        : selectedSubjects;

    if (recentSubjectId != null && recentSubjectId.isNotEmpty) {
      final recentIndex = visibleSubjects.indexWhere(
        (subject) => subject.id == recentSubjectId,
      );
      if (recentIndex > 0) {
        final recentSubject = visibleSubjects.removeAt(recentIndex);
        visibleSubjects.insert(0, recentSubject);
      } else if (recentIndex < 0) {
        LearningSubject? recentSubject;
        for (final subject in subjects) {
          if (subject.id == recentSubjectId) {
            recentSubject = subject;
            break;
          }
        }
        if (recentSubject != null) {
          visibleSubjects.insert(0, recentSubject);
          if (visibleSubjects.length > 3) visibleSubjects.removeLast();
        }
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.himalayanMist),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildDashboardSectionIcon(Icons.school_rounded, const [
                Color(0xFFD88912),
                Color(0xFFC1740C),
              ]),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Continue learning',
                  style: AppTypography.headingMD(
                    color: AppColors.midnightNavy,
                    fontWeight: FontWeight.w600,
                  ).copyWith(fontSize: 21),
                ),
              ),
              Text(
                '${user.completedLessons.length} completed',
                style: AppTypography.captionSM(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ).copyWith(fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Your live curriculum stays connected to each subject and its course lessons.',
            style: AppTypography.bodyRegular(
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w400,
            ).copyWith(fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 14),
          if (visibleSubjects.isEmpty)
            _buildEmptyLearningAction()
          else
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBF4),
                borderRadius: BorderRadius.circular(19),
                // border: Border.all(color: const Color(0xFFF0E1CC)),
              ),
              child: Column(
                children: visibleSubjects.asMap().entries.map((entry) {
                  final subject = entry.value;
                  final isLast = entry.key == visibleSubjects.length - 1;
                  return Column(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _onStartSubject(subject),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 11,
                            ),
                            child: Row(
                              children: [
                                AreaInterestIcon(area: subject.title, size: 46),
                                const SizedBox(width: 14),
                                SizedBox(
                                  width: 94,
                                  child: Text(
                                    subject.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.headingMD(
                                      color: const Color(0xFF171717),
                                      fontWeight: FontWeight.w500,
                                    ).copyWith(fontSize: 18),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Open courses and study the next lesson',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyRegular(
                                      color: const Color(0xFF756E6A),
                                      fontWeight: FontWeight.w400,
                                    ).copyWith(fontSize: 12.5),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: Color(0xFFD88912),
                                  size: 28,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (!isLast)
                        const Divider(
                          height: 1,
                          thickness: 1,
                          color: Color(0xFFF0E1CC),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyLearningAction() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.read<DashboardNavCubit>().goToSubjects(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A)),
        ),
        child: Row(
          children: [
            Icon(
              Icons.add_circle_outline_rounded,
              color: Color(0xFFD97706),
              size: 22,
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Browse subjects to start your learning path',
                style: TextStyle(
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_rounded,
              color: Color(0xFFD97706),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLearningErrorNotice(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF3CC83)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            color: Color(0xFFD88912),
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF92400E),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.read<LearningCubit>().refresh(
              _currentUser.id,
              token: _currentUser.accessToken,
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD88912),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAreasOfInterestSection(
    User user,
    List<LearningSubject> subjects, {
    bool showAddSubjects = true,
  }) {
    final resolvedAreas = <String>{};
    for (final a in user.areasOfInterest) {
      final matching = subjects.where(
        (s) =>
            s.id == a ||
            s.slug == a.toLowerCase() ||
            s.title.toLowerCase() == a.toLowerCase(),
      );
      if (matching.isNotEmpty) {
        resolvedAreas.add(matching.first.title);
      } else if (a.length <= 25 && !a.contains('-')) {
        resolvedAreas.add(a);
      }
    }

    final areas = resolvedAreas.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBC5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: Color(0xFFD88912),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    'PERSONAL TOPICS',
                    style: AppTypography.captionXS(
                      color: const Color(0xFFD88912),
                      fontWeight: FontWeight.w800,
                    ).copyWith(letterSpacing: 0.7, fontSize: 10),
                  ),
                ],
              ),
            ),
            if (showAddSubjects) ...[
              const Spacer(),
              TextButton.icon(
                onPressed: () => _openSubjectSelectionScreen(context, subjects),
                icon: const Icon(Icons.add_rounded, size: 22),
                label: const Text('Add Subjects'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFD88912),
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: AppTypography.buttonLabel(
                    color: const Color(0xFFD88912),
                    fontWeight: FontWeight.w700,
                  ).copyWith(fontSize: 13),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Text(
                'Areas of Interest',
                style: AppTypography.headingMD(
                  color: AppColors.midnightNavy,
                  fontWeight: FontWeight.w600,
                ).copyWith(fontSize: 20),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEBC5),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFF3CC83)),
              ),
              child: Text(
                '${areas.length} Selected',
                style: AppTypography.captionSM(
                  color: const Color(0xFFD88912),
                  fontWeight: FontWeight.w700,
                ).copyWith(fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (areas.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              showAddSubjects
                  ? 'No subjects selected yet. Use Add Subjects to personalize your learning path.'
                  : 'No subjects selected yet.',
              style: AppTypography.bodyRegular(
                color: const Color(0xFF756E6A),
                fontWeight: FontWeight.w400,
              ),
            ),
          )
        else
          SizedBox(
            height: 112,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: areas.length,
              itemBuilder: (context, index) {
                final area = areas[index];
                final isSelected = index == 0;
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        final matches = subjects.where(
                          (s) =>
                              s.title.toLowerCase().contains(
                                area.toLowerCase(),
                              ) ||
                              s.slug.toLowerCase().contains(area.toLowerCase()),
                        );
                        if (matches.isNotEmpty) _onStartSubject(matches.first);
                      },
                      child: Container(
                        width: 78,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFF0D0)
                              : const Color(0xFFFFFBF4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFF3CC83)
                                : const Color(0xFFF0E6D8),
                            width: isSelected ? 1.4 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AreaInterestIcon(area: area, size: 58),
                            const SizedBox(height: 6),
                            Text(
                              area,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.captionSM(
                                color: const Color(0xFF27211A),
                                fontWeight: FontWeight.w700,
                              ).copyWith(fontSize: 11.5, height: 1.15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSubjectsCarousel(
    LearningState state,
    List<LearningSubject> subjects,
  ) {
    if (state is LearningLoading) {
      return const SubjectCarouselShimmer();
    }
    if (subjects.isEmpty) {
      return Container(
        height: 140,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Text(
          'No learning subjects available from the API.',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }
    final dotCount = subjects.length.clamp(1, 4);
    if (_subjectsCarouselIndex >= dotCount) {
      _subjectsCarouselIndex = dotCount - 1;
    }
    return Column(
      children: [
        SizedBox(
          height: 144,
          child: ListView.builder(
            controller: _subjectsScrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              final subject = subjects[index];
              return SubjectFeaturedCard(
                subject: subject,
                onTap: () => _onStartSubject(subject),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(dotCount, (index) {
            final isActive = index == _subjectsCarouselIndex;
            return GestureDetector(
              onTap: () => _scrollToSubjectIndicator(index, dotCount),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: isActive ? 28 : 10,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFD88912)
                      : const Color(0xFFE8DDCB),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  // ==========================================
  // CERTIFICATES & CREDENTIALS SECTION (CONSULTANT CERTIFICATION)
  // ==========================================
  Widget _buildApiCertificatesSection(User user) {
    final certificates = user.certificates;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF0E1CC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 18,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildDashboardSectionIcon(
                Icons.workspace_premium_rounded,
                const [Color(0xFFD97706), Color(0xFFF59E0B)],
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'Certificates',
                  style: AppTypography.headingMD(
                    color: AppColors.midnightNavy,
                    fontWeight: FontWeight.w600,
                  ).copyWith(fontSize: 21),
                ),
              ),
              Text(
                '${certificates.length}',
                style: const TextStyle(
                  color: AppColors.saffronGold,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (certificates.isEmpty)
            Text(
              'Certificates earned from the profile API will appear here.',
              style: AppTypography.bodyRegular(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w400,
              ).copyWith(fontSize: 12.5, height: 1.4),
            )
          else
            ...certificates.map(
              (certificate) => Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    const Icon(
                      Icons.verified_rounded,
                      color: Color(0xFF059669),
                      size: 18,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        certificate,
                        style: const TextStyle(
                          color: Color(0xFF334155),
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDashboardSectionIcon(IconData icon, List<Color> colors) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(13),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 21),
    );
  }

  // ==========================================
  // TAB 1: SUBJECTS CATALOG TAB
  // ==========================================
  Widget _buildSubjectsCatalogTab(LearningState state) {
    final availableSubjects = state is LearningLoaded
        ? state.allSubjects
        : const <LearningSubject>[];
    final categories = [
      'All',
      ...availableSubjects
          .map((subject) => subject.title)
          .where((title) => title.trim().isNotEmpty)
          .toSet(),
    ];
    final selectedCategory = state is LearningLoaded
        ? state.selectedCategory
        : 'All';
    final filteredSubjects = state is LearningLoaded
        ? state.filteredSubjects
        : const <LearningSubject>[];

    return RefreshIndicator(
      color: AppColors.saffronGold,
      backgroundColor: Colors.white,
      onRefresh: () => context.read<LearningCubit>().refresh(
        _currentUser.id,
        token: _currentUser.accessToken,
      ),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildDrawerMenuButton(),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Subjects Catalog',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () =>
                      _openSubjectSelectionScreen(context, availableSubjects),
                  icon: const Icon(Icons.add_rounded, size: 17),
                  label: const Text('Add Subjects'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.saffronGold,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (state is LearningError) ...[
              const SizedBox(height: 12),
              _buildLearningErrorNotice(state.message),
            ],
            const SizedBox(height: 16),
            if (categories.length > 1)
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected =
                        selectedCategory.toLowerCase() ==
                        category.toLowerCase();
                    return InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () => context
                          .read<LearningCubit>()
                          .filterByCategory(category),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFEF3C7)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFD97706)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isSelected) ...[
                              const Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: Color(0xFFD97706),
                              ),
                              const SizedBox(width: 5),
                            ],
                            Text(
                              category,
                              style: TextStyle(
                                color: isSelected
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF475569),
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 18),
            if (state is LearningLoading)
              const SubjectListShimmer(count: 5)
            else if (filteredSubjects.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text(
                    'No subjects found in this category.',
                    style: AppTypography.bodyRegular(
                      color: AppColors.himalayanMist,
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredSubjects.length,
                itemBuilder: (context, index) {
                  final subject = filteredSubjects[index];
                  return SubjectListCard(
                    subject: subject,
                    onTap: () => _onStartSubject(subject),
                  );
                },
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 2: USER PROFILE TAB
  // ==========================================
  Widget _buildProfileTab(LearningState state) {
    final List<LearningSubject> subjects = state is LearningLoaded
        ? state.userSubjects
        : (state is LearningError ? state.fallbackSubjects : []);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildDrawerMenuButton(),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'My Vedic Profile',
                  style: AppTypography.headingMD(
                    color: AppColors.midnightNavy,
                    fontWeight: FontWeight.w600,
                  ).copyWith(fontSize: 21),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF0E1CC)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D8B5E24),
                  blurRadius: 16,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                _buildProfileAvatar(),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _currentUser.fullName.isNotEmpty
                            ? _currentUser.fullName
                            : 'Learner',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headingMD(
                          color: AppColors.midnightNavy,
                          fontWeight: FontWeight.w600,
                        ).copyWith(fontSize: 21),
                      ),
                      const SizedBox(height: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBC5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(
                          _currentUser.role.isNotEmpty
                              ? _currentUser.role
                              : 'Learner',
                          style: AppTypography.captionXS(
                            color: const Color(0xFFD88912),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Keep learning, keep growing',
                        style: AppTypography.bodyRegular(
                          color: const Color(0xFF756E6A),
                          fontWeight: FontWeight.w400,
                        ).copyWith(fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _buildProfileSurfaceCard(
            title: 'Personal details',
            icon: Icons.person_outline_rounded,
            child: Column(
              children: [
                _buildProfileDetailRow(
                  icon: Icons.phone_android_rounded,
                  label: 'Mobile',
                  val: _currentUser.mobile?.isNotEmpty == true
                      ? _currentUser.mobile!
                      : 'Not provided',
                ),
                const Divider(color: Color(0xFFF0E1CC), height: 24),
                _buildProfileDetailRow(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  val: _currentUser.email?.isNotEmpty == true
                      ? _currentUser.email!
                      : 'Not provided',
                ),
                const Divider(color: Color(0xFFF0E1CC), height: 24),
                _buildProfileDetailRow(
                  icon: Icons.work_outline_rounded,
                  label: 'Experience',
                  val: _currentUser.experience ?? 'Not provided',
                ),
                const Divider(color: Color(0xFFF0E1CC), height: 24),
                _buildProfileDetailRow(
                  icon: Icons.language_rounded,
                  label: 'Languages',
                  val: _currentUser.languages.isEmpty
                      ? 'Not provided'
                      : _currentUser.languages.join(', '),
                ),
                const Divider(color: Color(0xFFF0E1CC), height: 24),
                _buildProfileDetailRow(
                  icon: Icons.location_on_outlined,
                  label: 'Country',
                  val: _currentUser.country ?? 'Not provided',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _buildAreasOfInterestSection(
            _currentUser,
            subjects,
            showAddSubjects: false,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD88912),
                side: const BorderSide(color: Color(0xFFF3CC83), width: 1.2),
                backgroundColor: const Color(0xFFFFFBF4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () => showLogoutConfirmation(context),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: Text(
                'Log Out',
                style: AppTypography.buttonLabel(
                  color: const Color(0xFFD88912),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSurfaceCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0E1CC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildGradientIconBadge(icon, size: 34),
              const SizedBox(width: 9),
              Text(
                title,
                style: AppTypography.headingMD(
                  color: AppColors.midnightNavy,
                  fontWeight: FontWeight.w600,
                ).copyWith(fontSize: 17),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return SizedBox(
      width: 104,
      height: 112,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 100,
            height: 100,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF60A5FA), Color(0xFF1E3A8A)],
              ),
              border: Border.all(color: const Color(0xFFF3CC83), width: 3),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x333B82F6),
                  blurRadius: 16,
                  offset: Offset(0, 6),
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
                  size: 52,
                ),
              ),
            ),
          ),
          Positioned(
            right: 1,
            bottom: 5,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.saffronGold,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFFBF4), width: 3),
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.midnightNavy,
                size: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileDetailRow({
    required IconData icon,
    required String label,
    required String val,
  }) {
    return Row(
      children: [
        _buildGradientIconBadge(icon),
        const SizedBox(width: 12),
        Text(
          label,
          style: AppTypography.captionSM(color: const Color(0xFF64748B)),
        ),
        const Spacer(),
        Text(
          val,
          style: AppTypography.captionSM(
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGradientIconBadge(IconData icon, {double size = 36}) {
    final iconSize = size * 0.52;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.3),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26D97706),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}
