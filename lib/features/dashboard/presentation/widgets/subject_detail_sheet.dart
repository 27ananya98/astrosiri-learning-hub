import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../domain/models/learning_subject.dart';
import 'subject_image_widget.dart';

class SubjectDetailSheet extends StatelessWidget {
  final LearningSubject subject;
  final VoidCallback onStartLearning;

  const SubjectDetailSheet({
    super.key,
    required this.subject,
    required this.onStartLearning,
  });

  static void show(
    BuildContext context,
    LearningSubject subject,
    VoidCallback onStartLearning,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SubjectDetailSheet(
          subject: subject,
          onStartLearning: onStartLearning,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topics = _getSubjectTopics(subject.slug);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF0C142A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: Color(0xFF233560), width: 1.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              SubjectImageWidget(
                iconUrl: subject.iconUrl,
                imageUrl: subject.imageUrl,
                slug: subject.slug,
                title: subject.title,
                width: 64,
                height: 64,
                borderRadius: 16,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.title,
                      style: AppTypography.headingMD(
                        color: AppColors.pureWhite,
                      ).copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.saffronGold.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Module ${subject.order}',
                            style: AppTypography.captionXS(
                              color: AppColors.saffronGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${subject.eligibilityThreshold}% Passmark',
                          style: AppTypography.captionXS(
                            color: const Color(0xFF2ECC71),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Description
          Text(
            subject.description.isNotEmpty
                ? subject.description
                : 'Comprehensive authentic curriculum designed by top Vedic Acharyas. Includes Kundli analysis, energy alignment, and live mentorship.',
            style: AppTypography.bodyRegular(
              color: AppColors.himalayanMist.withValues(alpha: 0.9),
            ),
          ),

          const SizedBox(height: 20),

          // Syllabus Highlights
          Text(
            'Curriculum Highlights',
            style: AppTypography.bodyRegular(
              color: AppColors.pureWhite,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...topics.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.saffronGold,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t,
                      style: AppTypography.captionSM(
                        color: AppColors.himalayanMist,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.saffronGold,
                foregroundColor: AppColors.midnightNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              onPressed: () {
                Navigator.pop(context);
                onStartLearning();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_circle_fill_rounded, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'Start Learning ${subject.title}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  static List<String> _getSubjectTopics(String slug) {
    switch (slug.toLowerCase()) {
      case 'astrology':
        return [
          'Vedic Kundli Foundations & 12 Bhavas (Houses)',
          '9 Navagraha Planetary Influences & Dasha Cycles',
          'Rashi Analysis & Transit Predictions (Gochara)',
          'Kundli Milan & Marriage Compatibility',
        ];
      case 'vastu':
        return [
          'The 16 Vastu Zones & Elemental Alignments',
          'Panchtattva Balance (Earth, Water, Fire, Air, Space)',
          'Remedies Without Demolition (Pyramids, Colors, Crystals)',
          'Commercial & Industrial Spatial Geometry',
        ];
      case 'numerology':
        return [
          'Chaldean & Pythagorean Number Systems',
          'Life Path, Destiny & Soul Urge Numbers',
          'Name Spelling Correction & Brand Vibrations',
          'Personal Year & Universal Cycle Forecasts',
        ];
      case 'tarot':
        return [
          '78 Cards: 22 Major Arcana & 56 Minor Arcana',
          'Symbolism, Archetypes & Celestial Correspondence',
          'Celtic Cross & Intuitive Card Spreads',
          'Client Consultation Ethics & Accuracy',
        ];
      case 'palmistry':
        return [
          'Major Hand Lines (Life, Heart, Head, Fate)',
          'The 7 Planetary Mounts & Energy Channels',
          'Special Signs: Stars, Crosses, Triangles & Fish',
          'Health, Wealth & Career Timeline Prediction',
        ];
      default:
        return [
          'Foundational Principles & Vedic Literature',
          'Practical lesson walkthroughs and examples',
          'Video and PDF study materials',
        ];
    }
  }
}
