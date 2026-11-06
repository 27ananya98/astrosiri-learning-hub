import 'package:flutter_test/flutter_test.dart';
import 'package:astro_siri_learning_hub/core/utils/network_error.dart';

void main() {
  group('NetworkErrorUtils', () {
    test('recognizes failed host lookup as an offline error', () {
      const error =
          'ClientException: Failed host lookup: api.example.com (errno = 7)';

      expect(NetworkErrorUtils.isNetworkFailure(error), isTrue);
      expect(
        NetworkErrorUtils.message(error),
        'No internet connection. Check your network and try again.',
      );
    });

    test('recognizes request timeouts as network failures', () {
      expect(NetworkErrorUtils.isNetworkFailure('TimeoutException'), isTrue);
    });

    test('preserves a backend error message', () {
      expect(
        NetworkErrorUtils.message('Invalid verification code.'),
        'Invalid verification code.',
      );
    });
  });
}
