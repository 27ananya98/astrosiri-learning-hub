import 'package:equatable/equatable.dart';
import '../../../../domain/models/course.dart';
import '../../../../domain/models/learning_subject.dart';

abstract class CoursesState extends Equatable {
  const CoursesState();

  @override
  List<Object?> get props => [];
}

class CoursesInitial extends CoursesState {
  const CoursesInitial();
}

class CoursesLoading extends CoursesState {
  final String subjectId;
  const CoursesLoading({required this.subjectId});

  @override
  List<Object?> get props => [subjectId];
}

class CoursesLoaded extends CoursesState {
  final LearningSubject subject;
  final List<Course> courses;
  final Course? selectedCourse;

  const CoursesLoaded({
    required this.subject,
    required this.courses,
    this.selectedCourse,
  });

  CoursesLoaded copyWith({
    LearningSubject? subject,
    List<Course>? courses,
    Course? selectedCourse,
  }) {
    return CoursesLoaded(
      subject: subject ?? this.subject,
      courses: courses ?? this.courses,
      selectedCourse: selectedCourse ?? this.selectedCourse,
    );
  }

  @override
  List<Object?> get props => [subject, courses, selectedCourse];
}

class CoursesError extends CoursesState {
  final String message;
  final LearningSubject? subject;
  final List<Course> fallbackCourses;

  const CoursesError({
    required this.message,
    this.subject,
    this.fallbackCourses = const [],
  });

  @override
  List<Object?> get props => [message, subject, fallbackCourses];
}
