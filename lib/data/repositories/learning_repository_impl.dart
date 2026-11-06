import '../../domain/models/course.dart';
import '../../domain/models/learning_subject.dart';
import '../../domain/models/lesson_mobile_media.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/learning_repository.dart';
import '../services/learning_service.dart';

class LearningRepositoryImpl implements LearningRepository {
  final LearningService _learningService;

  LearningRepositoryImpl({LearningService? learningService})
    : _learningService = learningService ?? ApiLearningService();

  @override
  Future<List<LearningSubject>> getAllSubjects({String? token}) {
    return _learningService.getAllLearningSubjects(token: token);
  }

  @override
  Future<List<LearningSubject>> getUserSubjects(
    String userId, {
    String? token,
  }) {
    return _learningService.getUserLearningSubjects(userId, token: token);
  }

  @override
  Future<List<LearningSubject>> getSubjects(String userId, {String? token}) {
    return getUserSubjects(userId, token: token);
  }

  @override
  Future<User?> getProfile(String userId, {String? token}) {
    return _learningService.getUserProfile(userId, token: token);
  }

  @override
  Future<List<Course>> getCourses(String subjectId, {String? token}) {
    return _learningService.getCoursesBySubject(subjectId, token: token);
  }

  @override
  Future<LessonMobileMedia?> getLessonMobileMedia(
    String lessonId, {
    String? token,
  }) {
    return _learningService.getLessonMobileMedia(lessonId, token: token);
  }

  @override
  Future<String?> getLessonMediaUrl(
    String lessonId, {
    required bool isVideo,
    String? token,
  }) {
    return _learningService.getLessonMediaUrl(
      lessonId,
      isVideo: isVideo,
      token: token,
    );
  }
}
