import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:astro_siri_learning_hub/core/constants/api_constants.dart';
import 'package:astro_siri_learning_hub/core/constants/app_assets.dart';
import 'package:astro_siri_learning_hub/domain/models/course.dart';
import 'package:astro_siri_learning_hub/domain/models/lesson_mobile_media.dart';
import 'package:astro_siri_learning_hub/features/dashboard/presentation/widgets/lesson_video_player.dart';

void main() {
  group('LessonMobileMedia parsing & endpoints', () {
    test('parses mobile lesson media response with video and pdf objects', () {
      final json = {
        'success': true,
        'data': {
          'lessonId': 'lesson-123',
          'courseId': 'course-456',
          'videoUrl': 'https://storage.azure.com/videos/lesson1.mp4',
          'pdfUrl': 'https://storage.azure.com/docs/lesson1.pdf',
          'video': {
            'url': 'https://storage.azure.com/videos/lesson1.mp4?token=abc',
            'expiresAt': '2026-10-27T18:00:00Z',
          },
          'pdf': {
            'url': 'https://storage.azure.com/docs/lesson1.pdf?token=xyz',
            'expiresAt': '2026-10-27T18:00:00Z',
          },
        },
      };

      final media = LessonMobileMedia.fromJson(json);
      expect(media.lessonId, 'lesson-123');
      expect(media.courseId, 'course-456');
      expect(
        media.videoUrl,
        'https://storage.azure.com/videos/lesson1.mp4?token=abc',
      );
      expect(
        media.pdfUrl,
        'https://storage.azure.com/docs/lesson1.pdf?token=xyz',
      );
      expect(media.videoExpiresAt, '2026-10-27T18:00:00Z');
      expect(media.pdfExpiresAt, '2026-10-27T18:00:00Z');
    });

    test(
      'parses mobile lesson media fallback when nested objects are absent',
      () {
        final json = {
          'success': true,
          'data': {
            'lessonId': 'lesson-999',
            'courseId': 'course-888',
            'videoUrl': 'https://storage.azure.com/videos/fallback.mp4',
            'pdfUrl': 'https://storage.azure.com/docs/fallback.pdf',
          },
        };

        final media = LessonMobileMedia.fromJson(json);
        expect(media.lessonId, 'lesson-999');
        expect(media.courseId, 'course-888');
        expect(media.videoUrl, 'https://storage.azure.com/videos/fallback.mp4');
        expect(media.pdfUrl, 'https://storage.azure.com/docs/fallback.pdf');
      },
    );

    test('resolves relative URLs properly', () {
      final json = {
        'success': true,
        'data': {
          'videoUrl': '/api/v1/media/stream/123.mp4',
          'pdfUrl': '/api/v1/media/docs/123.pdf',
        },
      };

      final media = LessonMobileMedia.fromJson(json);
      expect(
        media.videoUrl,
        'https://func-astrosiri-onboarding-dev-cin-h2htbvhnhegkdabh.centralindia-01.azurewebsites.net/api/v1/media/stream/123.mp4',
      );
      expect(
        media.pdfUrl,
        'https://func-astrosiri-onboarding-dev-cin-h2htbvhnhegkdabh.centralindia-01.azurewebsites.net/api/v1/media/docs/123.pdf',
      );
    });

    test('parses dedicated PDF response without treating it as video', () {
      final media = LessonMobileMedia.fromJson({
        'success': true,
        'data': {
          'url': 'https://storage.azure.com/docs/lesson.pdf?sig=abc',
          'expiresAt': '2026-10-28T07:49:16.000Z',
          'provider': 'azure',
        },
      });

      expect(media.videoUrl, isNull);
      expect(media.pdfUrl, 'https://storage.azure.com/docs/lesson.pdf?sig=abc');
      expect(media.pdfExpiresAt, '2026-10-28T07:49:16.000Z');
    });

    test('ApiConstants constructs correct mobile lesson media URL', () {
      final url = ApiConstants.nativeLessonMediaMobile('test-id-100');
      expect(
        url,
        'https://func-astrosiri-onboarding-dev-cin-h2htbvhnhegkdabh.centralindia-01.azurewebsites.net/api/v1/media/mobile/lesson/test-id-100',
      );
    });

    test('AppAssets includes celestialBook and userAvatar', () {
      expect(AppAssets.celestialBook, 'assets/images/icons/celestial_book.png');
      expect(AppAssets.userAvatar, 'assets/images/icons/user_avatar.png');
    });

    testWidgets(
      'LessonVideoPlayer displays loader while MP4 media is loading',
      (tester) async {
        const lesson = Lesson(
          id: 'lesson-1',
          courseId: 'course-1',
          sectionId: 'section-1',
          title: 'Introduction to Vedic Houses',
          durationMinutes: 12,
          hasVideo: true,
        );

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LessonVideoPlayer(lesson: lesson, isMediaLoading: true),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading lesson video...'), findsOneWidget);
        expect(find.text('Introduction to Vedic Houses'), findsOneWidget);
      },
    );
  });
}
