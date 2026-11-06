import '../../domain/models/user.dart';

abstract class AuthRepository {
  Future<User> loginWithGoogle();
  Future<User> loginWithApple();
  Future<String> sendOtp(String identifier);
  Future<User> verifyOtp(String identifier, String otp);
  Future<User> updateProfile(User user);
  Future<User> updateUserSubjects(List<String> subjectIds, {String? token});
  Future<User?> refreshToken({String? tokenToRefresh});
  Stream<bool> get onTokenExpired;
  Stream<User> get onUserChanged;
  Future<void> logout();
  Future<User?> getCurrentUser();
}
