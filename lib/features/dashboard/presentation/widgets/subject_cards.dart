import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/learning_subject.dart';
import 'area_interest_icon.dart';
import 'subject_image_widget.dart';

/// Horizontal Featured Subject Item for Mobile Carousels (Unboxed Editorial Style)
class SubjectFeaturedCard extends StatelessWidget {
  final LearningSubject subject;
  final VoidCallback onTap;

  const SubjectFeaturedCard({
    super.key,
    required this.subject,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            height: 140,
            padding: const EdgeInsets.fromLTRB(12, 11, 10, 9),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBF4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFF0E3D2)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D8B5E24),
                  blurRadius: 14,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -6,
                  top: 5,
                  child: Opacity(
                    opacity: 0.36,
                    child: AreaInterestIcon(area: subject.title, size: 96),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.headingMD(
                        color: AppColors.midnightNavy,
                        fontWeight: FontWeight.w600,
                      ).copyWith(fontSize: 17, letterSpacing: -0.2),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 154,
                      child: Text(
                        subject.description.isNotEmpty
                            ? subject.description
                            : 'Explore the next lesson and build your practice.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyRegular(
                          color: const Color(0xFF756E6A),
                          fontWeight: FontWeight.w400,
                        ).copyWith(fontSize: 10.5, height: 1.2),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Row(
                    children: [
                      const Spacer(),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD88912),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 18,
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
    );
  }
}

/// Vertical Full-Width Subject Card for List Views (Clean White Style with Brand Spec)
class SubjectListCard extends StatelessWidget {
  final LearningSubject subject;
  final VoidCallback onTap;

  const SubjectListCard({
    super.key,
    required this.subject,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Use the API artwork directly without the old circular
                  // wrapper, so each subject keeps its own visual identity.
                  SubjectImageWidget(
                    iconUrl: subject.iconUrl,
                    imageUrl: subject.imageUrl,
                    slug: subject.slug,
                    title: subject.title,
                    width: 76,
                    height: 76,
                    borderRadius: 0,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                subject.title,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  letterSpacing: -0.2,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: subject.active
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                subject.active ? 'ACTIVE' : 'COMING SOON',
                                style: TextStyle(
                                  color: subject.active
                                      ? const Color(0xFF059669)
                                      : const Color(0xFF64748B),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subject.description.isNotEmpty
                              ? subject.description
                              : 'Explore in-depth modules and certificate track for ${subject.title}.',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12.5,
                            height: 1.35,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF94A3B8),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
        const Divider(color: Color(0xFFF1F5F9), height: 1),
      ],
    );
  }
}
