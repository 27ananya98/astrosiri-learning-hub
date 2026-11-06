import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/utils/jwt_helper.dart';
import '../../domain/models/course.dart';
import '../../domain/models/learning_subject.dart';
import '../../domain/models/lesson_mobile_media.dart';
import '../../domain/models/quiz.dart';
import '../../domain/models/user.dart';
import 'auth_service.dart';

abstract class LearningService {
  Future<List<LearningSubject>> getAllLearningSubjects({String? token});
  Future<List<LearningSubject>> getUserLearningSubjects(
    String userId, {
    String? token,
  });
  Future<List<LearningSubject>> getLearningSubjects(
    String userId, {
    String? token,
  });
  Future<User?> getUserProfile(String userId, {String? token});
  Future<List<Course>> getCoursesBySubject(String subjectId, {String? token});
  Future<List<Quiz>> getQuizzesBySubject(String subjectId, {String? token});
  Future<QuizSubmissionResult> submitQuiz(
    String quizId,
    Map<String, int> answers, {
    String? token,
  });
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

class ApiLearningService implements LearningService {
  final http.Client _client;
  final AuthService _authService;

  ApiLearningService({http.Client? client, AuthService? authService})
    : _client = client ?? http.Client(),
      _authService = authService ?? ApiAuthService();

  Future<String?> _resolveValidToken(String? token) async {
    // Prefer the session token because a previous request may already have
    // refreshed it while the caller is still holding the old token.
    String? resolved = _authService.currentUser?.accessToken ?? token;
    if (resolved == null || resolved.isEmpty) {
      try {
        final savedUser = await _authService.getSavedUser();
        resolved = savedUser?.accessToken;
      } catch (_) {}
    }
    if (resolved != null &&
        resolved.isNotEmpty &&
        JwtHelper.isExpired(resolved)) {
      debugPrint(
        'AccessToken is expired. Auto-refreshing before making request...',
      );
      try {
        final refreshed = await _authService.refreshToken();
        resolved = refreshed?.accessToken ?? resolved;
      } catch (e) {
        debugPrint('Token pre-request refresh note: $e');
      }
    }
    return resolved;
  }

  Map<String, String> _headersWithToken(
    Map<String, String> headers,
    String? token,
  ) {
    final requestHeaders = <String, String>{...headers};
    if (token != null && token.isNotEmpty) {
      requestHeaders['Authorization'] = 'Bearer $token';
    } else {
      requestHeaders.remove('Authorization');
    }
    return requestHeaders;
  }

  bool _isAuthenticationFailure(http.Response response) =>
      response.statusCode == 401 || response.statusCode == 403;

  Future<String?> _refreshAfterAuthenticationFailure({
    String? failedToken,
  }) async {
    // If another concurrent request has already refreshed the session token,
    // immediately reuse the freshly issued token without firing a duplicate refresh.
    final currentToken = _authService.currentUser?.accessToken;
    if (currentToken != null &&
        currentToken.isNotEmpty &&
        currentToken != failedToken &&
        !JwtHelper.isExpired(currentToken)) {
      debugPrint(
        'Token was already refreshed by another concurrent request. Reusing fresh token.',
      );
      return currentToken;
    }

    try {
      final refreshed = await _authService.refreshToken();
      return refreshed?.accessToken;
    } catch (error) {
      // AuthService emits onTokenExpired when refresh is no longer possible.
      // Keep the original API response available to the caller/fallback path.
      debugPrint('Unable to refresh access token after API rejection: $error');
      return null;
    }
  }

  /// Sends one authenticated GET and retries it once with a freshly issued
  /// access token when the server rejects the original bearer token.
  Future<http.Response> _getWithTokenRefresh(
    Uri uri, {
    required Map<String, String> headers,
    required String? token,
    Duration timeout = const Duration(minutes: 1),
  }) async {
    var response = await _client
        .get(uri, headers: _headersWithToken(headers, token))
        .timeout(timeout);
    if (!_isAuthenticationFailure(response)) return response;

    final refreshedToken = await _refreshAfterAuthenticationFailure(
      failedToken: token,
    );
    if (refreshedToken == null || refreshedToken.isEmpty) return response;

    response = await _client
        .get(uri, headers: _headersWithToken(headers, refreshedToken))
        .timeout(timeout);
    return response;
  }

