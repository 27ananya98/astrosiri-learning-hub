import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:astro_siri_learning_hub/core/utils/jwt_helper.dart';
import 'package:astro_siri_learning_hub/data/services/auth_service.dart';
import 'package:astro_siri_learning_hub/domain/models/user.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('JwtHelper Tests', () {
    test('Correctly identifies expired token', () {
      final pastTimestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 3600; // 1 hour ago
      final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
      final payload = base64Url.encode(utf8.encode(jsonEncode({'sub': '123', 'exp': pastTimestamp})));
      final token = '$header.$payload.signature';

      expect(JwtHelper.isExpired(token), isTrue);
    });

    test('Correctly identifies valid unexpired token', () {
      final futureTimestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600; // 1 hour in future
      final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
      final payload = base64Url.encode(utf8.encode(jsonEncode({'sub': '123', 'exp': futureTimestamp})));
      final token = '$header.$payload.signature';

      expect(JwtHelper.isExpired(token), isFalse);
    });

    test('Treats null or empty token as expired', () {
      expect(JwtHelper.isExpired(null), isTrue);
      expect(JwtHelper.isExpired(''), isTrue);
    });
  });

  group('Token Refresh & Expiry Handling Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Successfully refreshes token via POST /api/v1/auth/refresh-token', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, contains('/auth/refresh-token'));
        expect(request.headers['Content-Type'], 'application/json');

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['refreshToken'], 'valid_refresh_token_123');

        return http.Response(
          jsonEncode({
            'success': true,
            'message': 'Token refreshed successfully.',
            'accessToken': 'new_access_token_xyz',
            'refreshToken': 'new_refresh_token_456',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = ApiAuthService(client: mockClient);
      final refreshedUser = await authService.refreshToken(tokenToRefresh: 'valid_refresh_token_123');

      expect(refreshedUser, isNotNull);
      expect(refreshedUser!.accessToken, 'new_access_token_xyz');
      expect(refreshedUser.refreshToken, 'new_refresh_token_456');
    });

    test('Throws TokenExpiredException and clears session on 401 Unauthorized', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': false,
            'message': 'Refresh token has expired or is invalid.',
          }),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = ApiAuthService(client: mockClient);
      bool tokenExpiredEventReceived = false;
      authService.onTokenExpired.listen((_) {
        tokenExpiredEventReceived = true;
      });

      expect(
        () => authService.refreshToken(tokenToRefresh: 'expired_refresh_token'),
        throwsA(isA<TokenExpiredException>()),
      );

      // Allow microtask queue to process broadcast stream event
      await Future.delayed(const Duration(milliseconds: 10));
      expect(tokenExpiredEventReceived, isTrue);
      expect(authService.currentUser, isNull);
    });

    test('Successfully parses nested tokens format { data: { tokens: { accessToken, refreshToken } } }', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'tokens': {
                'accessToken': 'nested_access_token',
                'refreshToken': 'nested_refresh_token',
              },
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = ApiAuthService(client: mockClient);
      final refreshedUser = await authService.refreshToken(tokenToRefresh: 'active_rt');

      expect(refreshedUser, isNotNull);
      expect(refreshedUser!.accessToken, 'nested_access_token');
      expect(refreshedUser.refreshToken, 'nested_refresh_token');
    });

    test('Preserves existing refresh token when backend only returns new accessToken', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'success': true,
            'accessToken': 'just_access_token',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = ApiAuthService(client: mockClient);
      final refreshedUser = await authService.refreshToken(tokenToRefresh: 'original_refresh_token');

      expect(refreshedUser, isNotNull);
      expect(refreshedUser!.accessToken, 'just_access_token');
      expect(refreshedUser.refreshToken, 'original_refresh_token');
    });

    test('Successfully handles snake_case access_token and refresh_token', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'access_token': 'snake_access_token',
            'refresh_token': 'snake_refresh_token',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = ApiAuthService(client: mockClient);
      final refreshedUser = await authService.refreshToken(tokenToRefresh: 'active_rt');

      expect(refreshedUser, isNotNull);
      expect(refreshedUser!.accessToken, 'snake_access_token');
      expect(refreshedUser.refreshToken, 'snake_refresh_token');
    });

    test('Retries profile save with a refreshed access token after 401', () async {
      final requests = <http.Request>[];
      final mockClient = MockClient((request) async {
        requests.add(request);

        if (request.method == 'PUT') {
          if (requests.where((item) => item.method == 'PUT').length == 1) {
            return http.Response('{}', 401);
          }
          expect(request.headers['authorization'], 'Bearer refreshed_access');
          return http.Response('{}', 200);
        }

        expect(request.method, 'POST');
        expect(request.url.path, contains('/auth/refresh-token'));
        return http.Response(
          jsonEncode({
            'success': true,
            'accessToken': 'refreshed_access',
            'refreshToken': 'refreshed_refresh',
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = ApiAuthService(client: mockClient);
      final savedUser = await authService.updateProfile(
        const User(
          id: 'user-1',
          fullName: 'Test User',
          mobile: '6387052463',
          accessToken: 'old_access',
          refreshToken: 'active_refresh',
        ),
      );

      expect(requests.map((request) => request.method), ['PUT', 'POST', 'PUT']);
      expect(savedUser.accessToken, 'refreshed_access');
      expect(savedUser.refreshToken, 'refreshed_refresh');
    });

    test('Throws TokenExpiredException when 400 Bad Request indicates invalid token', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'message': 'Invalid or expired refresh token provided',
          }),
          400,
          headers: {'content-type': 'application/json'},
        );
      });

      final authService = ApiAuthService(client: mockClient);
      bool expiredFired = false;
      authService.onTokenExpired.listen((_) => expiredFired = true);

      expect(
        () => authService.refreshToken(tokenToRefresh: 'some_bad_token'),
        throwsA(isA<TokenExpiredException>()),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(expiredFired, isTrue);
    });

    test('Throws TokenExpiredException when no refresh token is available', () async {
      final mockClient = MockClient((request) async => http.Response('{}', 200));
      final authService = ApiAuthService(client: mockClient);

      expect(
        () => authService.refreshToken(tokenToRefresh: null),
        throwsA(isA<TokenExpiredException>()),
      );
    });

    test('Rejects an already expired JWT refresh token before network access', () async {
      var requestWasSent = false;
      final mockClient = MockClient((request) async {
        requestWasSent = true;
        return http.Response('{}', 200);
      });
      final authService = ApiAuthService(client: mockClient);
      const expiredRefreshToken =
          'eyJhbGciOiJub25lIiwidHlwIjoiSldUIn0.eyJleHAiOjF9.signature';

      expect(
        () => authService.refreshToken(tokenToRefresh: expiredRefreshToken),
        throwsA(isA<TokenExpiredException>()),
      );
      expect(requestWasSent, isFalse);
    });

    test('Temporary network error does NOT clear user session or fire onTokenExpired', () async {
      final mockClient = MockClient((request) async {
        throw http.ClientException('Connection failed');
      });

      final authService = ApiAuthService(client: mockClient);
      bool expiredFired = false;
      authService.onTokenExpired.listen((_) => expiredFired = true);

      // Verify exception thrown is a regular Exception (not TokenExpiredException)
      expect(
        () => authService.refreshToken(tokenToRefresh: 'some_valid_looking_token'),
        throwsA(isNot(isA<TokenExpiredException>())),
      );

      await Future.delayed(const Duration(milliseconds: 10));
      expect(expiredFired, isFalse);
    });

    test('JwtHelper correctly parses millisecond-based (13-digit) exp timestamps', () {
      final futureMs = DateTime.now().millisecondsSinceEpoch + 3600000;
      final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'HS256', 'typ': 'JWT'})));
      final payload = base64Url.encode(utf8.encode(jsonEncode({'sub': '123', 'exp': futureMs})));
      final token = '$header.$payload.signature';

      expect(JwtHelper.isExpired(token), isFalse);
    });
  });
}
