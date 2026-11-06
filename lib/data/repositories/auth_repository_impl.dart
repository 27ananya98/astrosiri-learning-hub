import '../../domain/models/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../services/auth_service.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthService _authService;

  AuthRepositoryImpl({AuthService? authService})
    : _authService = authService ?? ApiAuthService();

  @override
  Future<User> loginWithGoogle() => _authService.signInWithGoogle();

  @override
  Future<User> loginWithApple() => _authService.signInWithApple();

  @override
  Future<String> sendOtp(String identifier) => _authService.sendOtp(identifier);

  @override
  Future<User> verifyOtp(String identifier, String otp) =>
      _authService.verifyOtp(identifier, otp);

  @override
  Future<User> updateProfile(User user) => _authService.updateProfile(user);

  @override
  Future<User> updateUserSubjects(List<String> subjectIds, {String? token}) =>
      _authService.updateUserSubjects(subjectIds, token: token);

  @override
  Future<User?> refreshToken({String? tokenToRefresh}) =>
      _authService.refreshToken(tokenToRefresh: tokenToRefresh);

  @override
  Stream<bool> get onTokenExpired => _authService.onTokenExpired;

  @override
  Stream<User> get onUserChanged => _authService.onUserChanged;

  @override
  Future<void> logout() => _authService.signOut();

  @override
  Future<User?> getCurrentUser() => _authService.getSavedUser();
}