  /// Sends one authenticated POST and retries it once with a freshly issued
  /// access token when the server rejects the original bearer token.
  Future<http.Response> _postWithTokenRefresh(
    Uri uri, {
    required Map<String, String> headers,
    required String? token,
    required String body,
    Duration timeout = const Duration(minutes: 1),
  }) async {
    var response = await _client
        .post(uri, headers: _headersWithToken(headers, token), body: body)
        .timeout(timeout);
    if (!_isAuthenticationFailure(response)) return response;

    final refreshedToken = await _refreshAfterAuthenticationFailure(
      failedToken: token,
    );
    if (refreshedToken == null || refreshedToken.isEmpty) return response;

    response = await _client
        .post(
          uri,
          headers: _headersWithToken(headers, refreshedToken),
          body: body,
        )
        .timeout(timeout);
    return response;
  }

  /// Learning endpoints have returned both `{data: {subjects: [...]}}` and
  /// `{data: [...]}` over time. Keep the UI model layer independent of that
  /// envelope variation so every subject follows the same path.
  static List<dynamic> _readList(Map<String, dynamic> response, String key) {
    final payload = response['data'];
    if (payload is List) return payload;
    if (payload is Map) {
      final nested =
          payload[key] ??
          payload[key.toLowerCase()] ??
          payload['items'] ??
          payload['results'];
      if (nested is List) return nested;
    }
    final root =
        response[key] ??
        response[key.toLowerCase()] ??
        response['items'] ??
        response['results'];
    return root is List ? root : const <dynamic>[];
  }

  Future<List<LearningSubject>> _getSubjectsFromEndpoint(
    String url, {
    required Map<String, String> headers,
    required String? token,
  }) async {
    final response = await _getWithTokenRefresh(
      Uri.parse(url),
      headers: headers,
      token: token,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('Subjects API returned HTTP ${response.statusCode}.');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      final contentType = response.headers['content-type'] ?? 'unknown';
      throw StateError(
        'Subjects API returned non-JSON HTTP ${response.statusCode} '
        '(content-type: $contentType).',
      );
    }
    if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
      final message = decoded is Map
          ? (decoded['message'] ?? decoded['error']?['message'])
          : null;
      throw StateError(
        'Subjects API returned an unsuccessful response'
        '${message == null ? '' : ': $message'}.',
      );
    }

    return _readList(decoded, 'subjects')
        .whereType<Map>()
        .map(
          (subject) =>
              LearningSubject.fromJson(Map<String, dynamic>.from(subject)),
        )
        .toList();
  }

  Map<String, String> _subjectHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  @override
  Future<List<LearningSubject>> getAllLearningSubjects({String? token}) async {
    final validToken = await _resolveValidToken(token);
    Object? lastError;
    for (final request in [
      // GET /api/v1/learning/subjects
      ApiConstants.nativeAllLearningSubjects(),
      // Native catalogue route used by newer deployments.
      ApiConstants.nativeSubjects(),
    ]) {
      try {
        debugPrint('Fetching complete subjects catalogue: $request');
        return await _getSubjectsFromEndpoint(
          request,
          headers: _subjectHeaders(validToken),
          token: validToken,
        );
      } catch (error) {
        lastError = error;
        debugPrint('Subjects catalogue request failed: $error');
      }
    }
    throw StateError(
      'Unable to load the complete subjects catalogue from the API: $lastError',
    );
  }

  @override
  Future<List<LearningSubject>> getUserLearningSubjects(
    String userId, {
    String? token,
  }) async {
    final validToken = await _resolveValidToken(token);
    Object? lastError;
    final requests = [
      // The deployed backend currently serves the dashboard route through
      // /learning/subjects?userId={userId}.
      ApiConstants.nativeLearningSubjects(userId),
      // Keep the path-based route as a fallback for newer deployments.
      ApiConstants.nativeUserSubjects(userId),
    ];
    for (final request in requests) {
      try {
        debugPrint('Fetching user subjects: $request');
        return await _getSubjectsFromEndpoint(
          request,
          headers: _subjectHeaders(validToken),
          token: validToken,
        );
      } catch (error) {
        lastError = error;
        debugPrint('User subjects request failed: $error');
      }
    }
    throw StateError(
      'Unable to load subjects for user $userId from the API: $lastError',
    );
  }

  @override
  Future<List<LearningSubject>> getLearningSubjects(
    String userId, {
    String? token,
  }) {
    return getUserLearningSubjects(userId, token: token);
  }

  @override
  Future<List<Course>> getCoursesBySubject(
    String subjectId, {
    String? token,
  }) async {
    final validToken = await _resolveValidToken(token);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (validToken != null && validToken.isNotEmpty)
        'Authorization': 'Bearer $validToken',
    };

