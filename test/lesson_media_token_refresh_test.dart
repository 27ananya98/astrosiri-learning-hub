import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:astro_siri_learning_hub/data/services/auth_service.dart';
import 'package:astro_siri_learning_hub/data/services/learning_service.dart';
import 'package:astro_siri_learning_hub/domain/models/quiz.dart';
import 'package:astro_siri_learning_hub/domain/models/user.dart';

class _RefreshingAuthService implements AuthService {
  User? _user = const User(
    id: 'user-1',
    fullName: 'Test User',
    accessToken: 'old-access-token',
    refreshToken: 'refresh-token',
  );
  int refreshCalls = 0;

  @override
  User? get currentUser => _user;

  @override
  Stream<bool> get onTokenExpired => const Stream<bool>.empty();

  @override
  Stream<User> get onUserChanged => const Stream<User>.empty();

  @override
  Future<User?> refreshToken({String? tokenToRefresh}) async {
    refreshCalls += 1;
    _user = _user!.copyWith(accessToken: 'new-access-token');
    return _user;
  }

  @override
  Future<User> signInWithGoogle() => Future.error(UnimplementedError());

  @override
  Future<User> signInWithApple() => Future.error(UnimplementedError());

  @override
  Future<String> sendOtp(String identifier) =>
      Future.error(UnimplementedError());

  @override
  Future<User> verifyOtp(String identifier, String otp) =>
      Future.error(UnimplementedError());

  @override
  Future<User> updateProfile(User updatedUser) =>
      Future.error(UnimplementedError());

  @override
  Future<User> updateUserSubjects(List<String> subjectIds, {String? token}) =>
      Future.error(UnimplementedError());

  @override
  Future<void> signOut() async {}

  @override
  Future<User?> getSavedUser() async => _user;
}

void main() {
  test('retries lesson media once with the refreshed access token', () async {
    final authService = _RefreshingAuthService();
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (requests.length == 1) {
        return http.Response('{}', 401);
      }
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'video': {'url': 'https://cdn.example.com/lesson.mp4'},
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = ApiLearningService(
      client: client,
      authService: authService,
    );
    final media = await service.getLessonMobileMedia(
      'lesson-1',
      token: 'old-access-token',
    );

    expect(media?.videoUrl, 'https://cdn.example.com/lesson.mp4');
    expect(authService.refreshCalls, 1);
    expect(requests, hasLength(2));
    expect(requests[0].headers['authorization'], 'Bearer old-access-token');
    expect(requests[1].headers['authorization'], 'Bearer new-access-token');
  });

  test('loads quizzes and retries after an expired access token', () async {
    final authService = _RefreshingAuthService();
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      if (requests.length == 1) return http.Response('{}', 401);
      return http.Response(
        jsonEncode({
          'success': true,
          'data': {
            'quizzes': [
              {
                'id': 'quiz-1',
                'subjectId': 'subject-1',
                'title': 'Foundations Quiz',
                'totalQuestions': 8,
                'durationMinutes': 12,
              },
            ],
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = ApiLearningService(
      client: client,
      authService: authService,
    );
    final quizzes = await service.getQuizzesBySubject(
      'subject-1',
      token: 'old-access-token',
    );

    expect(quizzes, hasLength(1));
    expect(quizzes.single, isA<Quiz>());
    expect(quizzes.single.title, 'Foundations Quiz');
    expect(quizzes.single.totalQuestions, 8);
    expect(authService.refreshCalls, 1);
    expect(requests, hasLength(2));
    expect(requests[0].headers['authorization'], 'Bearer old-access-token');
    expect(requests[1].headers['authorization'], 'Bearer new-access-token');
  });

  test('submits quiz answers using the native quiz submit payload', () async {
    final authService = _RefreshingAuthService();
    late http.Request submittedRequest;
    final client = MockClient((request) async {
      submittedRequest = request;
      return http.Response(
        jsonEncode({
          'success': true,
          'message': 'Quiz result saved successfully in database!',
          'data': {
            'success': true,
            'passed': true,
            'scorePercentage': 100,
            'totalQuestions': 2,
            'correctAnswers': 2,
            'pointsEarned': 50,
            'totalSubjectPoints': 50,
            'quizAttempts': {'quiz-1': 1},
            'attemptsMade': 1,
          },
        }),
        200,
        headers: {'content-type': 'application/json'},
      );
    });

    final service = ApiLearningService(
      client: client,
      authService: authService,
    );
    final result = await service.submitQuiz('quiz-1', {
      'question-1': 1,
      'question-2': 2,
    }, token: 'old-access-token');
    final body = jsonDecode(submittedRequest.body) as Map<String, dynamic>;

    expect(submittedRequest.method, 'POST');
    expect(submittedRequest.url.path, contains('/learning/quizzes/submit'));
    expect(
      submittedRequest.headers['authorization'],
      'Bearer old-access-token',
    );
    expect(body['quizId'], 'quiz-1');
    expect(body['answers'], {'question-1': 1, 'question-2': 2});
    expect(result.passed, isTrue);
    expect(result.scorePercentage, 100);
    expect(result.attemptsMade, 1);
  });
}
