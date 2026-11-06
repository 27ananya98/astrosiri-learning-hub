import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/network_error.dart';
import '../../../../domain/models/course.dart';
import '../../../../domain/models/learning_subject.dart';
import '../../../../domain/repositories/learning_repository.dart';
import 'courses_state.dart';

class CoursesCubit extends Cubit<CoursesState> {
  final LearningRepository learningRepository;

  CoursesCubit({required this.learningRepository})
    : super(const CoursesInitial());

  /// Fetches courses for the given [subject] using its [subject.id]
  Future<void> fetchCoursesForSubject(
    LearningSubject subject, {
    String? token,
  }) async {
    emit(CoursesLoading(subjectId: subject.id));
    try {
      final courses = await learningRepository.getCourses(
        subject.id,
        token: token,
      );
      emit(
        CoursesLoaded(
          subject: subject,
          courses: courses,
          selectedCourse: courses.isNotEmpty ? courses.first : null,
        ),
      );
    } catch (e) {
      final message = NetworkErrorUtils.isNetworkFailure(e)
          ? NetworkErrorUtils.message(e)
          : 'Courses are not available right now. Please try again.';
      emit(CoursesError(message: message, subject: subject));
    }
  }

  /// Select a specific course to inspect or study
  void selectCourse(Course course) {
    if (state is CoursesLoaded) {
      emit((state as CoursesLoaded).copyWith(selectedCourse: course));
    }
  }
}
