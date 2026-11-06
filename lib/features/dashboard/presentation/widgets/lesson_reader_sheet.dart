import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/network_error.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../data/services/learning_service.dart';
import '../../../../domain/models/course.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import 'lesson_video_player.dart';

class LessonReaderSheet extends StatefulWidget {
  final Lesson lesson;
  final String courseTitle;
  final String? accessType;
  final LearningService? learningService;

  const LessonReaderSheet({
    super.key,
    required this.lesson,
    required this.courseTitle,
    this.accessType,
    this.learningService,
  });

  static void show(
    BuildContext context,
    Lesson lesson,
    String courseTitle, {
    String? accessType,
    LearningService? learningService,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LessonReaderSheet(
          lesson: lesson,
          courseTitle: courseTitle,
          accessType: accessType,
          learningService: learningService,
        ),
      ),
    );
  }

  @override
  State<LessonReaderSheet> createState() => _LessonReaderSheetState();
}

class _LessonReaderSheetState extends State<LessonReaderSheet> {
  late final LearningService _learningService;
  final GlobalKey<LessonVideoPlayerState> _videoPlayerKey =
      GlobalKey<LessonVideoPlayerState>();
  String? _mediaUrl;
  String? _pdfUrl;
  Duration? _videoDuration;
  bool _isMediaLoading = true;
  bool _isDescriptionExpanded = false;

  @override
  void initState() {
    super.initState();
    _learningService = widget.learningService ?? ApiLearningService();
    _fetchLessonMedia();
  }

  void _toggleDescription() {
    setState(() => _isDescriptionExpanded = !_isDescriptionExpanded);
  }

  void _handleVideoDuration(Duration duration) {
    if (!mounted || duration <= Duration.zero) return;
    if (_videoDuration != duration) {
      setState(() => _videoDuration = duration);
    }
  }

  String _lessonDurationLabel() {
    final duration = _videoDuration;
    if (duration != null && duration > Duration.zero) {
      final totalMinutes = duration.inMinutes.toString().padLeft(2, '0');
      final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
      return '$totalMinutes:$seconds';
    }
    return widget.lesson.durationMinutes > 0
        ? '${widget.lesson.durationMinutes} mins'
        : 'Duration unavailable';
  }