    // Native mobile backend only.
    try {
      final nativeUrl = ApiConstants.nativeCourses(subjectId);
      debugPrint('Fetching courses from native backend: $nativeUrl');
      final response = await _getWithTokenRefresh(
        Uri.parse(nativeUrl),
        headers: headers,
        token: validToken,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true) {
          final coursesJson = _readList(data, 'courses');
          return coursesJson
              .map((c) => Course.fromJson(c as Map<String, dynamic>))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Native courses fetch failed: $e');
    }

    throw StateError(
      'Unable to load courses for subject $subjectId from the API.',
    );
  }

  @override
  Future<List<Quiz>> getQuizzesBySubject(
    String subjectId, {
    String? token,
  }) async {
    final validToken = await _resolveValidToken(token);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (validToken != null && validToken.isNotEmpty)
        'Authorization': 'Bearer $validToken',
    };
    final response = await _getWithTokenRefresh(
      Uri.parse(ApiConstants.nativeQuizzes(subjectId)),
      headers: headers,
      token: _authService.currentUser?.accessToken ?? validToken,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Unable to load quizzes for subject $subjectId from the API.',
      );
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (data['success'] != true) return const <Quiz>[];
    return _readList(data, 'quizzes')
        .whereType<Map>()
        .map((quiz) => Quiz.fromJson(Map<String, dynamic>.from(quiz)))
        .toList();
  }

  @override
  Future<QuizSubmissionResult> submitQuiz(
    String quizId,
    Map<String, int> answers, {
    String? token,
  }) async {
    final validToken = await _resolveValidToken(token);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (validToken != null && validToken.isNotEmpty)
        'Authorization': 'Bearer $validToken',
    };
    final response = await _postWithTokenRefresh(
      Uri.parse(ApiConstants.nativeQuizSubmit()),
      headers: headers,
      token: _authService.currentUser?.accessToken ?? validToken,
      body: jsonEncode({'quizId': quizId, 'answers': answers}),
    );
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final result = QuizSubmissionResult.fromJson(decoded);
    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        !result.success) {
      throw StateError(
        result.message.isNotEmpty
            ? result.message
            : 'Unable to save the quiz result.',
      );
    }
    return result;
  }

  @override
  Future<User?> getUserProfile(String userId, {String? token}) async {
    final validToken = await _resolveValidToken(token);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (validToken != null && validToken.isNotEmpty)
        'Authorization': 'Bearer $validToken',
    };

    // Native mobile backend only.
    try {
      final url = ApiConstants.nativeUserProfile(userId);
      final response = await _getWithTokenRefresh(
        Uri.parse(url),
        headers: headers,
        token: validToken,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data['success'] == true &&
            (data['user'] != null || data['data'] != null)) {
          final preservedRefreshToken =
              _authService.currentUser?.refreshToken ??
              (await _authService.getSavedUser())?.refreshToken;
          return User.fromJson(
            data,
            accessToken: validToken ?? token,
            refreshToken: preservedRefreshToken,
          );
        }
      }
    } catch (e) {
      debugPrint('Native profile fetch failed: $e');
    }

    return null;
  }

  @override
  Future<LessonMobileMedia?> getLessonMobileMedia(
    String lessonId, {
    String? token,
  }) async {
    final validToken = await _resolveValidToken(token);
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (validToken != null && validToken.isNotEmpty)
        'Authorization': 'Bearer $validToken',
    };

    // Native Mobile Lesson Media Endpoint:
    // GET /api/v1/media/mobile/lesson/{lessonId}
    // Authorization: Bearer <accessToken>
    try {
      final nativeUrl = ApiConstants.nativeLessonMediaMobile(lessonId);
      debugPrint('Fetching mobile media from native endpoint: $nativeUrl');
      final res = await _getWithTokenRefresh(
        Uri.parse(nativeUrl),
        headers: headers,
        token: validToken,
      );
      debugPrint('Mobile media response status: ${res.statusCode}');
      debugPrint('Mobile media response body: ${res.body}');
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final media = LessonMobileMedia.fromJson(data);
        debugPrint(
          'Retrieved mobile media: video=${media.videoUrl}, pdf=${media.pdfUrl}',
        );
        return media;
      }
    } catch (e) {
      debugPrint('Native mobile media fetch failed: $e');
    }

    return null;
  }

  @override
  Future<String?> getLessonMediaUrl(
    String lessonId, {
    required bool isVideo,
    String? token,
  }) async {
    try {
      final mobileMedia = await getLessonMobileMedia(lessonId, token: token);
      if (mobileMedia != null) {
        final targetUrl = isVideo ? mobileMedia.videoUrl : mobileMedia.pdfUrl;
        if (targetUrl != null && targetUrl.isNotEmpty) {
          return targetUrl;
        }
      }
    } catch (e) {
      debugPrint('Mobile media check error: $e');
    }

    return null;
  }
}
