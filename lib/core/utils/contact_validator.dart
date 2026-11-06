// Validation result for contact (mobile / email) and OTP inputs.

/// Validates a mobile number used during first-time profile setup.
///
/// The app accepts exactly ten digits, with an Indian mobile prefix from
/// 6–9, and rejects placeholder values such as 0000000000.
String? validateMobileNumber(String? value) {
  final number = value?.trim() ?? '';
  final hasValidFormat = RegExp(r'^[6-9]\d{9}$').hasMatch(number);
  final isRepeatedDigit = RegExp(r'^(\d)\1{9}$').hasMatch(number);

  if (!hasValidFormat || isRepeatedDigit) {
    return 'Invalid mobile number.';
  }

  return null;
}

class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String sanitizedValue;

  const ValidationResult({
    required this.isValid,
    this.errorMessage,
    required this.sanitizedValue,
  });

  const ValidationResult.success(this.sanitizedValue)
    : isValid = true,
      errorMessage = null;

  const ValidationResult.failure(this.errorMessage, [this.sanitizedValue = ''])
    : isValid = false;
}

class ContactValidator {
  ContactValidator._();

  /// Formats contact input for display on the OTP screen.
  /// Phone numbers are formatted consistently as `+91 XXXXX XXXXX`.
  /// Emails are formatted in lowercase.
  static String formatContactForOtp(String contact) {
    final trimmed = contact.trim();
    if (trimmed.contains('@')) {
      return trimmed.toLowerCase();
    }
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    String tenDigits = digits;
    if (digits.length == 12 && digits.startsWith('91')) {
      tenDigits = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      tenDigits = digits.substring(1);
    }
    if (tenDigits.length == 10) {
      return '+91 ${tenDigits.substring(0, 5)} ${tenDigits.substring(5)}';
    }
    return trimmed;
  }

  /// Validates mobile number or email input.
  /// - Reject empty input
  /// - Reject phone numbers outside required length (must be exactly 10 digits)
  /// - Reject unsupported email special characters
  /// - Reject invalid domain or dot placements
  static ValidationResult validateContactInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const ValidationResult.failure(
        'Please enter your mobile number or email.',
      );
    }

    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    final isLikelyPhone =
        RegExp(r'^[\d\s\+\-\(\)]+$').hasMatch(trimmed) && digitsOnly.isNotEmpty;

    if (isLikelyPhone) {
      return validatePhoneInput(trimmed);
    }

    return _validateEmail(trimmed, genericContactMessage: true);
  }

  /// Validates an email when the Login screen is in Email mode.
  static ValidationResult validateEmailInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const ValidationResult.failure('Please enter your email address.');
    }
    return _validateEmail(trimmed);
  }

  /// Validates a mobile number when the Login screen is in Mobile mode.
  static ValidationResult validatePhoneInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      return const ValidationResult.failure('Please enter your mobile number.');
    }

    if (!RegExp(r'^[\d\s\+\-\(\)]+$').hasMatch(trimmed)) {
      return const ValidationResult.failure(
        'Mobile number must contain digits only.',
      );
    }

    final digitsOnly = trimmed.replaceAll(RegExp(r'\D'), '');
    String normalized = digitsOnly;
    if (digitsOnly.length == 12 && digitsOnly.startsWith('91')) {
      normalized = digitsOnly.substring(2);
    } else if (digitsOnly.length == 11 && digitsOnly.startsWith('0')) {
      normalized = digitsOnly.substring(1);
    }

    if (normalized.length != 10) {
      return ValidationResult.failure(
        'Mobile number must be exactly 10 digits.',
        normalized,
      );
    }

    final mobileError = validateMobileNumber(normalized);
    if (mobileError != null) {
      return ValidationResult.failure(mobileError, normalized);
    }

    return ValidationResult.success(normalized);
  }

  /// Validates the local number entered beside the fixed India (+91) prefix
  /// shown on the Login screen. The field must contain exactly 10 digits.
  static ValidationResult validateLocalPhoneInput(String input) {
    final digits = input.trim();
    if (!RegExp(r'^\d{10}$').hasMatch(digits)) {
      return ValidationResult.failure(
        'Mobile number must be exactly 10 digits.',
        digits,
      );
    }
    final mobileError = validateMobileNumber(digits);
    if (mobileError != null) {
      return ValidationResult.failure(mobileError, digits);
    }
    return ValidationResult.success(digits);
  }

  static ValidationResult _validateEmail(
    String trimmed, {
    bool genericContactMessage = false,
  }) {
    if (!trimmed.contains('@')) {
      return ValidationResult.failure(
        genericContactMessage
            ? 'Please enter a valid 10-digit mobile number or email address.'
            : 'Please enter a valid email address.',
        trimmed,
      );
    }

    final atCount = trimmed.split('@').length - 1;
    if (atCount != 1) {
      return ValidationResult.failure(
        'Email address cannot contain multiple @ symbols.',
        trimmed,
      );
    }

    final parts = trimmed.split('@');
    final localPart = parts[0];
    final domainPart = parts[1];

    if (localPart.isEmpty) {
      return ValidationResult.failure(
        'Email username cannot be empty.',
        trimmed,
      );
    }

    // Reject unsupported special characters in local part
    final unsupportedSpecialChars = RegExp(r'[^a-zA-Z0-9._\-\+]');
    if (unsupportedSpecialChars.hasMatch(localPart)) {
      return ValidationResult.failure(
        'Email contains unsupported special characters.',
        trimmed,
      );
    }

    if (localPart.startsWith('.') ||
        localPart.endsWith('.') ||
        localPart.contains('..')) {
      return ValidationResult.failure(
        'Email address contains invalid dot placement.',
        trimmed,
      );
    }

    final domainRegex = RegExp(
      r'^[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]*[a-zA-Z0-9])?)*\.[a-zA-Z]{2,}$',
    );
    if (!domainRegex.hasMatch(domainPart)) {
      return ValidationResult.failure(
        'Please enter a valid email domain (e.g. example.com).',
        trimmed,
      );
    }

    return ValidationResult.success(trimmed.toLowerCase());
  }

  /// Validates OTP code input.
  /// - Incomplete OTP (< 6 digits or empty)
  /// - Reject OTP longer than 6 digits (> 6 digits)
  /// - Must be digits only
  static ValidationResult validateOtp(String otp) {
    final trimmed = otp.trim();
    if (trimmed.isEmpty) {
      return const ValidationResult.failure(
        'Please enter the 6-digit verification code.',
      );
    }

    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
      return const ValidationResult.failure(
        'Verification code must contain digits only.',
      );
    }

    if (trimmed.length < 6) {
      return ValidationResult.failure(
        'Verification code must be exactly 6 digits (entered ${trimmed.length} digits).',
        trimmed,
      );
    }

    if (trimmed.length > 6) {
      return const ValidationResult.failure(
        'Verification code cannot exceed 6 digits.',
      );
    }

    return ValidationResult.success(trimmed);
  }
}
