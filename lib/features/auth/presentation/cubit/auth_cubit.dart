import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/widgets.dart';
import '../../../../core/utils/jwt_helper.dart';
import '../../../../core/utils/network_error.dart';
import '../../../../data/services/auth_service.dart';
import '../../../../domain/models/user.dart';
import '../../../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> with WidgetsBindingObserver {
  final AuthRepository authRepository;
  StreamSubscription<bool>? _tokenExpiredSubscription;
  StreamSubscription<User>? _userChangedSubscription;
  Timer? _accessTokenRefreshTimer;

  static const Duration _accessTokenRefreshLead = Duration(minutes: 1);
  static const Duration _refreshRetryDelay = Duration(seconds: 30);

  AuthCubit({required this.authRepository}) : super(const AuthInitial()) {
    WidgetsBinding.instance.addObserver(this);
    _tokenExpiredSubscription = authRepository.onTokenExpired.listen((_) {
      debugPrint(
        'AuthCubit received onTokenExpired event. Emitting Unauthenticated.',
      );
      _accessTokenRefreshTimer?.cancel();
      emit(
        const Unauthenticated(message: 'Session expired. Please log in again.'),
      );
    });

    _userChangedSubscription = authRepository.onUserChanged.listen((user) {
      if (user.accessToken != null && user.accessToken!.isNotEmpty) {
        final needsProfileSetup = _checkNeedsProfileSetup(user);
        emit(Authenticated(user: user, needsProfileSetup: needsProfileSetup));
        _scheduleAccessTokenRefresh(user);
      }
    });
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _tokenExpiredSubscription?.cancel();
    _userChangedSubscription?.cancel();
    _accessTokenRefreshTimer?.cancel();
    return super.close();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || isClosed) return;

    final user = currentUser;
    if (user == null) return;

    if (JwtHelper.isExpired(user.accessToken)) {
      _refreshAccessTokenInBackground();
    } else {
      _scheduleAccessTokenRefresh(user);
    }
  }

  void _scheduleAccessTokenRefresh(User user) {
    _accessTokenRefreshTimer?.cancel();
    final expiry = JwtHelper.getExpirationDate(user.accessToken);
    if (expiry == null || user.refreshToken?.isNotEmpty != true) return;

    final refreshAt = expiry.subtract(_accessTokenRefreshLead);
    final delay = refreshAt.difference(DateTime.now().toUtc());
    _accessTokenRefreshTimer = Timer(
      delay.isNegative ? Duration.zero : delay,
      _refreshAccessTokenInBackground,
    );
  }

  Future<void> _refreshAccessTokenInBackground() async {
    if (isClosed || state is! Authenticated) return;

    final refreshedUser = await refreshToken();
    if (refreshedUser == null && !isClosed && state is Authenticated) {
      // A temporary network failure must not log the learner out. Retry soon;
      // a genuine invalid/expired refresh token emits Unauthenticated from
      // the AuthService and cancels this timer through the stream listener.
      _accessTokenRefreshTimer = Timer(
        _refreshRetryDelay,
        _refreshAccessTokenInBackground,
      );
    }
  }

  User? get currentUser =>
      state is Authenticated ? (state as Authenticated).user : null;

  Future<void> checkCurrentUser() async {
    final user = await authRepository.getCurrentUser();
    if (user != null) {
      final expiry = JwtHelper.getExpirationDate(user.accessToken);
      final isExpired = JwtHelper.isExpired(user.accessToken);
      final remaining = expiry?.difference(DateTime.now().toUtc());

      debugPrint('================= 🔑 USER TOKEN STATUS =================');
      debugPrint(
        '👤 User: ${user.id} (${user.fullName.isNotEmpty ? user.fullName : user.mobile ?? user.email ?? "Learner"})',
      );
      debugPrint(
        '⏳ Access Token Expires: ${expiry?.toLocal() ?? "No expiration claim"}',
      );
      if (remaining != null) {
        if (remaining.isNegative) {
          debugPrint('⏱️ Status: Expired ${(-remaining.inMinutes)} mins ago');
        } else {
          debugPrint(
            '⏱️ Status: Valid for ${remaining.inMinutes}m ${remaining.inSeconds % 60}s',
          );
        }
      }
      debugPrint('⚠️ Is Access Token Expired: $isExpired');
      debugPrint(
        '🔄 Has Refresh Token: ${user.refreshToken != null && user.refreshToken!.isNotEmpty}',
      );
      if (user.refreshToken != null && user.refreshToken!.isNotEmpty) {
        final rt = user.refreshToken!;
        final rtPreview = rt.length > 20
            ? '${rt.substring(0, 10)}...${rt.substring(rt.length - 8)}'
            : rt;
        debugPrint('🎟️ Refresh Token: $rtPreview');
      }
      debugPrint('========================================================');

      // Check if access token is expired, and refresh if refreshToken is available
      if (user.refreshToken != null && user.refreshToken!.isNotEmpty) {
        if (JwtHelper.isExpired(user.accessToken)) {
          debugPrint(
            'Active accessToken is expired. Proactively refreshing token...',
          );
          try {
            final refreshedUser = await authRepository.refreshToken();
            if (refreshedUser != null) {
              final needsProfileSetup = _checkNeedsProfileSetup(refreshedUser);
              emit(
                Authenticated(
                  user: refreshedUser,
                  needsProfileSetup: needsProfileSetup,
                ),
              );
              _scheduleAccessTokenRefresh(refreshedUser);
              return;
            }
          } on TokenExpiredException {
            emit(
              const Unauthenticated(
                message: 'Session expired. Please log in again.',
              ),
            );
            return;
          } catch (e) {
            debugPrint('Proactive token refresh error: $e');
          }
        }
      } else if (JwtHelper.isExpired(user.accessToken)) {
        // An expired access token cannot establish an authenticated session
        // without a refresh token. Do not let the app enter the dashboard
        // with a session that every protected request will reject.
        debugPrint(
          'Access token is expired and no refresh token is available. Signing out locally.',
        );
        emit(
          const Unauthenticated(
            message: 'Session expired. Please log in again.',
          ),
        );
        return;
      }

      final needsProfileSetup = _checkNeedsProfileSetup(user);
      emit(Authenticated(user: user, needsProfileSetup: needsProfileSetup));
      _scheduleAccessTokenRefresh(user);
    } else {
      emit(const Unauthenticated());
    }
  }

  Future<User?> refreshToken() async {
    try {
      final refreshedUser = await authRepository.refreshToken();
      if (refreshedUser != null) {
        final needsProfileSetup = _checkNeedsProfileSetup(refreshedUser);
        emit(
          Authenticated(
            user: refreshedUser,
            needsProfileSetup: needsProfileSetup,
          ),
        );
        _scheduleAccessTokenRefresh(refreshedUser);
        return refreshedUser;
      }
    } on TokenExpiredException {
      emit(
        const Unauthenticated(message: 'Session expired. Please log in again.'),
      );
    } catch (e) {
      debugPrint('Error refreshing token in AuthCubit: $e');
    }
    return null;
  }

  void handleTokenExpired([String? message]) {
    emit(
      Unauthenticated(
        message: message ?? 'Session expired. Please log in again.',
      ),
    );
  }

  Future<void> loginWithGoogle() async {
    emit(const AuthLoading(message: 'Authenticating with Google...'));
    try {
      final user = await authRepository.loginWithGoogle();
      final needsProfileSetup = _checkNeedsProfileSetup(user);
      emit(Authenticated(user: user, needsProfileSetup: needsProfileSetup));
      _scheduleAccessTokenRefresh(user);
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (e is GoogleSignInCancelledException ||
          errStr.contains('cancel') ||
          errStr.contains('12501') ||
          errStr.contains('16:') ||
          errStr.contains('no credential') ||
          errStr.contains('popup_closed_by_user')) {
        emit(
          const AuthError(
            'Google sign-in was cancelled. Please try again when you are ready.',
          ),
        );
      } else if (e is GoogleAuthException) {
        emit(AuthError(e.message));
      } else if (NetworkErrorUtils.isNetworkFailure(e)) {
        emit(
          const AuthError(
            'No internet connection. Check your network and try again.',
          ),
        );
      } else {
        // Do not expose backend status codes, raw response bodies, token
        // details, or implementation errors to the learner.
        debugPrint('Google sign-in failed: $e');
        emit(
          const AuthError(
            'Unable to sign in with Google right now. Please try again.',
          ),
        );
      }
    }
  }

  Future<bool> updateUserSubjects(List<String> subjectIds) async {
    try {
      final user = await authRepository.updateUserSubjects(
        subjectIds,
        token: currentUser?.accessToken,
      );
      emit(Authenticated(user: user, needsProfileSetup: false));
      _scheduleAccessTokenRefresh(user);
      return true;
    } catch (e) {
      emit(AuthError(e.toString()));
      return false;
    }
  }

  Future<void> sendOtp(String identifier) async {
    if (identifier.trim().isEmpty) {
      emit(const AuthError('Please enter your mobile number or email.'));
      return;
    }

    emit(const AuthLoading(message: 'Sending verification code...'));
    try {
      final message = await authRepository.sendOtp(identifier.trim());
      emit(AuthOtpSent(identifier: identifier.trim(), message: message));
    } catch (e) {
      emit(
        AuthError(
          NetworkErrorUtils.message(
            e,
            fallback: 'Failed to send verification code.',
          ),
        ),
      );
    }
  }

  Future<void> verifyOtp(String identifier, String otp) async {
    if (otp.trim().isEmpty) {
      emit(const AuthError('Please enter the verification code.'));
      return;
    }

    emit(const AuthLoading(message: 'Verifying code...'));
    try {
      final user = await authRepository.verifyOtp(
        identifier.trim(),
        otp.trim(),
      );
      final needsProfileSetup = _checkNeedsProfileSetup(user);
      emit(Authenticated(user: user, needsProfileSetup: needsProfileSetup));
      _scheduleAccessTokenRefresh(user);
    } catch (e) {
      emit(
        AuthError(
          NetworkErrorUtils.message(
            e,
            fallback: 'The verification code entered is incorrect.',
          ),
        ),
      );
    }
  }

  Future<void> updateProfile(User updatedUser) async {
    emit(const AuthLoading(message: 'Updating profile...'));
    try {
      final user = await authRepository.updateProfile(updatedUser);
      emit(Authenticated(user: user, needsProfileSetup: false));
      _scheduleAccessTokenRefresh(user);
    } catch (e) {
      emit(
        AuthError(
          NetworkErrorUtils.message(
            e,
            fallback: 'Unable to save your profile.',
          ),
        ),
      );
    }
  }

  Future<void> logout() async {
    emit(const AuthLoading(message: 'Logging out...'));
    try {
      await authRepository.logout();
      _accessTokenRefreshTimer?.cancel();
      emit(const Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  bool _checkNeedsProfileSetup(User user) {
    return user.isNewUser ||
        user.fullName.isEmpty ||
        user.fullName == 'Learner' ||
        (user.mobile == null || user.mobile!.isEmpty) ||
        (user.email == null || user.email!.isEmpty);
  }
}
