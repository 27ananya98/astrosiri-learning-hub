class ApiConstants {
  ApiConstants._();

  /// Direct Native Mobile Backend Base URL (Azure)
  static const String mobileBaseUrl =
      'https://func-astrosiri-onboarding-dev-cin-h2htbvhnhegkdabh.centralindia-01.azurewebsites.net/api/v1';
  static const String onboardingBaseUrl = 'https://onboarding.astrosiri.com';

  /// Native Auth Endpoints
  static const String nativeGoogleAuth = '$mobileBaseUrl/auth/mobile/google';
  static const String nativeOtpSend = '$mobileBaseUrl/auth/mobile/otp/send';
  static const String nativeOtpVerify = '$mobileBaseUrl/auth/mobile/otp/verify';
  static const String nativeRefreshToken = '$mobileBaseUrl/auth/refresh-token';
  static const String nativeMobileRefreshToken =
      '$mobileBaseUrl/auth/mobile/refresh-token';
  static const String mobileSessionLogout = '$mobileBaseUrl/auth/logout';

  /// Learning Subjects Endpoints
  static String nativeAllLearningSubjects() =>
      '$mobileBaseUrl/learning/subjects';

  static String nativeLearningSubjects(String userId) =>
      '$mobileBaseUrl/learning/subjects?userId=$userId';

  /// Complete subject catalogue and user-specific subject endpoints.
  static String nativeSubjects() => '$mobileBaseUrl/subjects';

  static String nativeUserSubjects(String userId) =>
      '$mobileBaseUrl/subjects/$userId';

  /// Learning Courses by Subject Endpoints
  static String nativeCourses(String subjectId) =>
      '$mobileBaseUrl/learning/courses/$subjectId';

  /// Legacy quiz service endpoints retained for service-level compatibility.
  static String nativeQuizzes(String subjectId) =>
      '$mobileBaseUrl/learning/quizzes?subjectId=$subjectId';

  static String nativeQuizSubmit() => '$mobileBaseUrl/learning/quizzes/submit';

  /// Mobile Lesson Media Endpoint (Unified Video & PDF)
  /// GET /api/v1/media/mobile/lesson/{lessonId}
  static String nativeLessonMediaMobile(String lessonId) =>
      '$mobileBaseUrl/media/mobile/lesson/$lessonId';

  /// Resolves a relative media path against the native API origin.
  ///
  /// Signed Azure URLs are normally absolute. This keeps defensive handling
  /// of relative URLs on the native host instead of routing media through the
  /// website proxy.
  static String resolveNativeMediaUrl(String mediaUrl) {
    if (!mediaUrl.startsWith('/')) return mediaUrl;

    // Web portal proxy sessions live on the onboarding web domain
    if (mediaUrl.startsWith('/api/session/')) {
      return '$onboardingBaseUrl$mediaUrl';
    }

    final base = Uri.parse(mobileBaseUrl);
    final origin = Uri(
      scheme: base.scheme,
      userInfo: base.userInfo,
      host: base.host,
      port: base.port,
    );
    final path = mediaUrl.startsWith('/api/v1')
        ? mediaUrl
        : (mediaUrl.startsWith('/api/')
              ? mediaUrl.replaceFirst('/api/', '/api/v1/')
              : '${base.path}$mediaUrl');
    return origin.replace(path: path).toString();
  }

  /// User Profile Endpoints
  static String nativeUserProfile([String? userId]) =>
      userId != null && userId.isNotEmpty
      ? '$mobileBaseUrl/user/profile?userId=$userId'
      : '$mobileBaseUrl/user/profile';

  /// Google OAuth Web Client ID configured in Google Cloud Console
  static const String googleServerClientId =
      '274643888920-5j8v5q5sv85b0ghsa3qt7oa2avpls7uj.apps.googleusercontent.com';

  /// Google OAuth iOS Client ID (from Google Cloud Console / GoogleService-Info.plist)
  /// Also configured in Info.plist via GIDClientID
  static const String googleIosClientId =
      '274643888920-ugb1g5l8iuv04ukovqpf5snqqb0ua3jc.apps.googleusercontent.com';
}
