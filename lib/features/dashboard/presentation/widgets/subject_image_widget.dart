import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_shimmer.dart';

class SubjectImageWidget extends StatelessWidget {
  final String? iconUrl;
  final String? imageUrl;
  final String slug;
  final String title;
  final double width;
  final double height;
  final double borderRadius;

  const SubjectImageWidget({
    super.key,
    this.iconUrl,
    this.imageUrl,
    required this.slug,
    required this.title,
    this.width = 60,
    this.height = 60,
    this.borderRadius = 14,
  });

  @override
  Widget build(BuildContext context) {
    // Tarot and palmistry use the supplied brand artwork consistently across
    // the dashboard, catalogue, and course header instead of API-dependent
    // placeholder icons.
    final localArt = _buildLocalSubjectArt();
    if (localArt != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: localArt,
      );
    }

    final subjectKey = '${slug.toLowerCase()} ${title.toLowerCase()}';
    if (subjectKey.contains('astro') && width <= 80) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF9C3),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: EdgeInsets.all(width * 0.12),
          child: Image.asset(AppAssets.astrologySun, fit: BoxFit.contain),
        ),
      );
    }

    // APIs can return null, empty strings, or an unsupported placeholder in
    // either field. Prefer a usable image URL, then the API icon URL, and
    // finally the subject-specific local fallback below.
    final imageUri = _firstUsableUri([imageUrl, iconUrl]);

    Widget imageContent;

    if (imageUri != null && imageUri.startsWith('data:image')) {
      // Base64 encoded image (e.g. Vastu)
      try {
        final commaIdx = imageUri.indexOf(',');
        final base64Str = commaIdx != -1
            ? imageUri.substring(commaIdx + 1)
            : imageUri;
        final Uint8List bytes = base64Decode(base64Str);
        imageContent = Image.memory(
          bytes,
          width: width,
          height: height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
        );
      } catch (e) {
        imageContent = _buildFallbackIcon();
      }
    } else if (imageUri != null && imageUri.toLowerCase().startsWith('http')) {
      // Network URL (e.g. Astrology, Numerology)
      imageContent = Image.network(
        imageUri,
        width: width,
        height: height,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return ImageShimmerPlaceholder(
            width: width,
            height: height,
            borderRadius: borderRadius,
          );
        },
        errorBuilder: (context, error, stackTrace) => _buildFallbackIcon(),
      );
    } else {
      imageContent = _buildFallbackIcon();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: imageContent,
    );
  }

  Widget? _buildLocalSubjectArt() {
    final lowerSlug = slug.toLowerCase();
    final isTarot =
        lowerSlug == 'tarot' || title.toLowerCase().contains('tarot');
    final isPalmistry =
        lowerSlug == 'palmistry' || title.toLowerCase().contains('palm');
    final isVastu =
        lowerSlug == 'vastu' || title.toLowerCase().contains('vastu');
    if (!isTarot && !isPalmistry && !isVastu) return null;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isTarot
              ? const [Color(0xFF4B1D0B), Color(0xFF160904)]
              : isPalmistry
              ? const [Color(0xFFFFF2D6), Color(0xFFF7D39A)]
              : const [Color(0xFF5A2608), Color(0xFF211006)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: EdgeInsets.all(width <= 80 ? width * 0.06 : width * 0.02),
      child: Image.asset(
        isTarot
            ? AppAssets.tarotCards
            : isPalmistry
            ? AppAssets.palmistryHand
            : AppAssets.vastuIcon,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildFallbackIcon() {
    final subjectKey = '${slug.toLowerCase()} ${title.toLowerCase()}';

    if (subjectKey.contains('astro')) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: const RadialGradient(
            center: Alignment.center,
            radius: 0.85,
            colors: [Color(0xFF3B1E63), Color(0xFF1E0D38), Color(0xFF0C0519)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(width * 0.12),
            child: Image.asset(AppAssets.astrologySun, fit: BoxFit.contain),
          ),
        ),
      );
    }

    if (subjectKey.contains('numer')) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF0E1C44)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        padding: EdgeInsets.all(width * 0.1),
        child: Image.asset(AppAssets.numerologyYantra, fit: BoxFit.contain),
      );
    }

    final config = _getSlugVisualConfig(slug);
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: config.gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(config.icon, color: config.iconColor, size: width * 0.45),
      ),
    );
  }

  static String? _firstUsableUri(List<String?> candidates) {
    for (final candidate in candidates) {
      final value = candidate?.trim();
      if (value == null || value.isEmpty || value.toLowerCase() == 'null') {
        continue;
      }
      final lower = value.toLowerCase();
      if (lower.startsWith('http') || lower.startsWith('data:image')) {
        return value;
      }
    }
    return null;
  }

  static _VisualConfig _getSlugVisualConfig(String slug) {
    switch (slug.toLowerCase()) {
      case 'astrology':
        return _VisualConfig(
          icon: Icons.auto_awesome_rounded,
          gradientColors: [const Color(0xFF2A1B4E), const Color(0xFF150D2A)],
          iconColor: const Color(0xFFFFD166),
        );
      case 'vastu':
        return _VisualConfig(
          icon: Icons.explore_rounded,
          gradientColors: [const Color(0xFF0F3B36), const Color(0xFF091F1C)],
          iconColor: const Color(0xFF06D6A0),
        );
      case 'numerology':
        return _VisualConfig(
          icon: Icons.pin_outlined,
          gradientColors: [const Color(0xFF1E3A8A), const Color(0xFF0E1C44)],
          iconColor: const Color(0xFF60A5FA),
        );
      case 'tarot':
        return _VisualConfig(
          icon: Icons.style_rounded,
          gradientColors: [const Color(0xFF4B1D0B), const Color(0xFF160904)],
          iconColor: const Color(0xFFFFC44D),
        );
      case 'palmistry':
        return _VisualConfig(
          icon: Icons.pan_tool_rounded,
          gradientColors: [const Color(0xFFFFF2D6), const Color(0xFFF7D39A)],
          iconColor: const Color(0xFFD97706),
        );
      default:
        return _VisualConfig(
          icon: Icons.menu_book_rounded,
          gradientColors: [const Color(0xFF1E293B), const Color(0xFF0F172A)],
          iconColor: AppColors.saffronGold,
        );
    }
  }
}

class _VisualConfig {
  final IconData icon;
  final List<Color> gradientColors;
  final Color iconColor;

  _VisualConfig({
    required this.icon,
    required this.gradientColors,
    required this.iconColor,
  });
}
