import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_shimmer.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../core/widgets/vedic_icons.dart';
import '../../../../domain/models/course.dart';
import '../../../../domain/models/learning_subject.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/courses_cubit.dart';
import '../cubit/courses_state.dart';
import '../cubit/dashboard_nav_cubit.dart';
import '../widgets/lesson_reader_sheet.dart';
import '../widgets/subject_image_widget.dart';

class SubjectCoursesScreen extends StatefulWidget {
  final LearningSubject subject;

  const SubjectCoursesScreen({super.key, required this.subject});

  @override
  State<SubjectCoursesScreen> createState() => _SubjectCoursesScreenState();
}

class _SubjectCoursesScreenState extends State<SubjectCoursesScreen> {
  // Keeps track of which section indices are expanded
  final Set<int> _expandedSections = {0};
  final ScrollController _whatYouWillLearnController = ScrollController();
  bool _isSubjectDescriptionExpanded = false;

  static const Color _courseCardBlue = Color(0xFFFFFBF4);
  static const Color _courseCardBlueBorder = Color(0xFFF0E1CC);
  static const Color _dashboardCream = Color(0xFFFFF0DC);
  static const Color _dashboardGold = Color(0xFFD88912);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCourses();
    });
  }

  void _fetchCourses() {
    final token = context.read<AuthCubit>().currentUser?.accessToken;
    context.read<CoursesCubit>().fetchCoursesForSubject(
      widget.subject,
      token: token,
    );
  }

  Future<void> _openCourseLink(String target) async {
    final cleanedTarget = _linkTarget(target);
    final uri = Uri.tryParse(cleanedTarget);
    final scheme = uri?.scheme.toLowerCase();
    if (uri == null ||
        uri.toString().isEmpty ||
        !{'http', 'https', 'mailto', 'tel'}.contains(scheme)) {
      AppToast.error(context, 'This link is not valid.', title: 'Link Error');
      return;
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && mounted) {
        AppToast.error(
          context,
          'This link could not be opened.',
          title: 'Link Error',
        );
      }
    } catch (_) {
      if (mounted) {
        AppToast.error(
          context,
          'This link could not be opened.',
          title: 'Link Error',
        );
      }
    }
  }

  String _linkTarget(String value) {
    final cleaned = value.trim();
    // Do not include sentence punctuation in the URI passed to the browser.
    final target = cleaned.replaceFirst(RegExp(r'[),.;!?]+$'), '');
    if (target.startsWith('http://') || target.startsWith('https://')) {
      return target;
    }
    if (target.startsWith('mailto:') || target.startsWith('tel:')) {
      return target;
    }
    if (target.contains('@')) return 'mailto:$target';
    final phone = target.replaceAll(RegExp(r'[^0-9+]'), '');
    if (RegExp(r'^\+?\d{7,15}$').hasMatch(phone)) return 'tel:$phone';
    return target;
  }

  String _normalizeText(String value) => value.replaceAll(RegExp(r'\s+'), ' ');

  List<TextSpan> _buildTextSpans(String value, TextStyle style) {
    final tokenPattern = RegExp(
      r'''https?://[^\s<]+|mailto:[^\s<]+|tel:[^\s<]+|[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}|\+?\d[\d\s().-]{7,}\d''',
      caseSensitive: false,
    );
    final spans = <TextSpan>[];
    var cursor = 0;

    for (final match in tokenPattern.allMatches(value)) {
      if (match.start > cursor) {
        spans.add(
          TextSpan(text: value.substring(cursor, match.start), style: style),
        );
      }
      final token = match.group(0)!;
      final target = _linkTarget(token);
      spans.add(
        TextSpan(
          text: token,
          style: style.copyWith(
            color: const Color(0xFF2563EB),
            decoration: TextDecoration.underline,
          ),
          recognizer: target.isEmpty
              ? null
              : (TapGestureRecognizer()..onTap = () => _openCourseLink(target)),
        ),
      );
      cursor = match.end;
    }
    if (cursor < value.length) {
      spans.add(TextSpan(text: value.substring(cursor), style: style));
    }
    return spans.isEmpty ? [TextSpan(text: value, style: style)] : spans;
  }

  List<TextSpan> _buildInlineSpans(
    Iterable<html_dom.Node> nodes,
    TextStyle baseStyle, {
    bool autoLinkText = true,
  }) {
    final spans = <TextSpan>[];

    void visit(
      html_dom.Node node,
      TextStyle style, {
      String? activeLinkTarget,
    }) {
      if (node is html_dom.Text) {
        final text = _normalizeText(node.data);
        if (text.isNotEmpty) {
          if (activeLinkTarget != null) {
            spans.add(
              TextSpan(
                text: text,
                style: style,
                recognizer: TapGestureRecognizer()
                  ..onTap = () => _openCourseLink(activeLinkTarget),
              ),
            );
          } else {
            spans.addAll(
              autoLinkText
                  ? _buildTextSpans(text, style)
                  : [TextSpan(text: text, style: style)],
            );
          }
        }
        return;
      }

      if (node is! html_dom.Element) return;

      final tag = (node.localName ?? '').toLowerCase();
      if (tag == 'br') {
        spans.add(TextSpan(text: '\n', style: style));
        return;
      }

      final nextStyle = switch (tag) {
        'b' || 'strong' => style.copyWith(fontWeight: FontWeight.w700),
        'u' => style.copyWith(decoration: TextDecoration.underline),
        'i' || 'em' => style.copyWith(fontStyle: FontStyle.italic),
        _ => style,
      };

      if (tag == 'a') {
        final href = node.attributes['href']?.trim() ?? '';
        final linkTarget = href.isEmpty ? '' : _linkTarget(href);
        final linkStyle = nextStyle.copyWith(
          color: const Color(0xFF2563EB),
          decoration: TextDecoration.underline,
        );
        // Attach the recognizer to the actual rendered text leaves. This
        // keeps nested <b>/<u>/<li> formatting while making the visible link
        // reliably tappable on Android and iOS.
        for (final child in node.nodes) {
          visit(
            child,
            linkStyle,
            activeLinkTarget: linkTarget.isEmpty ? null : linkTarget,
          );
        }
        return;
      }

      for (final child in node.nodes) {
        visit(child, nextStyle, activeLinkTarget: activeLinkTarget);
      }
    }

    for (final node in nodes) {
      visit(node, baseStyle);
    }
    return spans;
  }

  Widget _buildCourseOverviewDescription(Course course) {
    final html = course.description.trim();
    if (html.isEmpty) {
      return const Text(
        'Course description unavailable.',
        style: TextStyle(color: Color(0xFF334155), fontSize: 13.5, height: 1.5),
      );
    }

    final fragment = html_parser.parseFragment(html);
    final blocks = <Widget>[];

    void addInlineNodes(
      Iterable<html_dom.Node> nodes, {
      TextStyle baseStyle = const TextStyle(
        color: Color(0xFF334155),
        fontSize: 13.5,
        height: 1.5,
      ),
      double spacing = 10,
    }) {
      final spans = _buildInlineSpans(nodes, baseStyle);
      if (spans.any(
        (span) =>
            span.text?.trim().isNotEmpty == true ||
            span.children?.isNotEmpty == true,
      )) {
        blocks.add(Text.rich(TextSpan(style: baseStyle, children: spans)));
        blocks.add(SizedBox(height: spacing));
      }
    }

    void addList(html_dom.Element list) {
      final ordered = list.localName?.toLowerCase() == 'ol';
      final items = list.children
          .where((element) => element.localName?.toLowerCase() == 'li')
          .toList();
      if (items.isEmpty) return;

      blocks.add(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < items.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 7),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 22,
                      child: Text(
                        ordered ? '${index + 1}.' : '•',
                        style: const TextStyle(
                          color: Color(0xFFD88912),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            color: Color(0xFF334155),
                            fontSize: 13.5,
                            height: 1.5,
                          ),
                          children: _buildInlineSpans(
                            items[index].nodes,
                            const TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 13.5,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
      blocks.add(const SizedBox(height: 10));
    }

    for (final node in fragment.nodes) {
      if (node is html_dom.Text) {
        if (_normalizeText(node.data).trim().isNotEmpty) {
          addInlineNodes([node]);
        }
        continue;
      }
      if (node is! html_dom.Element) continue;

      final tag = (node.localName ?? '').toLowerCase();
      if (tag == 'ul' || tag == 'ol') {
        addList(node);
        continue;
      }

      final heading = RegExp(r'^h[1-6]$').hasMatch(tag);
      if (heading || tag == 'p' || tag == 'div' || tag == 'section') {
        final level = heading ? int.parse(tag.substring(1)) : 0;
        addInlineNodes(
          node.nodes,
          baseStyle: TextStyle(
            color: heading ? AppColors.midnightNavy : const Color(0xFF334155),
            fontSize: heading ? (23 - level * 1.5) : 13.5,
            height: heading ? 1.25 : 1.5,
            fontWeight: heading ? FontWeight.w700 : FontWeight.w400,
          ),
          spacing: heading ? 12 : 10,
        );
        continue;
      }

      addInlineNodes([node]);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  @override
  void dispose() {
    _whatYouWillLearnController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _dashboardCream,
      body: SafeArea(
        bottom: false,
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
            Column(
              children: [
                _buildTopAppBar(context),
                const Divider(color: _courseCardBlueBorder, height: 1),
                Expanded(
                  child: BlocBuilder<CoursesCubit, CoursesState>(
                    builder: (context, state) {
                      if (state is CoursesLoading) {
                        return _buildLoadingState();
                      } else if (state is CoursesError &&
                          state.fallbackCourses.isEmpty) {
                        return _buildErrorState(state.message);
                      } else if (state is CoursesLoaded) {
                        return _buildLoadedContent(state.courses);
                      }
                      return _buildLoadingState();
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: _courseCardBlue,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: const Border(
            top: BorderSide(color: _courseCardBlueBorder, width: 1),
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x140F172A),
              blurRadius: 16,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: 1,
          onTap: (index) {
            context.read<DashboardNavCubit>().setTab(index);
            Navigator.of(context).pop();
          },
          backgroundColor: _courseCardBlue,
          selectedItemColor: _dashboardGold,
          unselectedItemColor: const Color(0xFF64748B),
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 11,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_stories_rounded),
              label: 'Subjects',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: _dashboardCream,
      child: Row(
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.black,
              size: 17,
            ),
            tooltip: 'Back',
            onPressed: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.subject.title,
                  style: AppTypography.headingMD(
                    color: AppColors.midnightNavy,
                    fontWeight: FontWeight.w600,
                  ).copyWith(fontSize: 18),
                ),
                Text(
                  'Vedic Curriculum & Courses',
                  style: AppTypography.captionXS(
                    color: AppColors.saffronGold,
                    fontWeight: FontWeight.w800,
                  ).copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFFD97706),
                size: 20,
              ),
              onPressed: () {
                _fetchCourses();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: CoursesListShimmer(count: 3),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Color(0xFFEF4444),
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Unable to load courses',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.saffronGold,
                foregroundColor: AppColors.midnightNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                _fetchCourses();
              },
              child: Text(
                'Try Again',
                style: AppTypography.buttonLabel(
                  color: AppColors.midnightNavy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadedContent(List<Course> courses) {
    if (courses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.school_outlined,
              color: AppColors.saffronGold,
              size: 54,
            ),
            const SizedBox(height: 16),
            Text(
              'No courses available yet for ${widget.subject.title}',
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'New curriculum modules are currently being prepared.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      children: [
        // Subject Hero Overview
        _buildSubjectHeroBanner(),
        const SizedBox(height: 20),

        // Courses Listing
        for (var index = 0; index < courses.length; index++) ...[
          if (index > 0) _buildCourseDivider(),
          _buildCourseView(courses[index]),
        ],
      ],
    );
  }

  Widget _buildCourseDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFD88912), height: 1)),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 10),
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFEBC5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'NEXT COURSE',
              style: TextStyle(
                color: Color(0xFF9A5B13),
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFFD88912), height: 1)),
        ],
      ),
    );
  }

  Widget _buildSubjectHeroBanner() {
    final subjectDescription = widget.subject.description.trim().isNotEmpty
        ? widget.subject.description.trim()
        : 'Subject description unavailable.';
    final canExpandSubjectDescription =
        subjectDescription.length > 120 || subjectDescription.contains('\n');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _courseCardBlue,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _courseCardBlueBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              SubjectImageWidget(
                iconUrl: widget.subject.iconUrl,
                imageUrl: widget.subject.imageUrl,
                slug: widget.subject.slug,
                title: widget.subject.title,
                width: 58,
                height: 58,
                borderRadius: 14,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.subject.eligibilityThreshold}% Passmark',
                      style: const TextStyle(
                        color: Color(0xFF059669),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (_isSubjectDescriptionExpanded)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subjectDescription,
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 12.5,
                            ),
                          ),
                          if (canExpandSubjectDescription)
                            _buildSubjectDescriptionAction('View less'),
                        ],
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final style = const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                          );
                          if (!canExpandSubjectDescription) {
                            return Text(subjectDescription, style: style);
                          }

                          final preview = _subjectDescriptionPreview(
                            subjectDescription,
                            constraints.maxWidth,
                            style,
                          );
                          return Text.rich(
                            TextSpan(
                              style: style,
                              children: [
                                TextSpan(text: preview),
                                TextSpan(
                                  text: ' View more',
                                  style: const TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () {
                                      setState(() {
                                        _isSubjectDescriptionExpanded = true;
                                      });
                                    },
                                ),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.clip,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectDescriptionAction(String label) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isSubjectDescriptionExpanded = false;
        });
      },
      child: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFF2563EB),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _subjectDescriptionPreview(
    String description,
    double maxWidth,
    TextStyle style,
  ) {
    if (!maxWidth.isFinite || maxWidth <= 0) {
      return description.substring(0, description.length.clamp(0, 100));
    }

    bool fits(String value) {
      final painter = TextPainter(
        text: TextSpan(text: '$value View more', style: style),
        textDirection: TextDirection.ltr,
        maxLines: 2,
      )..layout(maxWidth: maxWidth);
      return !painter.didExceedMaxLines;
    }

    var low = 0;
    var high = description.length;
    while (low < high) {
      final middle = (low + high + 1) ~/ 2;
      if (fits(description.substring(0, middle).trimRight())) {
        low = middle;
      } else {
        high = middle - 1;
      }
    }

    var preview = description.substring(0, low).trimRight();
    final lastSpace = preview.lastIndexOf(' ');
    if (lastSpace > 20) preview = preview.substring(0, lastSpace).trimRight();
    return preview;
  }

  Widget _buildCourseView(Course course) {
    final availableLessons = course.sections
        .expand((section) => section.lessons)
        .where((lesson) => lesson.isAvailable)
        .toList();
    final firstAvailableLesson = availableLessons.isEmpty
        ? null
        : availableLessons.first;
    final metricPills = <Widget>[
      if (course.rating > 0)
        _buildMetricPill(
          icon: Icons.star_rounded,
          label: '${course.rating.toStringAsFixed(1)} Rating',
          iconColor: _dashboardGold,
          bgColor: const Color(0xFFFFEBC5),
          textColor: const Color(0xFF8B5E24),
        ),
      if (course.durationHours.trim().isNotEmpty)
        _buildMetricPill(
          icon: Icons.schedule_rounded,
          label: course.durationHours.trim(),
          iconColor: _dashboardGold,
          bgColor: const Color(0xFFFFF3DE),
          textColor: const Color(0xFF8B5E24),
        ),
      if (course.level.trim().isNotEmpty)
        _buildMetricPill(
          icon: Icons.signal_cellular_alt_rounded,
          label: course.level.trim(),
          iconColor: _dashboardGold,
          bgColor: const Color(0xFFFFF0D0),
          textColor: const Color(0xFF8B5E24),
        ),
      if (course.accessType.trim().isNotEmpty)
        _buildMetricPill(
          icon: Icons.verified_rounded,
          label: course.accessType.trim(),
          iconColor: _dashboardGold,
          bgColor: const Color(0xFFFFF3DE),
          textColor: const Color(0xFF8B5E24),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Course Title & Subtitle (Black & Crisp for Visibility)
        Text(
          course.title,
          style: AppTypography.headingMD(
            color: AppColors.midnightNavy,
            fontWeight: FontWeight.w600,
          ).copyWith(fontSize: 20, height: 1.25),
        ),
        if (course.subtitle.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            course.subtitle,
            style: const TextStyle(
              color: Color(0xFFD97706),
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
            ),
          ),
        ],

        if (metricPills.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: metricPills),
          const SizedBox(height: 12),
        ],

        // Instructor Row
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _courseCardBlue,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _courseCardBlueBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x06000000),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFFBEB),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  color: Color(0xFFD97706),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          course.instructorName.isNotEmpty
                              ? course.instructorName
                              : 'Instructor unavailable',
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.verified,
                          color: Color(0xFF059669),
                          size: 15,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    if (course.badge.isNotEmpty)
                      Text(
                        course.badge,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11.5,
                        ),
                      ),
                  ],
                ),
              ),
              if (course.badge.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Text(
                    course.badge,
                    style: const TextStyle(
                      color: Color(0xFFD97706),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Description / Overview
        Text(
          'Course Overview',
          style: AppTypography.headingMD(
            color: AppColors.midnightNavy,
            fontWeight: FontWeight.w600,
          ).copyWith(fontSize: 17),
        ),
        const SizedBox(height: 6),
        _buildCourseOverviewDescription(course),

        const SizedBox(height: 14),

        // Vedic Astrological Chart & Sacred Scripture Book Artwork (Matching Screen 1)
        const VedicCourseBookBanner(height: 115),

        const SizedBox(height: 22),

        // What You Will Learn Section
        if (course.whatYouWillLearn.isNotEmpty) ...[
          Text(
            'What You Will Learn',
            style: AppTypography.headingMD(
              color: AppColors.midnightNavy,
              fontWeight: FontWeight.w600,
            ).copyWith(fontSize: 18),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _courseCardBlue,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _courseCardBlueBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 230),
              child: Scrollbar(
                controller: _whatYouWillLearnController,
                thumbVisibility: true,
                interactive: true,
                child: ListView.separated(
                  controller: _whatYouWillLearnController,
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(right: 10),
                  itemCount: course.whatYouWillLearn.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = course.whatYouWillLearn[index];
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF059669),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            item,
                            style: const TextStyle(
                              color: Color(0xFF334155),
                              fontSize: 13.5,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Curriculum Sections & Lessons
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Course Curriculum',
              style: AppTypography.headingMD(
                color: AppColors.midnightNavy,
                fontWeight: FontWeight.w600,
              ).copyWith(fontSize: 18),
            ),
            Text(
              '${course.sections.length} Sections · ${course.totalLessonsCount} Lessons',
              style: const TextStyle(
                color: Color(0xFFD97706),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Sections Accordion
        ...course.sections.asMap().entries.map((entry) {
          final index = entry.key;
          final section = entry.value;
          final isExpanded = _expandedSections.contains(index);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: _courseCardBlue,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _courseCardBlueBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Section Header (Clickable)
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    setState(() {
                      if (isExpanded) {
                        _expandedSections.remove(index);
                      } else {
                        _expandedSections.add(index);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFED7AA)),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Color(0xFFD97706),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                section.title,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${section.lessons.length} Lessons',
                                style: const TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          isExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF0F172A),
                        ),
                      ],
                    ),
                  ),
                ),

                // Expanded Lessons List
                if (isExpanded) ...[
                  const Divider(color: Color(0xFFF1F5F9), height: 1),
                  ...section.lessons.map((lesson) {
                    final hasVideo = lesson.hasVideo;

                    return InkWell(
                      onTap: lesson.isAvailable
                          ? () => LessonReaderSheet.show(
                              context,
                              lesson,
                              course.title,
                              accessType: course.accessType,
                            )
                          : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Color(0xFFF1F5F9),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: !lesson.isAvailable
                                    ? const Color(0xFFF1F5F9)
                                    : hasVideo
                                    ? const Color(0xFFF0F9FF)
                                    : const Color(0xFFFFFBEB),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                !lesson.isAvailable
                                    ? Icons.lock_outline_rounded
                                    : hasVideo
                                    ? Icons.play_arrow_rounded
                                    : Icons.menu_book_rounded,
                                color: !lesson.isAvailable
                                    ? const Color(0xFF94A3B8)
                                    : hasVideo
                                    ? const Color(0xFF0284C7)
                                    : const Color(0xFFD97706),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    lesson.title,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Row(
                                    children: [
                                      Text(
                                        lesson.durationMinutes > 0
                                            ? '${lesson.durationMinutes} mins'
                                            : 'Duration unavailable',
                                        style: const TextStyle(
                                          color: Color(0xFF64748B),
                                          fontSize: 11.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        !lesson.isAvailable
                                            ? '• Coming soon'
                                            : hasVideo
                                            ? '• Video lesson'
                                            : '• ${lesson.type}',
                                        style: TextStyle(
                                          color: !lesson.isAvailable
                                              ? const Color(0xFF94A3B8)
                                              : hasVideo
                                              ? const Color(0xFF0284C7)
                                              : const Color(0xFF64748B),
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: !lesson.isAvailable
                                    ? const Color(0xFFF1F5F9)
                                    : hasVideo
                                    ? const Color(0xFFF0F9FF)
                                    : const Color(0xFFFFFBEB),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: !lesson.isAvailable
                                      ? const Color(0xFFE2E8F0)
                                      : hasVideo
                                      ? const Color(0xFFBAE6FD)
                                      : const Color(0xFFFED7AA),
                                ),
                              ),
                              child: Text(
                                !lesson.isAvailable
                                    ? 'Coming soon'
                                    : hasVideo
                                    ? 'Watch'
                                    : 'Read',
                                style: TextStyle(
                                  color: !lesson.isAvailable
                                      ? const Color(0xFF64748B)
                                      : hasVideo
                                      ? const Color(0xFF0284C7)
                                      : const Color(0xFFD97706),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ],
            ),
          );
        }),

        const SizedBox(height: 20),

        // Bottom CTA Button
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.saffronGold,
              foregroundColor: AppColors.midnightNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              elevation: 2,
            ),
            onPressed: firstAvailableLesson == null
                ? null
                : () => LessonReaderSheet.show(
                    context,
                    firstAvailableLesson,
                    course.title,
                    accessType: course.accessType,
                  ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_circle_fill_rounded,
                  size: 22,
                  color: AppColors.midnightNavy,
                ),
                const SizedBox(width: 8),
                Text(
                  'Start Learning Now',
                  style: AppTypography.buttonLabel(
                    color: AppColors.midnightNavy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }

  Widget _buildMetricPill({
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTypography.captionXS(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
