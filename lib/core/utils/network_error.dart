/// Converts transport failures into short, user-facing messages without
/// requiring a platform-specific connectivity package.
class NetworkErrorUtils {
  static bool isNetworkFailure(Object error) {
    final value = error.toString().toLowerCase();
    return value.contains('socketexception') ||
        value.contains('clientexception') ||
        value.contains('failed host lookup') ||
        value.contains('no address associated with hostname') ||
        value.contains('network is unreachable') ||
        value.contains('connection refused') ||
        value.contains('connection reset') ||
        value.contains('connection closed') ||
        value.contains('connection aborted') ||
        value.contains('timed out') ||
        value.contains('timeout');
  }

  static String message(
    Object error, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    if (isNetworkFailure(error)) {
      return 'No internet connection. Check your network and try again.';
    }

    final raw = error.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
    return raw.trim().isEmpty ? fallback : raw.trim();
  }
}
