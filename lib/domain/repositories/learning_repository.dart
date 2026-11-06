import '../models/course.dart';
import '../models/learning_subject.dart';
import '../models/lesson_mobile_media.dart';
import '../models/user.dart';

abstract class LearningRepository {
  Future<List<LearningSubject>> getAllSubjects({String? token});
  Future<List<LearningSubject>> getUserSubjects(String userId, {String? token});
  Future<List<LearningSubject>> getSubjects(String userId, {String? token});
  Future<User?> getProfile(String userId, {String? token});
  Future<List<Course>> getCourses(String subjectId, {String? token});
  Future<LessonMobileMedia?> getLessonMobileMedia(
    String lessonId, {
    String? token,
  });
  Future<String?> getLessonMediaUrl(
    String lessonId, {
    required bool isVideo,
    String? token,
  });
}
