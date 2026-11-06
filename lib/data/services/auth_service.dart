import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/jwt_helper.dart';
import '../../domain/models/user.dart';

class GoogleSignInCancelledException implements Exception {
  final String message;
  const GoogleSignInCancelledException([
    this.message = 'Google sign-in was cancelled.',
  ]);

  @override
  String toString() => message;
}

class GoogleAuthException implements Exception {
  final String message;

  const GoogleAuthException(this.message);

  @override
  String toString() => message;
}

class TokenExpiredException implements Exception {
  final String message;
  const TokenExpiredException([
    this.message = 'Session expired. Please log in again.',
  ]);

  @override
  String toString() => message;
}

abstract class AuthService {
  Future<User> signInWithGoogle();

  /// Compatibility seam for older service tests; not exposed in the UI.
  Future<User> signInWithApple();
  Future<String> sendOtp(String identifier);
  Future<User> verifyOtp(String identifier, String otp);
  Future<User> updateProfile(User updatedUser);
  Future<User> updateUserSubjects(List<String> subjectIds, {String? token});
  Future<User?> refreshToken({String? tokenToRefresh});
  Stream<bool> get onTokenExpired;
  Stream<User> get onUserChanged;
  Future<void> signOut();
  Future<User?> getSavedUser();
  User? get currentUser;
}

class ApiAuthService implements AuthService {
  static final ApiAuthService _instance = ApiAuthService._internal();

  factory ApiAuthService({http.Client? client}) {
    if (client != null) return ApiAuthService._internal(client: client);
    return _instance;
  }

  ApiAuthService._internal({http.Client? client})
    : _client = client ?? http.Client() {
    _ensureGoogleInitialized();
  }

  final StreamController<bool> _tokenExpiredController =
      StreamController<bool>.broadcast();
  final StreamController<User> _userChangedController =
      StreamController<User>.broadcast();