  Future<void> _fetchLessonMedia() async {
    try {
      // Resolve media solely through the unified native mobile lesson media API:
      // GET /api/v1/media/mobile/lesson/{lessonId}
      final token = context.read<AuthCubit>().currentUser?.accessToken;
      final mobileMedia = await _learningService
          .getLessonMobileMedia(widget.lesson.id, token: token)
          .timeout(
            const Duration(minutes: 1),
            onTimeout: () {
              debugPrint('getLessonMobileMedia timed out after 1 minute');
              return null;
            },
          );

      final videoUrl = mobileMedia?.videoUrl;
      final docUrl = mobileMedia?.pdfUrl;

      if (mounted) {
        if (_mediaUrl != videoUrl ||
            _pdfUrl != docUrl ||
            _isMediaLoading != false) {
          setState(() {
            _mediaUrl = videoUrl;
            _pdfUrl = docUrl;
            _isMediaLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching lesson media: $e');
      if (mounted) {
        if (_isMediaLoading != false) {
          setState(() {
            _isMediaLoading = false;
          });
        }
      }
    }
  }

  Future<void> _openPdfDocument() async {
    _videoPlayerKey.currentState?.pauseForExternalResource();
    var url = _pdfUrl;
    // Always request fresh media metadata when opening a PDF. Azure Blob URLs
    // are signed and short-lived, so a URL cached while the lesson screen was
    // open may already be invalid even though a newly issued browser URL works.
    try {
      final token = context.read<AuthCubit>().currentUser?.accessToken;
      final media = await _learningService.getLessonMobileMedia(
        widget.lesson.id,
        token: token,
      );
      final freshUrl = media?.pdfUrl?.trim();
      if (freshUrl != null && freshUrl.isNotEmpty) {
        url = freshUrl;
        if (mounted) {
          setState(() => _pdfUrl = freshUrl);
        }
      }
    } catch (error) {
      debugPrint('Unable to refresh PDF URL before opening: $error');
    }

    if (url == null || url.trim().isEmpty) {
      if (mounted) {
        AppToast.info(
          context,
          'PDF study material is not available for this lesson.',
          title: 'Notice',
        );
      }
      return;
    }

    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasScheme) {
      if (mounted) {
        AppToast.error(
          context,
          'The PDF link is not valid.',
          title: 'File Error',
        );
      }
      return;
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _LessonPdfViewerScreen(
          pdfUrl: uri.toString(),
          courseTitle: widget.courseTitle,
          lessonTitle: widget.lesson.title,
          accessType: widget.accessType,
        ),
      ),
    );
  }

  Future<String?> _refreshVideoUrl() async {
    final token = context.read<AuthCubit>().currentUser?.accessToken;
    final refreshedUrl = await _learningService.getLessonMediaUrl(
      widget.lesson.id,
      isVideo: true,
      token: token,
    );
    if (refreshedUrl != null && refreshedUrl.isNotEmpty && mounted) {
      if (_mediaUrl != refreshedUrl) {
        setState(() => _mediaUrl = refreshedUrl);
      }
      return refreshedUrl;
    }
    return null;
  }

  String _cleanApiContent(String value) {
    return value
        .replaceAll('\u00a0', ' ')
        .replaceAll(RegExp(r'\r\n?'), '\n')
        .replaceAll(RegExp(r'[ \t]+\n'), '\n')
        .replaceAll(RegExp(r'\n[ \t]+'), '\n')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }

  @override
  Widget build(BuildContext context) {
    final cleanDescription = _cleanApiContent(
      widget.lesson.description
          .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
          .replaceAll(RegExp(r'</?p>', caseSensitive: false), '\n\n')
          .replaceAll(RegExp(r'<[^>]*>'), ''),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F1E7),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Open editorial header with a quiet celestial watermark.
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Stack(
                children: [
                  Positioned(
                    right: -18,
                    top: -28,
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.10,
                        child: Image.asset(
                          AppAssets.bigLotus,
                          width: 130,
                          height: 130,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 38,
                          minHeight: 38,
                        ),
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppColors.midnightNavy,
                          size: 17,
                        ),
                        tooltip: 'Back',
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.courseTitle.toUpperCase(),
                              style: AppTypography.captionXS(
                                color: AppColors.saffronGold,
                                fontWeight: FontWeight.w800,
                              ).copyWith(letterSpacing: 1.1),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.lesson.title,
                              style: AppTypography.headingMD(
                                color: AppColors.midnightNavy,
                                fontWeight: FontWeight.w700,
                              ).copyWith(fontSize: 21, height: 1.18),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 9),
                            Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 3,
                                  decoration: BoxDecoration(
                                    color: AppColors.saffronGold,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'LESSON READER',
                                  style: AppTypography.captionXS(
                                    color: AppColors.textPrimary.withValues(
                                      alpha: 0.62,
                                    ),
                                    fontWeight: FontWeight.w700,
                                  ).copyWith(letterSpacing: 1.2),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Scrollable body containing Video Player + Metadata + Study Content
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. VIDEO PLAYER SECTION (Plays live stream or displays PDF / Placeholder)
                    LessonVideoPlayer(
                      key: _videoPlayerKey,
                      lesson: widget.lesson,
                      courseTitle: widget.courseTitle,
                      accessType: widget.accessType,
                      mediaUrl: _mediaUrl,
                      pdfUrl: _pdfUrl,
                      isMediaLoading: _isMediaLoading,
                      onPdfTap: _openPdfDocument,
                      onDurationChanged: _handleVideoDuration,
                      onMediaRefresh: _refreshVideoUrl,
                    ),

                    if ((_pdfUrl != null && _pdfUrl!.isNotEmpty) ||
                        widget.lesson.hasPdf) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFF9ED), Color(0xFFFFEBC5)],
                          ),
                          border: Border.all(
                            color: const Color(0xFFF3CC83),
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFD88912,
                              ).withValues(alpha: 0.12),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: _openPdfDocument,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFD88912),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.picture_as_pdf_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Study Material (PDF)',
                                          style: TextStyle(
                                            color: Color(0xFF8B5E24),
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _pdfUrl != null && _pdfUrl!.isNotEmpty
                                              ? 'Tap to open and read lesson PDF'
                                              : 'Tap to fetch & open PDF',
                                          style: TextStyle(
                                            color: const Color(
                                              0xFF8B5E24,
                                            ).withValues(alpha: 0.8),
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.open_in_new_rounded,
                                    color: Color(0xFFD88912),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // 2. Metadata Badges
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF9ED),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                color: Color(0xFFD88912),
                                size: 14,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                _lessonDurationLabel(),
                                style: const TextStyle(
                                  color: Color(0xFF171717),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0D0),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFF3CC83)),
                          ),
                          child: Text(
                            widget.lesson.hasVideo
                                ? 'VIDEO LESSON'
                                : 'STUDY CHAPTER',
                            style: TextStyle(
                              color: widget.lesson.hasVideo
                                  ? const Color(0xFFD88912)
                                  : const Color(0xFF756E6A),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),
                    const Divider(color: Color(0xFFF0E1CC), height: 1),
                    const SizedBox(height: 18),

                    // 3. Study content card.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBF4),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFF0E1CC)),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.saffronGold.withValues(
                              alpha: 0.10,
                            ),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 46,
                                height: 46,
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color: AppColors.saffronGold,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Image.asset(
                                  AppAssets.goldenBook,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Study Material & Vedic Notes',
                                      style: AppTypography.headingMD(
                                        color: AppColors.midnightNavy,
                                        fontWeight: FontWeight.w700,
                                      ).copyWith(fontSize: 17),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Read at your own pace',
                                      style: AppTypography.captionSM(
                                        color: const Color(0xFF756E6A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(height: 1, color: const Color(0xFFF0E1CC)),
                          const SizedBox(height: 14),
                          Text(
                            cleanDescription.isNotEmpty
                                ? cleanDescription
                                : 'No study material is available for this lesson.',
                            maxLines:
                                !_isDescriptionExpanded &&
                                    cleanDescription.length > 260
                                ? 5
                                : null,
                            overflow:
                                !_isDescriptionExpanded &&
                                    cleanDescription.length > 260
                                ? TextOverflow.ellipsis
                                : TextOverflow.clip,
                            style: AppTypography.bodyRegular(
                              color: const Color(0xFF756E6A),
                              fontWeight: FontWeight.w400,
                            ).copyWith(height: 1.55, fontSize: 14.5),
                          ),
                          if (cleanDescription.length > 260)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _toggleDescription,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.only(top: 8),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  foregroundColor: AppColors.loginBlue,
                                ),
                                child: Text(
                                  _isDescriptionExpanded
                                      ? 'View less'
                                      : 'View more',
                                  style: AppTypography.buttonLabel(
                                    color: AppColors.loginBlue,
                                    fontWeight: FontWeight.w700,
                                  ).copyWith(fontSize: 13),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LessonPdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String courseTitle;
  final String lessonTitle;
  final String? accessType;

  const _LessonPdfViewerScreen({
    required this.pdfUrl,
    required this.courseTitle,
    required this.lessonTitle,
    this.accessType,
  });

  @override
  State<_LessonPdfViewerScreen> createState() => _LessonPdfViewerScreenState();
}

class _LessonPdfViewerScreenState extends State<_LessonPdfViewerScreen> {
  final PdfViewerController _pdfController = PdfViewerController();
  int _currentPage = 1;
  int _pageCount = 0;
  Uint8List? _pdfBytes;
  bool _isLoading = true;
  bool _useNetworkFallback = false;
  String? _loadError;
  DateTime? _lastPageChangeAt;
  int? _lastPageNumber;
  bool _isResettingFastScroll = false;

  bool get _isFreeAccess => widget.accessType?.trim().toUpperCase() == 'FREE';

  @override
  void initState() {
    super.initState();
    _loadPdfBytes();
  }

  Future<void> _loadPdfBytes() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _loadError = null;
        _pdfBytes = null;
        _useNetworkFallback = false;
        _currentPage = 1;
        _pageCount = 0;
      });
    }

    try {
      final response = await http
          .get(
            Uri.parse(widget.pdfUrl),
            headers: const {'Accept': 'application/pdf'},
          )
          .timeout(const Duration(minutes: 1));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError('PDF server returned HTTP ${response.statusCode}.');
      }
      if (response.bodyBytes.isEmpty) {
        throw const FormatException('The PDF response was empty.');
      }

      if (!mounted) return;
      debugPrint(
        'PDF downloaded for in-app viewer: ${response.statusCode}, '
        '${response.headers['content-type']}, ${response.bodyBytes.length} bytes',
      );
      setState(() {
        _pdfBytes = Uint8List.fromList(response.bodyBytes);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = _pdfLoadErrorMessage(error);
      });
    }
  }

  String _pdfLoadErrorMessage(Object error) {
    if (NetworkErrorUtils.isNetworkFailure(error)) {
      return 'No internet connection. Check your network and try again.';
    }
    final message = error.toString().toLowerCase();
    if (message.contains('403') || message.contains('expired')) {
      return 'This PDF link has expired. Please refresh the lesson and try again.';
    }
    if (message.contains('404')) {
      return 'This PDF is no longer available on the server.';
    }
    if (message.contains('timeout') || message.contains('socket')) {
      return 'The PDF took too long to download. Check your connection and try again.';
    }
    return 'The study material could not be downloaded. Please try again.';
  }

  void _handlePdfPageChanged(int pageNumber) {
    if (!mounted) return;

    final now = DateTime.now();
    final previousTime = _lastPageChangeAt;
    final previousPage = _lastPageNumber;
    _lastPageChangeAt = now;
    _lastPageNumber = pageNumber;

    if (_isFreeAccess &&
        !_isResettingFastScroll &&
        previousTime != null &&
        previousPage != null) {
      final elapsed = now.difference(previousTime).inMilliseconds;
      final pageDelta = (pageNumber - previousPage).abs();
      final isFastScroll = elapsed < 180 || pageDelta >= 2;

      if (isFastScroll && pageNumber > 1) {
        _isResettingFastScroll = true;
        AppToast.info(
          context,
          'Fast scrolling is not available for free lessons.',
          title: 'Slow down',
        );
        Future<void>.delayed(const Duration(milliseconds: 180), () {
          if (!mounted) return;
          Navigator.of(context).pop();
        });
        return;
      }
    }

    setState(() => _currentPage = pageNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0DC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.black,
                      size: 17,
                    ),
                    tooltip: 'Back to lesson',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD88912),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26D88912),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.courseTitle.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFD88912),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.lessonTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF171717),
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_pageCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBC5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFF3CC83)),
                      ),
                      child: Text(
                        '$_currentPage / $_pageCount',
                        style: const TextStyle(
                          color: Color(0xFF8B5E24),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBF4),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFF0E1CC)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x120F172A),
                      blurRadius: 16,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: _buildPdfContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPdfContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFFD88912),
          strokeWidth: 3,
        ),
      );
    }

    final bytes = _pdfBytes;
    if (_loadError != null || bytes == null) {
      return _buildPdfErrorState();
    }

    if (_useNetworkFallback) {
      return SfPdfViewer.network(
        widget.pdfUrl,
        headers: const {
          'Accept': 'application/pdf',
          'User-Agent': 'AstroSiri-Learning-App',
        },
        controller: _pdfController,
        canShowScrollHead: true,
        canShowScrollStatus: true,
        canShowPaginationDialog: true,
        enableDoubleTapZooming: true,
        onDocumentLoaded: (details) {
          if (!mounted) return;
          setState(() {
            _pageCount = details.document.pages.count;
            _currentPage = 1;
          });
        },
        onPageChanged: (details) {
          _handlePdfPageChanged(details.newPageNumber);
        },
        onDocumentLoadFailed: (details) {
          if (!mounted) return;
          debugPrint('PDF network fallback failed: ${details.description}');
          setState(() => _loadError = details.description);
        },
      );
    }

    return SfPdfViewer.memory(
      bytes,
      controller: _pdfController,
      canShowScrollHead: true,
      canShowScrollStatus: true,
      canShowPaginationDialog: true,
      enableDoubleTapZooming: true,
      onDocumentLoaded: (details) {
        if (!mounted) return;
        setState(() {
          _pageCount = details.document.pages.count;
          _currentPage = 1;
        });
      },
      onPageChanged: (details) {
        _handlePdfPageChanged(details.newPageNumber);
      },
      onDocumentLoadFailed: (details) {
        if (!mounted) return;
        debugPrint('PDF memory viewer failed: ${details.description}');
        setState(() {
          // Try Syncfusion's URL source as a second in-app path. This still
          // stays inside the application and does not open an external app.
          _useNetworkFallback = true;
          _loadError = null;
        });
      },
    );
  }

  Widget _buildPdfErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFFFEBC5),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.picture_as_pdf_outlined,
                color: Color(0xFFD88912),
                size: 30,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Unable to open this PDF',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF171717),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              _loadError ?? 'The study material could not be loaded.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF756E6A),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                OutlinedButton.icon(
                  onPressed: _loadPdfBytes,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD88912),
                    side: const BorderSide(color: Color(0xFFF3CC83)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try again'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD88912),
                    side: const BorderSide(color: Color(0xFFF3CC83)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.black,
                    size: 18,
                  ),
                  label: const Text('Back'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
