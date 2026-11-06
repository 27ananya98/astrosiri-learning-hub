import 'package:equatable/equatable.dart';
import '../../../../domain/models/learning_subject.dart';
import '../../../../domain/models/user.dart';

abstract class LearningState extends Equatable {
  const LearningState();

  @override
  List<Object?> get props => [];
}

class LearningInitial extends LearningState {
  const LearningInitial();
}

class LearningLoading extends LearningState {
  const LearningLoading();
}

class LearningLoaded extends LearningState {
  final List<LearningSubject> allSubjects;
  final List<LearningSubject> userSubjects;
  final List<LearningSubject> filteredSubjects;
  final String selectedCategory;
  final User? userProfile;

  const LearningLoaded({
    required this.allSubjects,
    required this.userSubjects,
    required this.filteredSubjects,
    this.selectedCategory = 'All',
    this.userProfile,
  });

  LearningLoaded copyWith({
    List<LearningSubject>? allSubjects,
    List<LearningSubject>? userSubjects,
    List<LearningSubject>? filteredSubjects,
    String? selectedCategory,
    User? userProfile,
  }) {
    return LearningLoaded(
      allSubjects: allSubjects ?? this.allSubjects,
      userSubjects: userSubjects ?? this.userSubjects,
      filteredSubjects: filteredSubjects ?? this.filteredSubjects,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      userProfile: userProfile ?? this.userProfile,
    );
  }

  @override
  List<Object?> get props => [
    allSubjects,
    userSubjects,
    filteredSubjects,
    selectedCategory,
    userProfile,
  ];
}

class LearningError extends LearningState {
  final String message;
  final List<LearningSubject> fallbackSubjects;

  const LearningError({
    required this.message,
    this.fallbackSubjects = const [],
  });

  @override
  List<Object?> get props => [message, fallbackSubjects];
}
