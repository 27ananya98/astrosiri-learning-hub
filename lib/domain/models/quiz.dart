/// Lightweight compatibility models for the legacy quiz service tests.
/// Quiz UI is not part of the current mobile application.
class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;

  const QuizQuestion({
    required this.id,
    required this.question,
    this.options = const [],
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id']?.toString() ?? '',
      question: json['question']?.toString() ?? '',
      options:
          (json['options'] as List?)
              ?.map((option) => option.toString())
              .toList() ??
          const [],
    );
  }
}

class Quiz {
  final String id;
  final String subjectId;
  final String title;
  final String description;
  final int totalQuestions;
  final int durationMinutes;
  final int passingScore;
  final bool isCompleted;
  final List<QuizQuestion> questions;

  const Quiz({
    required this.id,
    this.subjectId = '',
    required this.title,
    this.description = '',
    this.totalQuestions = 0,
    this.durationMinutes = 0,
    this.passingScore = 0,
    this.isCompleted = false,
    this.questions = const [],
  });

  factory Quiz.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List?;
    return Quiz(
      id: json['id']?.toString() ?? '',
      subjectId: json['subjectId']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      totalQuestions:
          (json['totalQuestions'] as num?)?.toInt() ??
          rawQuestions?.length ??
          0,
      durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
      passingScore: (json['passingScore'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      questions:
          rawQuestions
              ?.whereType<Map>()
              .map(
                (question) =>
                    QuizQuestion.fromJson(Map<String, dynamic>.from(question)),
              )
              .toList() ??
          const [],
    );
  }
}

class QuizSubmissionResult {
  final bool success;
  final String message;
  final bool passed;
  final int scorePercentage;
  final int totalQuestions;
  final int correctAnswers;
  final int pointsEarned;
  final int totalSubjectPoints;
  final Map<String, int> quizAttempts;
  final int attemptsMade;

  const QuizSubmissionResult({
    required this.success,
    this.message = '',
    this.passed = false,
    this.scorePercentage = 0,
    this.totalQuestions = 0,
    this.correctAnswers = 0,
    this.pointsEarned = 0,
    this.totalSubjectPoints = 0,
    this.quizAttempts = const {},
    this.attemptsMade = 0,
  });

  factory QuizSubmissionResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map
        ? Map<String, dynamic>.from(json['data'] as Map)
        : json;
    final attempts = <String, int>{};
    final rawAttempts = data['quizAttempts'];
    if (rawAttempts is Map) {
      rawAttempts.forEach((key, value) {
        attempts[key.toString()] = (value as num?)?.toInt() ?? 0;
      });
    }
    return QuizSubmissionResult(
      success: data['success'] as bool? ?? json['success'] as bool? ?? false,
      message: json['message']?.toString() ?? data['message']?.toString() ?? '',
      passed: data['passed'] as bool? ?? false,
      scorePercentage: (data['scorePercentage'] as num?)?.toInt() ?? 0,
      totalQuestions: (data['totalQuestions'] as num?)?.toInt() ?? 0,
      correctAnswers: (data['correctAnswers'] as num?)?.toInt() ?? 0,
      pointsEarned: (data['pointsEarned'] as num?)?.toInt() ?? 0,
      totalSubjectPoints: (data['totalSubjectPoints'] as num?)?.toInt() ?? 0,
      quizAttempts: attempts,
      attemptsMade: (data['attemptsMade'] as num?)?.toInt() ?? 0,
    );
  }
}