  // Use the legacy Google Sign-In client used by the previously working
  // build. This avoids the Android Credential Manager re-authentication path
  // that was returning code 16 before the backend request.
  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: ApiConstants.googleServerClientId,
  );

  @override
  Stream<bool> get onTokenExpired => _tokenExpiredController.stream;

  @override
  Stream<User> get onUserChanged => _userChangedController.stream;

  User? _currentUser;
  final http.Client _client;
  bool _isGoogleInitialized = false;
  Future<User?>? _refreshInFlight;
  static const String _userPrefsKey = 'astrosiri_user_session';
  static const String _refreshTokenPrefsKey = 'astrosiri_refresh_token';
  static const String _accessTokenPrefsKey = 'astrosiri_access_token';

  Future<void> _saveUserToPrefs(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userPrefsKey, jsonEncode(user.toJson()));
      if (user.refreshToken != null && user.refreshToken!.trim().isNotEmpty) {
        await prefs.setString(_refreshTokenPrefsKey, user.refreshToken!.trim());
      }
      if (user.accessToken != null && user.accessToken!.trim().isNotEmpty) {
        await prefs.setString(_accessTokenPrefsKey, user.accessToken!.trim());
      }
      debugPrint(
        'User session successfully persisted to SharedPreferences for: ${user.fullName}',
      );
      if (!_userChangedController.isClosed) {
        _userChangedController.add(user);
      }
    } catch (e) {
      debugPrint('Warning saving user session: $e');
    }
  }

  Future<void> _clearUserFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userPrefsKey);
      await prefs.remove(_refreshTokenPrefsKey);
      await prefs.remove(_accessTokenPrefsKey);
      debugPrint('User session cleared from SharedPreferences.');
    } catch (e) {
      debugPrint('Warning clearing user session: $e');
    }
  }

  @override
  Future<User?> getSavedUser() async {
    if (_currentUser != null &&
        _currentUser!.refreshToken != null &&
        _currentUser!.refreshToken!.trim().isNotEmpty) {
      return _currentUser;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJsonStr = prefs.getString(_userPrefsKey);
      final dedicatedAccessToken = prefs.getString(_accessTokenPrefsKey);
      final dedicatedRefreshToken = prefs.getString(_refreshTokenPrefsKey);

      if (userJsonStr != null && userJsonStr.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(userJsonStr);
        final jsonRefreshToken = data['refreshToken']?.toString().trim();
        final effectiveRefreshToken =
            (jsonRefreshToken != null && jsonRefreshToken.isNotEmpty)
            ? jsonRefreshToken
            : dedicatedRefreshToken;

        final jsonAccessToken = data['accessToken']?.toString().trim();
        final effectiveAccessToken =
            (jsonAccessToken != null && jsonAccessToken.isNotEmpty)
            ? jsonAccessToken
            : dedicatedAccessToken;

        _currentUser = User.fromJson(
          data,
          accessToken: effectiveAccessToken,
          refreshToken: effectiveRefreshToken,
          isNewUser: data['isNewUser'] as bool?,
        );
        debugPrint(
          'Successfully restored saved session for: ${_currentUser?.fullName} (${_currentUser?.mobile})',
        );
        return _currentUser;
      } else if (_currentUser != null &&
          dedicatedRefreshToken != null &&
          dedicatedRefreshToken.isNotEmpty) {
        _currentUser = _currentUser!.copyWith(
          refreshToken: dedicatedRefreshToken,
          accessToken: dedicatedAccessToken ?? _currentUser!.accessToken,
        );
        return _currentUser;
      }
    } catch (e) {
      debugPrint('Warning reading saved session: $e');
    }

    // A missing local session must stay unauthenticated. The dashboard
    // receives profile data only after a successful backend login.
    return null;
  }

  Future<void>? _googleInitFuture;

  Future<void> _ensureGoogleInitialized() {
    if (_isGoogleInitialized) return Future.value();
    return _googleInitFuture ??= _doGoogleInit();
  }

  Future<void> _doGoogleInit() async {
    try {
      // google_sign_in 6.x initializes through its client instance.
      _googleSignIn;
      _isGoogleInitialized = true;
    } catch (e) {
      debugPrint('GoogleSignIn initialize warning: $e');
    }
  }

  static bool _isGoogleReauthenticationFailure(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('account reauth failed') ||
        (message.contains('reauth') && message.contains('failed'));
  }

  Future<GoogleSignInAccount> _authenticateGoogleAccount() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) {
        throw const GoogleSignInCancelledException(
          'Google sign-in was cancelled.',
        );
      }
      return account;
    } catch (error) {
      if (!_isGoogleReauthenticationFailure(error)) rethrow;

      // Google code 16 can be returned as "canceled" when the SDK has a
      // stale account re-authentication session. Clear only that provider
      // session and retry the interactive sign-in once so the backend can
      // receive a fresh ID token.
      debugPrint(
        'Google auth SDK re-authentication failed; clearing stale Google session and retrying: $error',
      );
      try {
        await _googleSignIn.signOut();
      } catch (signOutError) {
        debugPrint('Google session reset warning: $signOutError');
      }

      final retryAccount = await _googleSignIn.signIn();
      if (retryAccount == null) {
        throw const GoogleSignInCancelledException(
          'Google sign-in was cancelled.',
        );
      }
      return retryAccount;
    }
  }

  Future<void> _resetGoogleSessionAfterBackendRejection() async {
    // The Google provider remains signed in even when AstroSiri rejects the
    // account. Clear that provider session so the next tap opens the account
    // chooser instead of silently reusing the rejected account.
    try {
      await _googleSignIn.signOut();
      debugPrint(
        'Google provider session cleared after backend authentication rejection.',
      );
    } catch (error) {
      debugPrint('Google provider session reset warning: $error');
    }
  }

  @override
  User? get currentUser => _currentUser;

  /// Helper to extract accessToken and refreshToken across all backend response variations.
  static (String? accessToken, String? refreshToken) _extractTokens(
    Map<String, dynamic> responseData,
  ) {
    final dataMap = responseData['data'] is Map
        ? Map<String, dynamic>.from(responseData['data'] as Map)
        : null;

    final tokensMap = (responseData['tokens'] is Map
        ? Map<String, dynamic>.from(responseData['tokens'] as Map)
        : (dataMap != null && dataMap['tokens'] is Map
              ? Map<String, dynamic>.from(dataMap['tokens'] as Map)
              : null));

    final resolvedAccessToken =
        responseData['accessToken']?.toString() ??
        responseData['access_token']?.toString() ??
        responseData['token']?.toString() ??
        responseData['jwt']?.toString() ??
        dataMap?['accessToken']?.toString() ??
        dataMap?['access_token']?.toString() ??
        dataMap?['token']?.toString() ??
        dataMap?['jwt']?.toString() ??
        tokensMap?['accessToken']?.toString() ??
        tokensMap?['access_token']?.toString() ??
        tokensMap?['token']?.toString() ??
        tokensMap?['jwt']?.toString();

    final resolvedRefreshToken =
        responseData['refreshToken']?.toString() ??
        responseData['refresh_token']?.toString() ??
        dataMap?['refreshToken']?.toString() ??
        dataMap?['refresh_token']?.toString() ??
        tokensMap?['refreshToken']?.toString() ??
        tokensMap?['refresh_token']?.toString();

    return (resolvedAccessToken, resolvedRefreshToken);
  }

  static dynamic _redactAuthResponse(dynamic value) {
    if (value is Map) {
      return value.map((key, nestedValue) {
        final normalizedKey = key.toString().toLowerCase();
        final isSensitive =
            normalizedKey.contains('token') ||
            normalizedKey.contains('secret') ||
            normalizedKey == 'authorization';
        return MapEntry(
          key,
          isSensitive ? '<redacted>' : _redactAuthResponse(nestedValue),
        );
      });
    }
    if (value is List) {
      return value.map(_redactAuthResponse).toList();
    }
    return value;
  }

  static String _redactedResponseBody(String body) {
    try {
      final decoded = jsonDecode(body);
      return jsonEncode(_redactAuthResponse(decoded));
    } catch (_) {
      return body.length > 500 ? '${body.substring(0, 500)}...' : body;
    }
  }

  static String? _apiErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map) return null;

      final error = decoded['error'];
      if (error is Map && error['message'] != null) {
        return error['message'].toString();
      }
      if (decoded['message'] != null) return decoded['message'].toString();

      final data = decoded['data'];
      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    } catch (_) {}
    return null;
  }

  static String _googleAuthUserMessage(String? apiMessage) {
    final normalized = (apiMessage ?? '').toLowerCase();
    if (normalized.contains('deactivat') ||
        normalized.contains('disabled') ||
        normalized.contains('suspend') ||
        normalized.contains('blocked') ||
        normalized.contains('inactive')) {
      return 'Your account has been deactivated by an administrator. Please contact support.';
    }
    if (normalized.contains('invalid') &&
        (normalized.contains('credential') || normalized.contains('token'))) {
      return 'Google sign-in could not be verified. Please try again.';
    }
    return 'Unable to sign in with Google right now. Please try again.';
  }

  @override
  Future<User> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();

      // 1. Trigger interactive Google authentication
      final GoogleSignInAccount account = await _authenticateGoogleAccount();

      // 2. Extract Google ID Token (JWT Credential) & Access Token
      final authentication = await account.authentication;
      final idToken = authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Google did not return a valid identity token.');
      }
      final verifiedIdToken = idToken;
      final accessToken = authentication.accessToken;

      debugPrint(
        'Google ID Token: ${verifiedIdToken.substring(0, verifiedIdToken.length > 20 ? 20 : verifiedIdToken.length)}..., AccessToken: ${accessToken != null && accessToken.isNotEmpty ? "present" : "null"}',
      );

      // 3. Post credential to the native mobile backend.
      final payload = jsonEncode({
        'credential': verifiedIdToken,
        'idToken': verifiedIdToken,
        if (accessToken != null && accessToken.isNotEmpty)
          'accessToken': accessToken,
        'token': verifiedIdToken,
        'email': account.email,
        if (account.displayName != null && account.displayName!.isNotEmpty)
          'name': account.displayName,
        if (account.displayName != null && account.displayName!.isNotEmpty)
          'fullName': account.displayName,
      });

      debugPrint(
        'Google auth API request: POST ${ApiConstants.nativeGoogleAuth}',
      );
      final response = await _client
          .post(
            Uri.parse(ApiConstants.nativeGoogleAuth),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: payload,
          )
          .timeout(const Duration(minutes: 1));

      final redactedResponseBody = _redactedResponseBody(response.body);
      debugPrint('Google auth API response status: ${response.statusCode}');
      debugPrint('Google auth API response body: $redactedResponseBody');

      String? backendErrorMessage;
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          final Map<String, dynamic> responseData =
              jsonDecode(response.body) as Map<String, dynamic>;
          final dataMap = responseData['data'] is Map
              ? Map<String, dynamic>.from(responseData['data'] as Map)
              : null;
          final (resolvedAccessToken, resolvedRefreshToken) = _extractTokens(
            responseData,
          );
          if (responseData['success'] == true ||
              responseData.containsKey('user') ||
              responseData.containsKey('data')) {
            final authenticatedUser = User.fromJson(
              responseData,
              accessToken: resolvedAccessToken,
              refreshToken: resolvedRefreshToken,
              isNewUser:
                  responseData['isNewUser'] as bool? ??
                  dataMap?['isNewUser'] as bool?,
              fallbackIdentifier: account.email,
            );

            // Do not treat a Google account as logged in until the AstroSiri
            // backend has returned a usable access token for API requests.
            if (authenticatedUser.accessToken == null ||
                authenticatedUser.accessToken!.isEmpty) {
              throw Exception(
                'Google sign-in response did not include an access token.',
              );
            }
            _currentUser = authenticatedUser;

            // The Google account name is the source of truth for the initial
            // profile name. This prevents a backend placeholder or stale
            // value from hiding the name returned by Google.
            final googleName = account.displayName?.trim();
            if (googleName != null && googleName.isNotEmpty) {
              _currentUser = _currentUser!.copyWith(fullName: googleName);
            }

            // Populate avatar from Google photo if missing
            if ((_currentUser!.avatarUrl == null ||
                    _currentUser!.avatarUrl!.isEmpty) &&
                account.photoUrl != null &&
                account.photoUrl!.isNotEmpty) {
              _currentUser = _currentUser!.copyWith(
                avatarUrl: account.photoUrl,
              );
            }

            await _saveUserToPrefs(_currentUser!);
            return _currentUser!;
          }
        } catch (parseError) {
          backendErrorMessage = parseError.toString().replaceFirst(
            RegExp(r'^Exception:\s*'),
            '',
          );
          debugPrint('Warning parsing backend response: $parseError');
        }
      }

      final apiMessage = _apiErrorMessage(response.body);
      debugPrint(
        'Native Google auth error response: ${_redactedResponseBody(response.body)}',
      );
      await _resetGoogleSessionAfterBackendRejection();
      throw GoogleAuthException(
        _googleAuthUserMessage(apiMessage ?? backendErrorMessage),
      );
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      // Google reports code 16 as "canceled" when account re-authentication
      // fails. This is not the same as the user dismissing the picker, so
      // expose a useful retry message to the UI.
      if (_isGoogleReauthenticationFailure(e)) {
        debugPrint('Google account re-authentication failed: $e');
        throw const GoogleAuthException(
          'Google account verification failed. Please try again or choose another Google account.',
        );
      }
      if (errStr.contains('cancel') ||
          errStr.contains('12501') ||
          errStr.contains('16:') ||
          errStr.contains('no credential') ||
          errStr.contains('popup_closed_by_user')) {
        debugPrint('Google sign-in was cancelled by user: $e');
        throw const GoogleSignInCancelledException(
          'Google sign-in was cancelled.',
        );
      }
      debugPrint('Error in signInWithGoogle: $e');
      rethrow;
    }
  }

  @override
  Future<User> signInWithApple() {
    return Future<User>.error(
      UnsupportedError('Apple sign-in is not enabled in the mobile app.'),
    );
  }

  /// Sends OTP to email or mobile using payload: { "identifier": "..." }
  @override
  Future<String> sendOtp(String identifier) async {
    final payload = jsonEncode({'identifier': identifier.trim()});
    debugPrint('Sending OTP request for: $identifier');

    final response = await _client
        .post(
          Uri.parse(ApiConstants.nativeOtpSend),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: payload,
        )
        .timeout(const Duration(minutes: 1));

    final Map<String, dynamic> data =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        data['success'] == true) {
      return data['message']?.toString() ??
          'Verification code sent successfully.';
    }

    final errorMessage = data['error'] is Map
        ? data['error']['message']?.toString()
        : data['message']?.toString();

    throw Exception(errorMessage ?? 'Failed to send verification code');
  }

  /// Verifies OTP code using payload: { "identifier": "...", "otp": "..." }
  @override
  Future<User> verifyOtp(String identifier, String otp) async {
    final payload = jsonEncode({
      'identifier': identifier.trim(),
      'otp': otp.trim(),
    });
    debugPrint('Verifying OTP for: $identifier, code: $otp');

    final response = await _client
        .post(
          Uri.parse(ApiConstants.nativeOtpVerify),
          headers: const {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: payload,
        )
        .timeout(const Duration(minutes: 1));

    final Map<String, dynamic> responseData =
        jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (responseData['success'] == true ||
          responseData.containsKey('user') ||
          responseData.containsKey('data')) {
        final dataMap = responseData['data'] is Map
            ? responseData['data'] as Map
            : null;
        final (resolvedAccessToken, resolvedRefreshToken) = _extractTokens(
          responseData,
        );

        _currentUser = User.fromJson(
          responseData,
          accessToken: resolvedAccessToken,
          refreshToken: resolvedRefreshToken,
          isNewUser:
              responseData['isNewUser'] as bool? ??
              dataMap?['isNewUser'] as bool?,
          fallbackIdentifier: identifier,
        );
        await _saveUserToPrefs(_currentUser!);
        return _currentUser!;
      }
    }

    final errorMessage = responseData['error'] is Map
        ? responseData['error']['message']?.toString()
        : responseData['message']?.toString();

    throw Exception(
      errorMessage ?? 'Invalid verification code. Please try again.',
    );
  }

  @override
  Future<User> updateProfile(User updatedUser) async {
    var token = _currentUser?.accessToken ?? updatedUser.accessToken;
    final refreshTokenToUse =
        _currentUser?.refreshToken ?? updatedUser.refreshToken;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // Profile setup can happen after the access token has expired. Refresh
    // before the PUT when possible, then keep the 401/403 retry below as a
    // server-side safety net for opaque or unexpectedly expired tokens.
    if (token != null && token.isNotEmpty && JwtHelper.isExpired(token)) {
      try {
        final refreshed = await refreshToken(tokenToRefresh: refreshTokenToUse);
        token = refreshed?.accessToken ?? token;
      } catch (error) {
        debugPrint('Unable to refresh token before profile update: $error');
      }
    }

    var response = await _client
        .put(
          Uri.parse('${ApiConstants.mobileBaseUrl}/user/profile'),
          headers: _headersWithToken(headers, token),
          body: jsonEncode({
            'fullName': updatedUser.fullName,
            'email': updatedUser.email,
            'mobile': updatedUser.mobile,
          }),
        )
        .timeout(const Duration(minutes: 1));

    if (response.statusCode == 401 || response.statusCode == 403) {
      try {
        final currentToken = _currentUser?.accessToken;
        if (currentToken != null &&
            currentToken.isNotEmpty &&
            currentToken != token &&
            !JwtHelper.isExpired(currentToken)) {
          response = await _client
              .put(
                Uri.parse('${ApiConstants.mobileBaseUrl}/user/profile'),
                headers: _headersWithToken(headers, currentToken),
                body: jsonEncode({
                  'fullName': updatedUser.fullName,
                  'email': updatedUser.email,
                  'mobile': updatedUser.mobile,
                }),
              )
              .timeout(const Duration(minutes: 1));
        } else {
          final refreshed = await refreshToken(
            tokenToRefresh: refreshTokenToUse,
          );
          final refreshedToken = refreshed?.accessToken;
          if (refreshedToken != null && refreshedToken.isNotEmpty) {
            response = await _client
                .put(
                  Uri.parse('${ApiConstants.mobileBaseUrl}/user/profile'),
                  headers: _headersWithToken(headers, refreshedToken),
                  body: jsonEncode({
                    'fullName': updatedUser.fullName,
                    'email': updatedUser.email,
                    'mobile': updatedUser.mobile,
                  }),
                )
                .timeout(const Duration(minutes: 1));
          }
        }
      } catch (error) {
        debugPrint('Unable to refresh token while updating profile: $error');
      }
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String? serverMessage;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          final error = decoded['error'];
          serverMessage = error is Map
              ? error['message']?.toString()
              : decoded['message']?.toString();
        }
      } catch (_) {
        // Keep a safe user-facing fallback for non-JSON error responses.
      }

      final errorText = '${response.body} ${serverMessage ?? ''}'.toLowerCase();
      final isDuplicateMobile =
          response.statusCode == 400 &&
          errorText.contains('mobile') &&
          (errorText.contains('already') ||
              errorText.contains('registered') ||
              errorText.contains('exists') ||
              errorText.contains('duplicate'));

      if (isDuplicateMobile) {
        throw Exception('Mobile number already registered.');
      }

      throw Exception(
        serverMessage?.trim().isNotEmpty == true
            ? serverMessage!.trim()
            : 'Unable to save your profile. Please check your details and try again.',
      );
    }

    _currentUser = updatedUser.copyWith(
      isNewUser: false,
      accessToken: _currentUser?.accessToken ?? updatedUser.accessToken,
      refreshToken: _currentUser?.refreshToken ?? updatedUser.refreshToken,
    );
    await _saveUserToPrefs(_currentUser!);
    return _currentUser!;
  }

  Future<http.Response> _patchWithTokenRefresh(
    Uri uri, {
    required Map<String, String> headers,
    required String? token,
    required String body,
  }) async {
    var response = await _client
        .patch(uri, headers: _headersWithToken(headers, token), body: body)
        .timeout(const Duration(minutes: 1));
    if (response.statusCode != 401 && response.statusCode != 403) {
      return response;
    }

    try {
      final currentToken = _currentUser?.accessToken;
      if (currentToken != null &&
          currentToken.isNotEmpty &&
          currentToken != token &&
          !JwtHelper.isExpired(currentToken)) {
        return await _client
            .patch(
              uri,
              headers: _headersWithToken(headers, currentToken),
              body: body,
            )
            .timeout(const Duration(minutes: 1));
      }

      final refreshed = await refreshToken();
      final refreshedToken = refreshed?.accessToken;
      if (refreshedToken != null && refreshedToken.isNotEmpty) {
        response = await _client
            .patch(
              uri,
              headers: _headersWithToken(headers, refreshedToken),
              body: body,
            )
            .timeout(const Duration(minutes: 1));
      }
    } catch (e) {
      debugPrint('Unable to refresh token while updating subjects: $e');
    }
    return response;
  }

  Map<String, String> _headersWithToken(
    Map<String, String> headers,
    String? token,
  ) {
    final resolved = <String, String>{...headers};
    if (token != null && token.isNotEmpty) {
      resolved['Authorization'] = 'Bearer $token';
    } else {
      resolved.remove('Authorization');
    }
    return resolved;
  }

  @override
  Future<User> updateUserSubjects(
    List<String> subjectIds, {
    String? token,
  }) async {
    final activeToken = token ?? _currentUser?.accessToken;
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final payload = jsonEncode({'areasOfInterest': subjectIds});

    debugPrint('Updating user subjects via PATCH /user/profile: $payload');

    try {
      final response = await _patchWithTokenRefresh(
        Uri.parse(ApiConstants.nativeUserProfile()),
        headers: headers,
        token: _currentUser?.accessToken ?? activeToken,
        body: payload,
      );
      debugPrint(
        'Native user profile PATCH response status: ${response.statusCode}',
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);
        final data = decoded is Map<String, dynamic>
            ? decoded
            : <String, dynamic>{};
        if (data['success'] != true &&
            data['user'] == null &&
            data['data'] == null) {
          throw Exception('Native profile update was not successful.');
        }
        final hasProfilePayload =
            data['user'] is Map || data['data'] is Map || data['id'] != null;
        final parsedUser = hasProfilePayload
            ? User.fromJson(
                data,
                accessToken: _currentUser?.accessToken ?? activeToken,
                refreshToken: _currentUser?.refreshToken,
              )
            : (_currentUser ??
                  User(id: '', fullName: '', accessToken: activeToken));

        // The successful PATCH is authoritative for the selected IDs even
        // when the API returns only {success: true} instead of a full profile.
        _currentUser = parsedUser.copyWith(areasOfInterest: subjectIds);
        await _saveUserToPrefs(_currentUser!);
        return _currentUser!;
      }
    } catch (e) {
      debugPrint('Error patching native profile: $e');
    }

    throw Exception(
      'Unable to update areas of interest through the profile API.',
    );
  }

  @override
  Future<User?> refreshToken({String? tokenToRefresh}) async {
    final existingRefresh = _refreshInFlight;
    if (existingRefresh != null) {
      debugPrint('Joining existing access-token refresh request.');
      return existingRefresh;
    }

    final refreshFuture = _performRefreshToken(tokenToRefresh: tokenToRefresh);
    late final Future<User?> trackedRefresh;
    trackedRefresh = refreshFuture.then(
      (user) {
        if (identical(_refreshInFlight, trackedRefresh)) {
          _refreshInFlight = null;
        }
        return user;
      },
      onError: (Object error, StackTrace stackTrace) {
        if (identical(_refreshInFlight, trackedRefresh)) {
          _refreshInFlight = null;
        }
        Error.throwWithStackTrace(error, stackTrace);
      },
    );
    _refreshInFlight = trackedRefresh;
    return trackedRefresh;
  }

  Future<User?> _performRefreshToken({String? tokenToRefresh}) async {
    // 1. Ensure user profile is loaded from persistent storage if memory is clean
    if (_currentUser == null) {
      await getSavedUser();
    }

    final candidate =
        (tokenToRefresh != null && tokenToRefresh.trim().isNotEmpty)
        ? tokenToRefresh.trim()
        : null;
    final persistedRefreshToken = await _readPersistedRefreshToken();
    final activeRefreshToken =
        candidate ?? _currentUser?.refreshToken ?? persistedRefreshToken;

    if (activeRefreshToken == null || activeRefreshToken.isEmpty) {
      debugPrint('No refreshToken found. Terminating expired session.');
      _currentUser = null;
      await _clearUserFromPrefs();
      _tokenExpiredController.add(true);
      throw const TokenExpiredException(
        'No refresh token available. Please log in again.',
      );
    }

    // Refresh tokens are commonly opaque, so the server remains the source
    // of truth for their seven-day lifetime. If the backend provides a JWT
    // refresh token, avoid making a doomed network request when its expiry is
    // already known locally.
    if (JwtHelper.getExpirationDate(activeRefreshToken) != null &&
        JwtHelper.isExpired(activeRefreshToken, buffer: Duration.zero)) {
      debugPrint('Refresh token is expired. Terminating expired session.');
      _currentUser = null;
      await _clearUserFromPrefs();
      _tokenExpiredController.add(true);
      throw const TokenExpiredException(
        'Session expired. Please log in again.',
      );
    }

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    final payload = jsonEncode({'refreshToken': activeRefreshToken});

    // Native mobile backend endpoints: try primary first, fallback if not found
    final endpoints = [
      ApiConstants.nativeRefreshToken,
      ApiConstants.nativeMobileRefreshToken,
    ];

    http.Response? response;
    Object? lastNetworkException;

    for (final url in endpoints) {
      try {
        debugPrint('----------------------------------------------------');
        debugPrint('🔄 [AUTH] Calling POST $url');
        debugPrint('----------------------------------------------------');

        final res = await _client
            .post(Uri.parse(url), headers: headers, body: payload)
            .timeout(const Duration(seconds: 20));

        debugPrint('====================================================');
        debugPrint('📥 [AUTH] REFRESH TOKEN API RESPONSE from $url:');
        debugPrint('📥 [AUTH] HTTP Status Code: ${res.statusCode}');
        debugPrint(
          '📥 [AUTH] Response Body: ${_redactedResponseBody(res.body)}',
        );
        debugPrint('====================================================');

        response = res;

        // If success (2xx), break out and process tokens
        if (res.statusCode >= 200 && res.statusCode < 300) {
          break;
        }

        // If 404 or 405 (route missing on deployed backend), try next endpoint
        if (res.statusCode == 404 || res.statusCode == 405) {
          debugPrint(
            '⚠️ Refresh endpoint $url returned ${res.statusCode}. Trying alternative route...',
          );
          continue;
        }

        break;
      } catch (e) {
        lastNetworkException = e;
        debugPrint('❌ [AUTH] Native refresh token request to $url failed: $e');
      }
    }

    if (response == null) {
      debugPrint(
        '❌ [AUTH] Refresh token request failed due to network/connectivity error: $lastNetworkException',
      );
      // Do NOT log the user out on temporary network failure!
      throw Exception(
        'Network error during token refresh: $lastNetworkException',
      );
    }

    // Process native response (200 OK / 201 Created)
    if (response.statusCode >= 200 && response.statusCode < 300) {
      try {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;

        final (newAccessToken, newRefreshToken) = _extractTokens(data);

        // Standard: if backend does not rotate refreshToken, keep activeRefreshToken
        final finalRefreshToken =
            (newRefreshToken != null && newRefreshToken.isNotEmpty)
            ? newRefreshToken
            : activeRefreshToken;

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          _currentUser = (_currentUser ?? const User(id: '', fullName: ''))
              .copyWith(
                accessToken: newAccessToken,
                refreshToken: finalRefreshToken,
              );
          await _saveUserToPrefs(_currentUser!);
          debugPrint(
            '✅ Token refreshed successfully. Message: ${data['message'] ?? 'OK'}',
          );
          return _currentUser;
        } else {
          debugPrint(
            '⚠️ Refresh endpoint returned ${response.statusCode} but no access token could be parsed.',
          );
        }
      } catch (parseError) {
        debugPrint('Error parsing refresh token response: $parseError');
      }
    }

    // 4. Handle Token Expiration (401 Unauthorized / 403 Forbidden)
    if (response.statusCode == 401 || response.statusCode == 403) {
      debugPrint(
        'Refresh token rejected by backend (HTTP ${response.statusCode}). Session ended.',
      );
      _currentUser = null;
      await _clearUserFromPrefs();
      _tokenExpiredController.add(true);
      throw const TokenExpiredException(
        'Session expired. Please log in again.',
      );
    }

    // 5. Handle 400 Bad Request or other server errors
    if (response.statusCode >= 400) {
      String errorMessage =
          'Failed to refresh token (HTTP ${response.statusCode})';
      try {
        final errJson = jsonDecode(response.body);
        if (errJson is Map) {
          errorMessage =
              errJson['message']?.toString() ??
              errJson['error']?.toString() ??
              errorMessage;
          final lower = errorMessage.toLowerCase();
          if (lower.contains('token') &&
              (lower.contains('invalid') ||
                  lower.contains('expired') ||
                  lower.contains('revoked'))) {
            _currentUser = null;
            await _clearUserFromPrefs();
            _tokenExpiredController.add(true);
            throw TokenExpiredException(errorMessage);
          }
        }
      } catch (e) {
        if (e is TokenExpiredException) rethrow;
      }
      throw Exception(errorMessage);
    }

    return null;
  }

  Future<String?> _readPersistedRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dedicated = prefs.getString(_refreshTokenPrefsKey);
      if (dedicated != null && dedicated.trim().isNotEmpty) {
        return dedicated.trim();
      }
      final rawSession = prefs.getString(_userPrefsKey);
      if (rawSession == null || rawSession.isEmpty) return null;

      final decoded = jsonDecode(rawSession);
      if (decoded is Map<String, dynamic>) {
        final refreshToken = decoded['refreshToken']?.toString();
        if (refreshToken != null && refreshToken.trim().isNotEmpty) {
          return refreshToken.trim();
        }
      }
    } catch (error) {
      debugPrint('Unable to read persisted refresh token: $error');
    }
    return null;
  }

  @override
  Future<void> signOut() async {
    // The mobile logout endpoint is stateless: it does not require a web
    // session cookie. Send the current bearer token when one is available,
    // but always clear the local session even if the server is unreachable.
    try {
      final token = _currentUser?.accessToken;
      final response = await _client
          .post(
            Uri.parse(ApiConstants.mobileSessionLogout),
            headers: {
              'Accept': 'application/json',
              if (token != null && token.isNotEmpty)
                'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(minutes: 1));
      debugPrint('Mobile logout API status: ${response.statusCode}');
    } catch (error) {
      debugPrint('Mobile logout API warning: $error');
    }

    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    _currentUser = null;
    await _clearUserFromPrefs();
  }
}
