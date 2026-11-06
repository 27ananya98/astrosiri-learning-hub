import 'dart:async';
import 'package:flutter/material.dart';

enum ToastType { info, success, error, warning }

class AppToast {
  static OverlayEntry? _activeOverlayEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context,
    String message, {
    String? title,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    Color borderColor;
    Color iconColor;
    IconData icon;

    switch (type) {
      case ToastType.success:
        borderColor = const Color(0xFF10B981);
        iconColor = const Color(0xFF10B981);
        icon = Icons.check_circle_rounded;
        break;
      case ToastType.error:
        borderColor = const Color(0xFFEF4444);
        iconColor = const Color(0xFFEF4444);
        icon = Icons.error_outline_rounded;
        break;
      case ToastType.warning:
        borderColor = const Color(0xFFF59E0B);
        iconColor = const Color(0xFFF59E0B);
        icon = Icons.warning_amber_rounded;
        break;
      case ToastType.info:
        borderColor = const Color(0xFFE5A93C);
        iconColor = const Color(0xFFE5A93C);
        icon = Icons.auto_awesome_rounded;
        break;
    }

    // Try showing via root Overlay so toast floats above modals/dialogs/sheets
    final overlay =
        Overlay.maybeOf(context, rootOverlay: true) ?? Overlay.maybeOf(context);
    if (overlay != null) {
      _dismissTimer?.cancel();
      _activeOverlayEntry?.remove();
      _activeOverlayEntry = null;

      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (ctx) {
          final topPadding = MediaQuery.of(ctx).padding.top;
          return Positioned(
            top: topPadding + 14,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: () {
                  _dismissTimer?.cancel();
                  if (_activeOverlayEntry == entry) {
                    entry.remove();
                    _activeOverlayEntry = null;
                  }
                },
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(0, -20 * (1 - value)),
                      child: Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: borderColor.withValues(alpha: 0.9),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: iconColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (title != null) ...[
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                              ],
                              Text(
                                message,
                                style: const TextStyle(
                                  color: Color(0xFFF1F5F9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
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
          );
        },
      );

      _activeOverlayEntry = entry;
      overlay.insert(entry);

      _dismissTimer = Timer(duration, () {
        if (_activeOverlayEntry == entry) {
          entry.remove();
          _activeOverlayEntry = null;
        }
      });
      return;
    }

    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger != null) {
      messenger.hideCurrentSnackBar();

      final snackBar = SnackBar(
        behavior: SnackBarBehavior.floating,
        elevation: 8,
        margin: const EdgeInsets.only(bottom: 96, left: 16, right: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: borderColor.withValues(alpha: 0.8),
            width: 1.5,
          ),
        ),
        duration: duration,
        action: action,
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.18),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                  ],
                  Text(
                    message,
                    style: const TextStyle(
                      color: Color(0xFFF1F5F9),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

      messenger.showSnackBar(snackBar);
    }
  }

  static void success(BuildContext context, String message, {String? title}) {
    show(context, message, title: title, type: ToastType.success);
  }

  static void error(BuildContext context, String message, {String? title}) {
    show(context, message, title: title, type: ToastType.error);
  }

  static void warning(BuildContext context, String message, {String? title}) {
    show(context, message, title: title, type: ToastType.warning);
  }

  static void info(BuildContext context, String message, {String? title}) {
    show(context, message, title: title, type: ToastType.info);
  }
}
