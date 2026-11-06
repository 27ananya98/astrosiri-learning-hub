import 'dart:convert';

/// Domain model representing an individual Lesson within a Course Section
class Lesson {
  final String id;
  final String courseId;
  final String sectionId;
  final String title;
  final String description;
  final String type; // e.g. TEXT, VIDEO, AUDIO
  final int durationMinutes;
  final int order;
  final String? contentUrl;
  final bool hasVideo;
  final String? videoUrl;
  final bool hasPdf;
  final String? thumbnailUrl;
  final int points;
  final bool isFreePreview;
  final bool published;
  final String status;
  final bool isAvailable;

  const Lesson({
    required this.id,
    required this.courseId,
    required this.sectionId,
    required this.title,
    this.description = '',
    this.type = 'TEXT',
    this.durationMinutes = 0,
    this.order = 0,
    this.contentUrl,
    this.hasVideo = false,
    this.videoUrl,
    this.hasPdf = false,
    this.thumbnailUrl,
    this.points = 0,
    this.isFreePreview = false,
    this.published = true,
    this.status = 'PUBLISHED',
    this.isAvailable = true,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    final rawVideo = json['video'];
    final explicitVideoUrl =
        json['videoUrl']?.toString() ??
        json['video_url']?.toString() ??
        (rawVideo is String ? rawVideo : null) ??
        (rawVideo is Map ? rawVideo['url']?.toString() : null);
    final contentUrl =
        json['contentUrl']?.toString() ?? json['content_url']?.toString();
    final contentIsPdf =
        contentUrl != null && contentUrl.toLowerCase().contains('.pdf');
    final rawVideoUrl = explicitVideoUrl ?? (contentIsPdf ? null : contentUrl);
    final type = json['type']?.toString().toUpperCase() ?? 'TEXT';
    final rawStatus = json['status']?.toString().toUpperCase();
    final rawAvailability = json['isAvailable'] ?? json['is_available'];
    final isAvailable = rawAvailability is bool
        ? rawAvailability
        : json['published'] is bool
        ? json['published'] as bool
        : rawStatus != 'COMING_SOON' && rawStatus != 'LOCKED';
    final hasVideoFlag =
        json['hasVideo'] == true ||
        json['has_video'] == true ||
        type == 'VIDEO' ||
        (rawVideoUrl != null && rawVideoUrl.trim().isNotEmpty);
    final rawPdf = json['pdf'];
    final explicitPdfUrl =
        json['pdfUrl']?.toString() ??
        json['pdf_url']?.toString() ??
        (rawPdf is String ? rawPdf : null) ??
        (rawPdf is Map ? rawPdf['url']?.toString() : null);
    final hasPdfFlag =
        json['hasPdf'] == true ||
        json['has_pdf'] == true ||
        explicitPdfUrl != null ||
        contentIsPdf;

    return Lesson(
      id: json['id']?.toString() ?? '',
      courseId:
          json['courseId']?.toString() ?? json['course_id']?.toString() ?? '',
      sectionId:
          json['sectionId']?.toString() ?? json['section_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Lesson',
      description: json['description']?.toString() ?? '',
      type: type,
      durationMinutes: _parseInt(
        json['durationMinutes'] ?? json['duration_minutes'],
      ),
      order: _parseInt(json['order']),
      contentUrl: contentUrl ?? rawVideoUrl,
      hasVideo: hasVideoFlag,
      videoUrl: rawVideoUrl,
      hasPdf: hasPdfFlag,
      thumbnailUrl:
          json['thumbnailUrl']?.toString() ?? json['thumbnail_url']?.toString(),
      points: _parseInt(json['points']),
      isFreePreview:
          json['isFreePreview'] == true || json['is_free_preview'] == true,
      published: isAvailable,
      status: rawStatus ?? (isAvailable ? 'PUBLISHED' : 'COMING_SOON'),
      isAvailable: isAvailable,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'courseId': courseId,
    'sectionId': sectionId,
    'title': title,
    'description': description,
    'type': type,
    'durationMinutes': durationMinutes,
    'order': order,
    'contentUrl': contentUrl,
    'hasVideo': hasVideo,
    'videoUrl': videoUrl,
    'hasPdf': hasPdf,
    'thumbnailUrl': thumbnailUrl,
    'points': points,
    'isFreePreview': isFreePreview,
    'published': published,
    'status': status,
    'isAvailable': isAvailable,
  };

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

/// Domain model representing a Curriculum Section containing Lessons
class CourseSection {
  final String id;
  final String courseId;
  final String title;
  final int order;
  final List<Lesson> lessons;

  const CourseSection({
    required this.id,
    required this.courseId,
    required this.title,
    this.order = 0,
    this.lessons = const [],
  });

  factory CourseSection.fromJson(Map<String, dynamic> json) {
    final rawLessons = json['Lessons'] ?? json['lessons'] ?? [];
    final lessonItems = rawLessons is List
        ? rawLessons
        : rawLessons is Map
        ? rawLessons.values.toList()
        : const <dynamic>[];
    final parsedLessons = lessonItems
        .whereType<Map>()
        .map((l) => Lesson.fromJson(Map<String, dynamic>.from(l)))
        .toList();

    // Sort lessons by order
    parsedLessons.sort((a, b) => a.order.compareTo(b.order));

    return CourseSection(
      id: json['id']?.toString() ?? '',
      courseId:
          json['courseId']?.toString() ?? json['course_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Section',
      order: Lesson._parseInt(json['order']),
      lessons: parsedLessons,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'courseId': courseId,
    'title': title,
    'order': order,
    'Lessons': lessons.map((l) => l.toJson()).toList(),
  };
}

/// Domain model representing a Course
class Course {
  final String id;
  final String subjectId;
  final String title;
  final String subtitle;
  final String description;
  final String thumbnailUrl;
  final String instructorName;
  final double rating;
  final int reviewsCount;
  final String level;
  final String durationHours;
  final int rewardPoints;
  final String badge;
  final List<String> tags;
  final List<String> whatYouWillLearn;
  final bool published;
  final int order;
  final String accessType;
  final double price;
  final double salesPrice;
  final List<CourseSection> sections;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Course({
    required this.id,
    required this.subjectId,
    required this.title,
    this.subtitle = '',
    this.description = '',
    this.thumbnailUrl = '',
    this.instructorName = '',
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.level = '',
    this.durationHours = '',
    this.rewardPoints = 0,
    this.badge = '',
    this.tags = const [],
    this.whatYouWillLearn = const [],
    this.published = true,
    this.order = 0,
    this.accessType = '',
    this.price = 0.0,
    this.salesPrice = 0.0,
    this.sections = const [],
    this.createdAt,
    this.updatedAt,
  });

  /// Total count of all lessons across all sections
  int get totalLessonsCount {
    return sections.fold<int>(0, (sum, sec) => sum + sec.lessons.length);
  }

  /// Clean plain-text description (strips HTML tags like <b>, <p>, <br>)
  String get plainDescription {
    return description
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</?p>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    // Parse tags: can be a comma-separated string or a List
    List<String> parsedTags = [];
    final rawTags = json['tags'];
    if (rawTags is List) {
      parsedTags = rawTags.map((t) => t.toString()).toList();
    } else if (rawTags is String && rawTags.isNotEmpty) {
      parsedTags = rawTags
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
    }

    // Parse whatYouWillLearn: can be JSON encoded string or List
    List<String> parsedLearn = [];
    final rawLearn = json['whatYouWillLearn'] ?? json['what_you_will_learn'];
    if (rawLearn is List) {
      parsedLearn = rawLearn.map((e) => e.toString()).toList();
    } else if (rawLearn is String && rawLearn.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawLearn);
        if (decoded is List) {
          parsedLearn = decoded.map((e) => e.toString()).toList();
        } else {
          parsedLearn = [rawLearn];
        }
      } catch (_) {
        parsedLearn = rawLearn
            .split('\n')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }

    // Parse sections
    final rawSections =
        json['Sections'] ??
        json['sections'] ??
        json['courseSections'] ??
        json['course_sections'] ??
        [];
    final sectionItems = rawSections is List
        ? rawSections
        : rawSections is Map
        ? rawSections.values.toList()
        : const <dynamic>[];
    final parsedSections = sectionItems
        .whereType<Map>()
        .map((s) => CourseSection.fromJson(Map<String, dynamic>.from(s)))
        .toList();
    parsedSections.sort((a, b) => a.order.compareTo(b.order));

    return Course(
      id: json['id']?.toString() ?? '',
      subjectId:
          json['subjectId']?.toString() ?? json['subject_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Course',
      subtitle: json['subtitle']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      thumbnailUrl:
          json['thumbnailUrl']?.toString() ??
          json['thumbnail_url']?.toString() ??
          '',
      instructorName:
          json['instructorName']?.toString() ??
          json['instructor_name']?.toString() ??
          json['instructor']?.toString() ??
          '',
      rating: _parseDouble(json['rating']),
      reviewsCount: Lesson._parseInt(
        json['reviewsCount'] ?? json['reviews_count'],
      ),
      level: json['level']?.toString().toUpperCase() ?? '',
      durationHours:
          json['durationHours']?.toString() ??
          json['duration_hours']?.toString() ??
          '',
      rewardPoints: Lesson._parseInt(
        json['rewardPoints'] ?? json['reward_points'],
      ),
      badge: json['badge']?.toString() ?? '',
      tags: parsedTags,
      whatYouWillLearn: parsedLearn,
      published: json['published'] == true || json['published'] == 1,
      order: Lesson._parseInt(json['order']),
      accessType: json['accessType']?.toString().toUpperCase() ?? '',
      price: _parseDouble(json['price'] ?? json['totalPrice']),
      salesPrice: _parseDouble(json['salesPrice'] ?? json['platformPrice']),
      sections: parsedSections,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
    );
  }

  static double _parseDouble(dynamic value, {double defaultValue = 0.0}) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
}
