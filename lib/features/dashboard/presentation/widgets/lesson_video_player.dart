import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../domain/models/course.dart';
import '../screens/full_screen_video_player_screen.dart';

/// Interactive Lesson Video Player Widget.
/// - Connects to live video URL via official [video_player] package.
/// - Detects video streams vs PDF documents.
/// - Synchronizes playback controls: Play/Pause, scrubber, seek ±10s, and speed.
class LessonVideoPlayer extends StatefulWidget {
  final Lesson lesson;
  final String? courseTitle;
  final String? accessType;
  final String? mediaUrl;
  final String? pdfUrl;
  final bool isMediaLoading;
  final VoidCallback? onPdfTap;
  final ValueChanged<Duration>? onDurationChanged;
  final Future<String?> Function()? onMediaRefresh;

  const LessonVideoPlayer({
    super.key,
    required this.lesson,
    this.courseTitle,
    this.accessType,
    this.mediaUrl,
    this.pdfUrl,
    this.isMediaLoading = false,
    this.onPdfTap,
    this.onDurationChanged,
    this.onMediaRefresh,
  });

  @override
  State<LessonVideoPlayer> createState() => LessonVideoPlayerState();
}

class LessonVideoPlayerState extends State<LessonVideoPlayer> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _isInitializingVideo = false;
  bool _hasError = false;
  String _errorMessage = '';
  // Show controls when paused or on initial load
  bool _showControls = true;
  double _speed = 1.0;
  Timer? _controlsTimer;
  String? _currentLoadedUrl;
  bool _userWantsPlaying = true;
  bool _hasStartedPlayback = false;
  bool _resumeRequestInFlight = false;
  bool _mediaRefreshInFlight = false;
  bool _manualRetryInFlight = false;
  int _autoRefreshAttempts = 0;
  Timer? _uiUpdateTimer;

  bool get _isFreeAccess => widget.accessType?.trim().toUpperCase() == 'FREE';

  @override
  void initState() {
    super.initState();
    _checkAndInitVideo();
  }

  @override
  void didUpdateWidget(covariant LessonVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isFreeAccess && oldWidget.accessType != widget.accessType) {
      _speed = 1.0;
      _controller?.setPlaybackSpeed(1.0);
    }
    final targetUrl = _resolvedUrl;
    final lessonChanged = oldWidget.lesson.id != widget.lesson.id;
    if (lessonChanged) {
      _autoRefreshAttempts = 0;
    }
    final urlChanged =
        targetUrl != null &&
        targetUrl.isNotEmpty &&
        targetUrl != _currentLoadedUrl;
    final needsInitialInit =
        targetUrl != null &&
        targetUrl.isNotEmpty &&
        _controller == null &&
        !_isInitializingVideo &&
        !_hasError;

    // Only re-init if the lesson changed or the actual media URL changed to a new target.
    // If widget.isMediaLoading changed but the resolved URL is already loaded/playing,
    // NEVER dispose the active controller so playback remains completely uninterrupted.
    if (lessonChanged || urlChanged || needsInitialInit) {
      _checkAndInitVideo();
    }
  }

  String? get _resolvedUrl {
    final explicit = widget.mediaUrl?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final fallback = widget.lesson.videoUrl?.trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return null;
  }

  String? get _youtubeVideoId {
    final rawUrl = _resolvedUrl;
    if (rawUrl == null || rawUrl.isEmpty) return null;

    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    if (!host.contains('youtube.com') &&
        !host.contains('youtube-nocookie.com') &&
        !host.contains('youtu.be')) {
      return null;
    }

    if (host.contains('youtu.be')) {
      return uri.pathSegments.isNotEmpty ? uri.pathSegments.first : null;
    }

    final queryId = uri.queryParameters['v'];
    if (queryId != null && queryId.isNotEmpty) return queryId;

    final segments = uri.pathSegments;
    for (final marker in const ['embed', 'shorts', 'live']) {
      final index = segments.indexOf(marker);
      if (index >= 0 && index + 1 < segments.length) {
        return segments[index + 1];
      }
    }
    return null;
  }

  bool get _isYouTubeVideo => _youtubeVideoId != null;

  bool get _isPlayableVideo {
    final url = _resolvedUrl;
    if (url == null || url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    final path = uri?.path.toLowerCase() ?? url.toLowerCase();
    if (path.endsWith('.pdf')) return false;
    return true;
  }

  Future<void> _checkAndInitVideo() async {
    final url = _resolvedUrl;
    if (_isYouTubeVideo) {
      _controller?.removeListener(_videoListener);
      await _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      _hasError = false;
      _isInitializingVideo = false;
      _currentLoadedUrl = url;
      if (mounted) setState(() {});
      return;
    }

    if (url == null || url.isEmpty || !_isPlayableVideo) {
      _controller?.removeListener(_videoListener);
      await _controller?.dispose();
      _controller = null;
      _isInitialized = false;
      _hasError = false;
      _isInitializingVideo = false;
      _currentLoadedUrl = null;
      if (mounted) setState(() {});
      return;
    }

    // Guard against redundant reinitialization if this exact URL is already loaded
    if (_controller != null && _isInitialized && _currentLoadedUrl == url) {
      return;
    }

    _controller?.removeListener(_videoListener);
    await _controller?.dispose();
    _controller = null;
    _isInitialized = false;
    _hasError = false;
    _isInitializingVideo = true;
    _currentLoadedUrl = url;
    _hasStartedPlayback = false;
    if (mounted) setState(() {});

    try {
      // Direct native streaming with proper URI encoding and error cleanup.
      final cleanUrl = url.trim();
      final uri = Uri.tryParse(cleanUrl) ?? Uri.parse(Uri.encodeFull(cleanUrl));

      final controller = VideoPlayerController.networkUrl(
        uri,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      try {
        await controller.initialize().timeout(
          const Duration(minutes: 1),
          onTimeout: () {
            throw TimeoutException(
              'Video stream timed out. The file may be too large to stream immediately, or network is slow.',
            );
          },
        );
      } catch (initError) {
        await controller.dispose();
        rethrow;
      }

      if (!mounted) {
        controller.dispose();
        return;
      }

      controller.addListener(_videoListener);

      setState(() {
        _controller = controller;
        _isInitialized = true;
        _isInitializingVideo = false;
        _userWantsPlaying = true;
        _showControls = true;
      });
      widget.onDurationChanged?.call(controller.value.duration);

      // Autoplay video on initialization
      try {
        await controller.play();
        _autoHideControls();
      } catch (error) {
        debugPrint('Video auto-play warning: $error');
      }
    } catch (e) {
      debugPrint('Video initialization warning: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _isInitializingVideo = false;
          _errorMessage = _parseVideoError(e);
        });
        if (_autoRefreshAttempts < 1 && _isTokenOrAuthError(e)) {
          _autoRefreshAttempts++;
          _refreshMediaAfterError();
        }
      }
    }
  }

  void _videoListener() {
    if (!mounted || _controller == null) return;

    // Detect runtime errors during streaming (e.g. network drops)
    if (_controller!.value.hasError) {
      debugPrint(
        'Video player runtime error: ${_controller!.value.errorDescription}',
      );
      if (!_hasError) {
        setState(() {
          _hasError = true;
          _errorMessage =
              _controller!.value.errorDescription ?? 'Playback error occurred';
        });
        _refreshMediaAfterError();
      }
      return;
    }

    // Auto-detect when video reaches the end
    if (_controller!.value.duration > Duration.zero &&
        _controller!.value.position >= _controller!.value.duration) {
      _userWantsPlaying = false;
      _showControls = true;
    }

    // Android's video backend can briefly report isBuffering while continuing
    // playback. Once the first video position has advanced, do not replace the
    // video with a full-screen loader for those transient buffer-state changes.
    if (_controller!.value.position > Duration.zero) {
      _hasStartedPlayback = true;
    }

    // Auto-resume playback if the controller pauses during a transient network
    // refill. Do not rely on isBuffering becoming false first: on some Android
    // devices it can remain true while the player is ready to resume.
    if (_userWantsPlaying &&
        !_controller!.value.isPlaying &&
        _controller!.value.position < _controller!.value.duration) {
      _resumePlaybackIfNeeded();
    }

    _scheduleVideoUiUpdate();
  }

  void _scheduleVideoUiUpdate() {
    if (!mounted || _uiUpdateTimer?.isActive == true) return;
    _uiUpdateTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) setState(() {});
    });
  }

  String _parseVideoError(Object error) {
    final raw = error.toString();
    final lower = raw.toLowerCase();

    if (lower.contains('403') ||
        lower.contains('authenticationfailed') ||
        lower.contains('unauthorized')) {
      return 'Video access token expired or rejected. Tap Retry to refresh.';
    }
    if (lower.contains('404') || lower.contains('not found')) {
      return 'Video stream was not found on the server.';
    }
    if (lower.contains('mediacodec') ||
        lower.contains('unrecognizedinputformat') ||
        lower.contains('-12842') ||
        lower.contains('unsupported format')) {
      return 'Video format is not supported on this device. H.264 MP4 is required.';
    }
    if (lower.contains('httpdatasource') ||
        lower.contains('ioexception') ||
        lower.contains('socket') ||
        lower.contains('connection')) {
      return 'Network connection issue while buffering video. Please retry.';
    }
    return 'Playback error occurred. Tap Retry to reload.';
  }

  bool _isTokenOrAuthError(Object error) {
    final lower = error.toString().toLowerCase();
    return lower.contains('403') ||
        lower.contains('authenticationfailed') ||
        lower.contains('unauthorized') ||
        lower.contains('token expired');
  }

  Future<void> _refreshMediaAfterError() async {
    if (_mediaRefreshInFlight || widget.onMediaRefresh == null) return;
    _mediaRefreshInFlight = true;
    try {
      final refreshedUrl = await widget.onMediaRefresh!.call();
      if (refreshedUrl != null &&
          refreshedUrl.isNotEmpty &&
          refreshedUrl != _currentLoadedUrl &&
          mounted) {
        setState(() {
          _hasError = false;
          _errorMessage = '';
        });
        _checkAndInitVideo();
      }
    } catch (error) {
      debugPrint('Video media refresh warning: $error');
    } finally {
      _mediaRefreshInFlight = false;
    }
  }

  Future<void> _handleManualRetry() async {
    if (_manualRetryInFlight) return;
    _manualRetryInFlight = true;
    _autoRefreshAttempts = 0;
    if (mounted) {
      setState(() {
        _hasError = false;
        _errorMessage = '';
        _isInitializingVideo = true;
      });
    }
    try {
      if (widget.onMediaRefresh != null) {
        try {
          final newUrl = await widget.onMediaRefresh!.call();
          if (newUrl != null && newUrl.isNotEmpty) {
            _currentLoadedUrl = null;
          }
        } catch (_) {}
      }
      await _checkAndInitVideo();
    } finally {
      _manualRetryInFlight = false;
      if (mounted && !_isInitializingVideo) {
        setState(() {});
      }
    }
  }

  Future<void> _handleUnavailableRetry() async {
    if (_manualRetryInFlight || widget.onMediaRefresh == null) return;
    _manualRetryInFlight = true;
    if (mounted) setState(() {});
    try {
      await widget.onMediaRefresh!.call();
    } finally {
      _manualRetryInFlight = false;
      if (mounted) setState(() {});
    }
  }

  Future<void> _resumePlaybackIfNeeded() async {
    final controller = _controller;
    if (_resumeRequestInFlight ||
        !_userWantsPlaying ||
        controller == null ||
        !controller.value.isInitialized ||
        controller.value.isPlaying ||
        controller.value.position >= controller.value.duration) {
      return;
    }

    _resumeRequestInFlight = true;
    try {
      await controller.play();
      // A manual pause may happen while play() is completing. Respect it.
      if (!_userWantsPlaying && controller.value.isPlaying) {
        await controller.pause();
      }
    } catch (error) {
      debugPrint('Video auto-resume warning: $error');
    } finally {
      _resumeRequestInFlight = false;
    }
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _uiUpdateTimer?.cancel();
    _controller?.removeListener(_videoListener);
    _controller?.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    if (_controller == null || !_isInitialized) return;
    setState(() {
      if (_controller!.value.isPlaying) {
        _userWantsPlaying = false;
        _controller!.pause();
      } else {
        // If playback finished, replay from beginning
        if (_controller!.value.duration > Duration.zero &&
            _controller!.value.position >= _controller!.value.duration) {
          _controller!.seekTo(Duration.zero);
        }
        _userWantsPlaying = true;
        _controller!.play();
        _autoHideControls();
      }
    });
  }

  /// Pauses playback before another lesson resource, such as a PDF, opens.
  /// The user's paused state is preserved when they return to this lesson.
  void pauseForExternalResource() {
    final controller = _controller;
    if (controller == null || !_isInitialized || !controller.value.isPlaying) {
      return;
    }

    _userWantsPlaying = false;
    controller.pause();
    if (mounted) {
      setState(() => _showControls = true);
    }
  }

  void _seekBy(int deltaSeconds) {
    if (_controller == null || !_isInitialized) return;
    final current = _controller!.value.position;
    final target = current + Duration(seconds: deltaSeconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > _controller!.value.duration
              ? _controller!.value.duration
              : target);
    _controller!.seekTo(clamped);
    _autoHideControls();
  }

  void _cycleSpeed() {
    if (_isFreeAccess || _controller == null || !_isInitialized) return;
    setState(() {
      if (_speed == 1.0) {
        _speed = 1.25;
      } else if (_speed == 1.25) {
        _speed = 1.5;
      } else if (_speed == 1.5) {
        _speed = 2.0;
      } else {
        _speed = 1.0;
      }
      _controller!.setPlaybackSpeed(_speed);
    });
    _autoHideControls();
  }

  void _showSpeedRestriction() {
    if (!_isFreeAccess || !mounted) return;
    AppToast.info(
      context,
      'Fast forward not allowed on this account.',
      title: 'Playback restricted',
    );
  }

  Future<void> _openYouTubeVideo() async {
    final rawUrl = _resolvedUrl;
    final uri = rawUrl == null ? null : Uri.tryParse(rawUrl);
    if (uri == null) return;

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      AppToast.error(
        context,
        'Unable to open this YouTube video.',
        title: 'Video unavailable',
      );
    }
  }

  Widget _buildYouTubePlaceholder() {
    return Container(
      color: const Color(0xFF0F172A),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.smart_display_rounded,
            color: Color(0xFFFF0000),
            size: 42,
          ),
          const SizedBox(height: 8),
          const Text(
            'YouTube lesson',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _openYouTubeVideo,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF0000),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Open in YouTube'),
          ),
        ],
      ),
    );
  }

  Future<void> _openFullScreen(BuildContext context) async {
    if (_controller == null || !_isInitialized) return;
    _controlsTimer?.cancel();

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenVideoPlayerScreen(
          controller: _controller!,
          lesson: widget.lesson,
          courseTitle: widget.courseTitle,
          initialSpeed: _speed,
          allowSpeedChange: !_isFreeAccess,
          onSpeedChanged: (newSpeed) {
            setState(() {
              _speed = newSpeed;
            });
          },
        ),
      ),
    );

    if (mounted) {
      setState(() {});
      _autoHideControls();
    }
  }

  void _autoHideControls() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && _controller?.value.isPlaying == true) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    final int m = duration.inMinutes;
    final int s = duration.inSeconds % 60;
    final String minutes = m < 10 ? '0$m' : '$m';
    final String secs = s < 10 ? '0$s' : '$s';
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isMediaLoading &&
        !_isInitializingVideo &&
        _isYouTubeVideo &&
        _youtubeVideoId != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: _buildYouTubePlaceholder(),
        ),
      );
    }

    if (!widget.isMediaLoading &&
        !_isInitializingVideo &&
        !_isPlayableVideo &&
        !_hasError) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: _buildUnavailablePlaceholder(compact: true),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_hasError) {
      return _buildErrorPlaceholder();
    }

    if (widget.isMediaLoading || _isInitializingVideo) {
      return _buildLoadingState();
    }

    if (_isPlayableVideo && _isInitialized && _controller != null) {
      return _buildActiveVideoPlayer();
    }

    return _buildUnavailablePlaceholder();
  }

  Widget _buildLoadingState() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.lesson.thumbnailUrl != null &&
              widget.lesson.thumbnailUrl!.isNotEmpty)
            Positioned.fill(
              child: Opacity(
                opacity: 0.20,
                child: Image.network(
                  widget.lesson.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5A93C).withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFE5A93C),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Loading lesson video...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    widget.lesson.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveVideoPlayer() {
    final controller = _controller!;
    final isPlaying = controller.value.isPlaying;
    final position = controller.value.position;
    final duration = controller.value.duration;
    final showControls = _showControls || !isPlaying;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
        if (_showControls) _autoHideControls();
      },
      onDoubleTap: () => _openFullScreen(context),
      child: Container(
        color: Colors.black,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Real Hardware-Accelerated Video Surface
            Center(
              child: AspectRatio(
                aspectRatio: controller.value.aspectRatio > 0
                    ? controller.value.aspectRatio
                    : (16 / 9),
                child: VideoPlayer(controller),
              ),
            ),

            // Buffering loader while MP4 data is loading/buffering
            if (controller.value.isBuffering && !_hasStartedPlayback)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    shape: BoxShape.circle,
                  ),
                  child: const SizedBox(
                    width: 32,
                    height: 32,
                    child: CircularProgressIndicator(
                      strokeWidth: 3.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFE5A93C),
                      ),
                    ),
                  ),
                ),
              ),

            // Dim overlay when controls are visible or video is paused
            if (showControls)
              Positioned.fill(
                child: Container(
                  color: isPlaying
                      ? Colors.black.withValues(alpha: 0.45)
                      : Colors.black.withValues(alpha: 0.35),
                ),
              ),

            // Top Bar: Lesson Title + Fullscreen Shortcut
            if (showControls)
              Positioned(
                top: 10,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white24,
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            widget.lesson.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),

            // Center Controls: -10s, Play/Pause, +10s
            if (showControls)
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.replay_10_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => _seekBy(-10),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE5A93C),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFE5A93C,
                              ).withValues(alpha: 0.5),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: const Color(0xFF0B132B),
                          size: 36,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(
                        Icons.forward_10_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => _seekBy(10),
                    ),
                  ],
                ),
              ),

            // Bottom Bar: Progress Scrubber, Duration, Speed
            if (showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.85),
                      ],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Video progress scrubber
                      VideoProgressIndicator(
                        controller,
                        allowScrubbing: true,
                        colors: const VideoProgressColors(
                          playedColor: Color(0xFFE5A93C),
                          bufferedColor: Colors.white38,
                          backgroundColor: Colors.white24,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      const SizedBox(height: 2),

                      // Time + Speed + Fullscreen row
                      Row(
                        children: [
                          Text(
                            '${_formatDuration(position)} / ${_formatDuration(duration)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),

                          // Speed button
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _isFreeAccess
                                ? _showSpeedRestriction
                                : _cycleSpeed,
                            child: Text(
                              '${_speed}x',
                              style: const TextStyle(
                                color: Color(0xFFE5A93C),
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Full Screen button
                          IconButton(
                            style: IconButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 2,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(
                              Icons.fullscreen_rounded,
                              color: Color(0xFFE5A93C),
                              size: 22,
                            ),
                            tooltip: 'Full Screen',
                            onPressed: () => _openFullScreen(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.amber,
                size: 32,
              ),
              const SizedBox(height: 8),
              const Text(
                'Video Playback Notice',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _errorMessage.isNotEmpty
                    ? _errorMessage
                    : 'Unable to stream video at this time.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _manualRetryInFlight ? null : _handleManualRetry,
                icon: _manualRetryInFlight
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFE5A93C),
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        size: 16,
                        color: Color(0xFFE5A93C),
                      ),
                label: const Text(
                  'Retry Loading Video',
                  style: TextStyle(
                    color: Color(0xFFE5A93C),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUnavailablePlaceholder({bool compact = false}) {
    if (compact) {
      return Container(
        height: 76,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        color: const Color(0xFF0F172A),
        child: Row(
          children: [
            const Icon(
              Icons.videocam_off_rounded,
              color: Color(0xFFE5A93C),
              size: 22,
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Video not available for this lesson.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (widget.onMediaRefresh != null)
              IconButton(
                tooltip: 'Retry Loading Video',
                onPressed: _manualRetryInFlight
                    ? null
                    : _handleUnavailableRetry,
                icon: _manualRetryInFlight
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFE5A93C),
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        color: Color(0xFFE5A93C),
                      ),
              ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.5),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.lesson.thumbnailUrl != null &&
              widget.lesson.thumbnailUrl!.isNotEmpty)
            Positioned.fill(
              child: Opacity(
                opacity: 0.22,
                child: Image.network(
                  widget.lesson.thumbnailUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE5A93C).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      widget.lesson.hasVideo
                          ? Icons.refresh_rounded
                          : Icons.videocam_off_rounded,
                      color: const Color(0xFFE5A93C),
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5A93C).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFFE5A93C).withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    widget.lesson.hasVideo
                        ? 'STREAM NOT LOADED'
                        : 'VIDEO NOT AVAILABLE',
                    style: const TextStyle(
                      color: Color(0xFFE5A93C),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.lesson.hasVideo
                      ? 'Could not connect to video stream. Tap retry to reload.'
                      : 'Video lecture is currently being prepared by Acharyas.\nComplete study material is available below.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
                if (widget.lesson.hasVideo &&
                    widget.onMediaRefresh != null) ...[
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE5A93C),
                      foregroundColor: const Color(0xFF0B132B),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: _manualRetryInFlight
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF0B132B),
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, size: 16),
                    label: Text(
                      _manualRetryInFlight
                          ? 'Retrying...'
                          : 'Retry Loading Video',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    onPressed: _manualRetryInFlight
                        ? null
                        : _handleUnavailableRetry,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
