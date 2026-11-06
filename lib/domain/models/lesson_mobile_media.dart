import 'package:equatable/equatable.dart';
import 'package:astro_siri_learning_hub/core/constants/api_constants.dart';

class LessonMobileMedia extends Equatable {
  final String? lessonId;
  final String? courseId;
  final String? videoUrl;
  final String? pdfUrl;
  final String? videoExpiresAt;
  final String? pdfExpiresAt;

  const LessonMobileMedia({
    this.lessonId,
    this.courseId,
    this.videoUrl,
    this.pdfUrl,
    this.videoExpiresAt,
    this.pdfExpiresAt,
  });

  factory LessonMobileMedia.fromJson(Map<String, dynamic> json) {
    // 1. Resolve raw data container (handles {data: {...}}, {data: [...]}, {media: {...}}, or flat json)
    final dynamic rawData =
        json['data'] ?? json['media'] ?? json['lesson'] ?? json;
    Map<String, dynamic> data = const {};
    if (rawData is Map<String, dynamic>) {
      data = rawData;
    } else if (rawData is Map) {
      data = Map<String, dynamic>.from(rawData);
    } else if (rawData is List && rawData.isNotEmpty && rawData.first is Map) {
      data = Map<String, dynamic>.from(rawData.first as Map);
    } else {
      data = json;
    }

    final lessonId =
        (data['lessonId'] ??
                data['lesson_id'] ??
                data['id'] ??
                json['lessonId'] ??
                json['id'])
            ?.toString();
    final courseId = (data['courseId'] ?? data['course_id'] ?? json['courseId'])
        ?.toString();

    // 2. Comprehensive Video URL resolution
    String? videoUrl;
    if (data['video'] is Map) {
      final vMap = data['video'] as Map;
      videoUrl =
          (vMap['url'] ??
                  vMap['videoUrl'] ??
                  vMap['video_url'] ??
                  vMap['streamUrl'] ??
                  vMap['playbackUrl'] ??
                  vMap['src'])
              ?.toString();
    } else if (data['video'] is String && data['video'].toString().isNotEmpty) {
      videoUrl = data['video'] as String;
    }

    videoUrl ??=
        (data['videoUrl'] ??
                data['video_url'] ??
                data['streamUrl'] ??
                data['stream_url'] ??
                data['playbackUrl'] ??
                data['playback_url'] ??
                data['mediaUrl'] ??
                data['media_url'] ??
                data['hlsUrl'] ??
                data['hls_url'] ??
                json['videoUrl'] ??
                json['video_url'] ??
                json['streamUrl'])
            ?.toString();

    // 3. Comprehensive PDF URL resolution
    String? pdfUrl;
    if (data['pdf'] is Map) {
      final pMap = data['pdf'] as Map;
      pdfUrl =
          (pMap['url'] ??
                  pMap['pdfUrl'] ??
                  pMap['pdf_url'] ??
                  pMap['documentUrl'] ??
                  pMap['src'])
              ?.toString();
    } else if (data['pdf'] is String && data['pdf'].toString().isNotEmpty) {
      pdfUrl = data['pdf'] as String;
    }

    pdfUrl ??=
        (data['pdfUrl'] ??
                data['pdf_url'] ??
                data['documentUrl'] ??
                data['document_url'] ??
                data['docUrl'] ??
                data['doc_url'] ??
                json['pdfUrl'] ??
                json['pdf_url'])
            ?.toString();

    // 4. Dedicated media endpoints return the signed URL as `url`
    final genericUrl = (data['url'] ?? json['url'])?.toString();
    final contentType =
        (data['contentType'] ??
                data['content_type'] ??
                data['type'] ??
                json['contentType'])
            ?.toString()
            .toLowerCase();
    final genericIsPdf =
        contentType?.contains('pdf') == true ||
        genericUrl?.toLowerCase().split('?').first.endsWith('.pdf') == true;

    if (genericUrl != null && genericUrl.isNotEmpty) {
      if (genericIsPdf) {
        pdfUrl ??= genericUrl;
      } else {
        videoUrl ??= genericUrl;
      }
    }

    // 5. Expiration metadata
    String? videoExpiresAt;
    if (data['video'] is Map) {
      videoExpiresAt =
          data['video']['expiresAt']?.toString() ??
          data['video']['expires_at']?.toString();
    }
    videoExpiresAt ??=
        (data['videoExpiresAt'] ??
                data['video_expires_at'] ??
                json['videoExpiresAt'])
            ?.toString();

    String? pdfExpiresAt;
    if (data['pdf'] is Map) {
      pdfExpiresAt =
          data['pdf']['expiresAt']?.toString() ??
          data['pdf']['expires_at']?.toString();
    }
    pdfExpiresAt ??=
        (data['pdfExpiresAt'] ?? data['pdf_expires_at'] ?? json['pdfExpiresAt'])
            ?.toString();

    if (genericIsPdf) {
      pdfExpiresAt ??= (data['expiresAt'] ?? json['expiresAt'])?.toString();
    } else {
      videoExpiresAt ??= (data['expiresAt'] ?? json['expiresAt'])?.toString();
    }

    // 6. Handle relative paths
    if (videoUrl != null && videoUrl.startsWith('/')) {
      videoUrl = ApiConstants.resolveNativeMediaUrl(videoUrl);
    }
    if (pdfUrl != null && pdfUrl.startsWith('/')) {
      pdfUrl = ApiConstants.resolveNativeMediaUrl(pdfUrl);
    }

    return LessonMobileMedia(
      lessonId: lessonId,
      courseId: courseId,
      videoUrl: videoUrl,
      pdfUrl: pdfUrl,
      videoExpiresAt: videoExpiresAt,
      pdfExpiresAt: pdfExpiresAt,
    );
  }

  @override
  List<Object?> get props => [
    lessonId,
    courseId,
    videoUrl,
    pdfUrl,
    videoExpiresAt,
    pdfExpiresAt,
  ];
}
