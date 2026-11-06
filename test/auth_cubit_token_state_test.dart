import 'package:flutter_test/flutter_test.dart';
import 'package:astro_siri_learning_hub/data/services/auth_service.dart';
import 'package:astro_siri_learning_hub/domain/models/user.dart';
import 'package:astro_siri_learning_hub/domain/repositories/auth_repository.dart';
import 'package:astro_siri_learning_hub/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:astro_siri_learning_hub/features/auth/presentation/cubit/auth_state.dart';

class _SavedSessionRepository implements AuthRepository {
  _SavedSessionRepository(this.user, {this.googleError});

  final User user;
  final Object? googleError;

  @override
  Stream<User> get onUserChanged => const Stream<User>.empty();

  @override
  Stream<bool> get onTokenExpired => const Stream<bool>.empty();

  @override
  Future<User?> getCurrentUser() async => user;

  @override
  Future<User?> refreshToken({String? tokenToRefresh}) async => null;

  @override
  Future<User> loginWithGoogle() async {
    if (googleError != null) throw googleError!;
    return user;
  }

  @override
  Future<User> loginWithApple() => Future.error(UnimplementedError());

  @override
  Future<String> sendOtp(String identifier) =>
      Future.error(UnimplementedError());

  @override
  Future<User> verifyOtp(String identifier, String otp) =>
      Future.error(UnimplementedError());

  @override
  Future<User> updateProfile(User user) => Future.error(UnimplementedError());

  @override
  Future<User> updateUserSubjects(List<String> subjectIds, {String? token}) =>
      Future.error(UnimplementedError());

  @override
  Future<void> logout() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('does not restore an expired session without a refresh token', () async {
    final expiredToken =
        'eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJleHAiOjF9.signature';
    final cubit = AuthCubit(
      authRepository: _SavedSessionRepository(
        User(id: 'user-1', fullName: 'Test User', accessToken: expiredToken),
      ),
    );

    await cubit.checkCurrentUser();

    expect(cubit.state, isA<Unauthenticated>());
    expect(
      (cubit.state as Unauthenticated).message,
      'Session expired. Please log in again.',
    );
    await cubit.close();
  });

  test('shows a safe message when Google auth API fails', () async {
    final cubit = AuthCubit(
      authRepository: _SavedSessionRepository(
        const User(id: 'user-1', fullName: 'Test User'),
        googleError: Exception('HTTP 401: invalid Google credential token'),
      ),
    );

    await cubit.loginWithGoogle();

    expect(cubit.state, isA<AuthError>());
    expect(
      (cubit.state as AuthError).message,
      'Unable to sign in with Google right now. Please try again.',
    );
    await cubit.close();
  });

  test(
    'shows a network message when Google auth cannot reach the API',
    () async {
      final cubit = AuthCubit(
        authRepository: _SavedSessionRepository(
          const User(id: 'user-1', fullName: 'Test User'),
          googleError: Exception('ClientException: Failed host lookup'),
        ),
      );

      await cubit.loginWithGoogle();

      expect(cubit.state, isA<AuthError>());
      expect(
        (cubit.state as AuthError).message,
        'No internet connection. Check your network and try again.',
      );
      await cubit.close();
    },
  );

  test(
    'shows a retry message when Google account re-authentication fails',
    () async {
      final cubit = AuthCubit(
        authRepository: _SavedSessionRepository(
          const User(id: 'user-1', fullName: 'Test User'),
          googleError: const GoogleAuthException(
            'Google account verification failed. Please try again or choose another Google account.',
          ),
        ),
      );

      await cubit.loginWithGoogle();

      expect(cubit.state, isA<AuthError>());
      expect(
        (cubit.state as AuthError).message,
        'Google account verification failed. Please try again or choose another Google account.',
      );
      await cubit.close();
    },
  );
}
