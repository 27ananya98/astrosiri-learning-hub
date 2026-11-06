import 'dart:convert';

/// Utility to inspect and decode JSON Web Tokens (JWT) for token expiration.
class JwtHelper {
  JwtHelper._();

  /// Decodes the payload portion of a JWT without full cryptographic verification.
  static Map<String, dynamic>? decodePayload(String? token) {
    if (token == null || token.isEmpty) return null;
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      var normalizedPayload = parts[1]
          .replaceAll('-', '+')
          .replaceAll('_', '/');
      while (normalizedPayload.length % 4 != 0) {
        normalizedPayload += '=';
      }

      final decodedBytes = base64Decode(normalizedPayload);
      final decodedString = utf8.decode(decodedBytes);
      final dynamic parsed = jsonDecode(decodedString);
      if (parsed is Map<String, dynamic>) {
        return parsed;
      }
    } catch (_) {}
    return null;
  }

  /// Extracts the expiration date [DateTime] (in UTC) from the `exp` claim in the JWT payload.
  /// Handles both standard Unix seconds (10-digit) and milliseconds (13-digit).
  static DateTime? getExpirationDate(String? token) {
    final payload = decodePayload(token);
    if (payload == null || !payload.containsKey('exp')) return null;
    final exp = payload['exp'];
    if (exp is num) {
      // Standard epoch seconds are ~10 digits (e.g. 1.79e9 in 2026).
      // Values >= 100 billion (10^11) are already in milliseconds.
      final expMs = exp > 100000000000 ? exp.round() : (exp * 1000).round();
      return DateTime.fromMillisecondsSinceEpoch(expMs, isUtc: true);
    }
    return null;
  }

  /// Checks if the token has expired or is about to expire within [buffer] window.
  /// Uses strictly UTC comparison to prevent device timezone offset discrepancies.
  static bool isExpired(
    String? token, {
    Duration buffer = const Duration(seconds: 30),
  }) {
    if (token == null || token.isEmpty) return true;
    final expiryDate = getExpirationDate(token);
    if (expiryDate == null) {
      // If token is not standard JWT or has no exp, do not assume expired
      return false;
    }
    return DateTime.now().toUtc().isAfter(expiryDate.subtract(buffer));
  }
}
