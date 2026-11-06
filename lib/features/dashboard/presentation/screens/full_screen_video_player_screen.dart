import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../../domain/models/course.dart';

/// Immersive Full-Screen Video Player Screen.
/// Keeps the app in portrait, enables edge-to-edge immersive UI,
/// and provides complete synchronized controls (-10s, play/pause, +10s, scrubber, speed, exit).
class FullScreenVideoPlayerScreen extends StatefulWidget {
  final VideoPlayerController controller;
  final Lesson lesson;
  final String? courseTitle;
  final double initialSpeed;
  final bool allowSpeedChange;
  final ValueChanged<double>? onSpeedChanged;

  const FullScreenVideoPlayerScreen({
    super.key,
    required this.controller,
    required this.lesson,
    this.courseTitle,
    this.initialSpeed = 1.0,
    this.allowSpeedChange = true,
    this.onSpeedChanged,
  });

  @override
  State<FullScreenVideoPlayerScreen> createState() =>
      _FullScreenVideoPlayerScreenState();
}

class _FullScreenVideoPlayerScreenState
    extends State<FullScreenVideoPlayerScreen> {
  late double _speed;
  bool _showControls = false;
  bool _userWantsPlaying = false;
  bool _resumeRequestInFlight = false;
  Timer? _controlsTimer;
  Timer? _uiUpdateTimer;

  @override
  void initState() {
    super.initState();
    _speed = widget.initialSpeed;
    _userWantsPlaying = widget.controller.value.isPlaying;

    // The application is portrait-only, including the full-screen player.
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // 2. Hide system status bar & navigation bar for immersive view
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    widget.controller.addListener(_controllerListener);
    _autoHideControls();
  }

  void _controllerListener() {
    if (!mounted) return;
    if (_userWantsPlaying &&
        !widget.controller.value.isPlaying &&
        widget.controller.value.position < widget.controller.value.duration) {
      _resumePlaybackIfNeeded();
    }
    // Auto-detect when video reaches the end
    if (widget.controller.value.duration > Duration.zero &&
        widget.controller.value.position >= widget.controller.value.duration) {
      _userWantsPlaying = false;
      _showControls = true;
    }
    if (_uiUpdateTimer?.isActive == true) return;
    _uiUpdateTimer = Timer(const Duration(milliseconds: 100), () {
      if (mounted) setState(() {});
    });
  }

  Future<void> _resumePlaybackIfNeeded() async {
    if (_resumeRequestInFlight ||
        !_userWantsPlaying ||
        widget.controller.value.isPlaying ||
        widget.controller.value.position >= widget.controller.value.duration) {
      return;
    }
    _resumeRequestInFlight = true;
    try {
      await widget.controller.play();
      if (!_userWantsPlaying && widget.controller.value.isPlaying) {
        await widget.controller.pause();
      }
    } catch (_) {}
    _resumeRequestInFlight = false;
  }

  void _restoreOrientation() {
    // Restore portrait orientation and standard edge-to-edge UI
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _uiUpdateTimer?.cancel();
    widget.controller.removeListener(_controllerListener);
    _restoreOrientation();
    super.dispose();
  }

  void _autoHideControls() {
    _controlsTimer?.cancel();
    _controlsTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && widget.controller.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  void _togglePlayPause() {
    setState(() {
      if (widget.controller.value.isPlaying) {
        _userWantsPlaying = false;
        widget.controller.pause();
      } else {
        if (widget.controller.value.duration > Duration.zero &&
            widget.controller.value.position >=
                widget.controller.value.duration) {
          widget.controller.seekTo(Duration.zero);
        }
        _userWantsPlaying = true;
        widget.controller.play();
        _autoHideControls();
      }
    });
  }

  void _seekBy(int deltaSeconds) {
    final current = widget.controller.value.position;
    final target = current + Duration(seconds: deltaSeconds);
    final clamped = target < Duration.zero
        ? Duration.zero
        : (target > widget.controller.value.duration
              ? widget.controller.value.duration
              : target);
    widget.controller.seekTo(clamped);
    _autoHideControls();
  }

  void _cycleSpeed() {
    if (!widget.allowSpeedChange) return;
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
      widget.controller.setPlaybackSpeed(_speed);
      widget.onSpeedChanged?.call(_speed);
    });
    _autoHideControls();
  }

  void _showSpeedRestriction() {
    if (widget.allowSpeedChange || !mounted) return;
    AppToast.info(
      context,
      'Fast forward not allowed on this account.',
      title: 'Playback restricted',
    );
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
    final controller = widget.controller;
    final isPlaying = controller.value.isPlaying;
    final position = controller.value.position;
    final duration = controller.value.duration;
    final showControls = _showControls || !isPlaying;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        _restoreOrientation();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: GestureDetector(
          onTap: () {
            setState(() {
              _showControls = !_showControls;
            });
            if (_showControls) _autoHideControls();
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Edge-to-Edge Centered Video Surface
              Center(
                child: AspectRatio(
                  aspectRatio: controller.value.aspectRatio > 0
                      ? controller.value.aspectRatio
                      : 16 / 9,
                  child: VideoPlayer(controller),
                ),
              ),

              // Buffering loader indicator
              if (controller.value.isBuffering)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      shape: BoxShape.circle,
                    ),
                    child: const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(
                        strokeWidth: 3.2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFFE5A93C),
                        ),
                      ),
                    ),
                  ),
                ),

              // Dark overlay when controls are visible or paused
              if (showControls)
                Positioned.fill(
                  child: Container(color: Colors.black.withValues(alpha: 0.45)),
                ),

              // Top Bar: Back Button, Titles & Fullscreen Exit
              if (showControls)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.85),
                            Colors.transparent,
                          ],
                        ),
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
                            tooltip: 'Exit Full Screen',
                            onPressed: () {
                              _restoreOrientation();
                              Navigator.pop(context);
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.courseTitle != null &&
                                    widget.courseTitle!.isNotEmpty)
                                  Text(
                                    widget.courseTitle!.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFFE5A93C),
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                Text(
                                  widget.lesson.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.fullscreen_exit_rounded,
                              color: Color(0xFFE5A93C),
                              size: 28,
                            ),
                            tooltip: 'Exit Full Screen',
                            onPressed: () {
                              _restoreOrientation();
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                    ),
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
                          size: 38,
                        ),
                        onPressed: () => _seekBy(-10),
                      ),
                      const SizedBox(width: 32),
                      GestureDetector(
                        onTap: _togglePlayPause,
                        child: Container(
                          width: 68,
                          height: 68,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFE5A93C),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFE5A93C,
                                ).withValues(alpha: 0.55),
                                blurRadius: 22,
                                spreadRadius: 3,
                              ),
                            ],
                          ),
                          child: Icon(
                            isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: const Color(0xFF0B132B),
                            size: 44,
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      IconButton(
                        icon: const Icon(
                          Icons.forward_10_rounded,
                          color: Colors.white,
                          size: 38,
                        ),
                        onPressed: () => _seekBy(10),
                      ),
                    ],
                  ),
                ),

              // Bottom Bar: Progress Scrubber, Duration, Speed & Exit Fullscreen
              if (showControls)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.9),
                          ],
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VideoProgressIndicator(
                            controller,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: Color(0xFFE5A93C),
                              bufferedColor: Colors.white38,
                              backgroundColor: Colors.white24,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                '${_formatDuration(position)} / ${_formatDuration(duration)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: widget.allowSpeedChange
                                    ? _cycleSpeed
                                    : _showSpeedRestriction,
                                child: Text(
                                  '${_speed}x',
                                  style: const TextStyle(
                                    color: Color(0xFFE5A93C),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
