import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Celestial & Theme-aware Shimmer Wrapper
class AppShimmer extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;

  const AppShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: baseColor ?? const Color(0xFF131F3B),
      highlightColor: highlightColor ?? const Color(0xFF243660),
      child: child,
    );
  }
}

/// Generic Shimmer Box / Skeleton Element
class AppShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;
  final Color? color;

  const AppShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.shape = BoxShape.rectangle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? Colors.white.withValues(alpha: 0.12),
        shape: shape,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(borderRadius)
            : null,
      ),
    );
  }
}

/// Horizontal Subject Carousel Skeleton Loader
class SubjectCarouselShimmer extends StatelessWidget {
  const SubjectCarouselShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: SizedBox(
        height: 230,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, index) {
            return Container(
              width: 230,
              margin: const EdgeInsets.only(right: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppShimmerBox(
                    width: 230,
                    height: 120,
                    borderRadius: 16,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      AppShimmerBox(width: 70, height: 12, borderRadius: 4),
                      AppShimmerBox(width: 80, height: 12, borderRadius: 4),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const AppShimmerBox(width: 170, height: 18, borderRadius: 6),
                  const SizedBox(height: 6),
                  const AppShimmerBox(width: 210, height: 12, borderRadius: 4),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Vertical Subject List Skeleton Loader
class SubjectListShimmer extends StatelessWidget {
  final int count;

  const SubjectListShimmer({super.key, this.count = 4});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: count,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                const AppShimmerBox(width: 52, height: 52, borderRadius: 14),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      AppShimmerBox(width: 140, height: 16, borderRadius: 6),
                      SizedBox(height: 8),
                      AppShimmerBox(
                        width: double.infinity,
                        height: 12,
                        borderRadius: 4,
                      ),
                      SizedBox(height: 4),
                      AppShimmerBox(width: 180, height: 12, borderRadius: 4),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const AppShimmerBox(width: 16, height: 16, borderRadius: 4),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Courses List Skeleton Loader
class CoursesListShimmer extends StatelessWidget {
  final int count;

  const CoursesListShimmer({super.key, this.count = 3});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          children: List.generate(count, (index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      AppShimmerBox(width: 80, height: 14, borderRadius: 6),
                      AppShimmerBox(width: 60, height: 14, borderRadius: 6),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const AppShimmerBox(width: 220, height: 20, borderRadius: 6),
                  const SizedBox(height: 8),
                  const AppShimmerBox(
                    width: double.infinity,
                    height: 12,
                    borderRadius: 4,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: const [
                      AppShimmerBox(
                        width: 24,
                        height: 24,
                        shape: BoxShape.circle,
                      ),
                      SizedBox(width: 8),
                      AppShimmerBox(width: 90, height: 12, borderRadius: 4),
                      Spacer(),
                      AppShimmerBox(width: 80, height: 28, borderRadius: 14),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

/// Image Loading Shimmer Placeholder
class ImageShimmerPlaceholder extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const ImageShimmerPlaceholder({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: AppShimmerBox(
        width: width,
        height: height,
        borderRadius: borderRadius,
      ),
    );
  }
}
