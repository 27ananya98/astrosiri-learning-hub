import 'package:flutter_test/flutter_test.dart';
import 'package:astro_siri_learning_hub/core/constants/app_assets.dart';
import 'package:astro_siri_learning_hub/core/utils/contact_validator.dart';

void main() {
  group('ContactValidator - Phone Number Validation', () {
    test('accepts valid 10-digit phone number', () {
      final res = ContactValidator.validateContactInput('9876543210');
      expect(res.isValid, isTrue);
      expect(res.sanitizedValue, '9876543210');
      expect(res.errorMessage, isNull);
    });

    test('accepts 10-digit phone with +91 or leading 0 prefix and normalizes', () {
      final resWith91 = ContactValidator.validateContactInput('+91 98765 43210');
      expect(resWith91.isValid, isTrue);
      expect(resWith91.sanitizedValue, '9876543210');

      final resWith0 = ContactValidator.validateContactInput('09876543210');
      expect(resWith0.isValid, isTrue);
      expect(resWith0.sanitizedValue, '9876543210');
    });

    test('rejects phone numbers with length less than 10 digits', () {
      final res = ContactValidator.validateContactInput('987654321'); // 9 digits
      expect(res.isValid, isFalse);
      expect(res.errorMessage, 'Mobile number must be exactly 10 digits.');
    });

    test('rejects phone numbers with length greater than 10 digits (without country code)', () {
      final res = ContactValidator.validateContactInput('987654321099'); // 12 digits not starting with 91
      expect(res.isValid, isFalse);
      expect(res.errorMessage, 'Mobile number must be exactly 10 digits.');
    });
  });

  group('ContactValidator - Email Address Validation', () {
    test('accepts valid standard email address', () {
      final res = ContactValidator.validateContactInput('user@example.com');
      expect(res.isValid, isTrue);
      expect(res.sanitizedValue, 'user@example.com');
      expect(res.errorMessage, isNull);
    });

    test('accepts email address with valid characters and subdomains', () {
      final res = ContactValidator.validateContactInput('john.doe+work@sub.company.org');
      expect(res.isValid, isTrue);
      expect(res.sanitizedValue, 'john.doe+work@sub.company.org');
    });

    test('rejects email containing unsupported special characters', () {
      final resWithHash = ContactValidator.validateContactInput('user#name@example.com');
      expect(resWithHash.isValid, isFalse);
      expect(resWithHash.errorMessage, 'Email contains unsupported special characters.');

      final resWithExclamation = ContactValidator.validateContactInput('user!test@example.com');
      expect(resWithExclamation.isValid, isFalse);
      expect(resWithExclamation.errorMessage, 'Email contains unsupported special characters.');
    });

    test('rejects email without @ or with multiple @ symbols', () {
      final noAt = ContactValidator.validateContactInput('invalidemail.com');
      expect(noAt.isValid, isFalse);
      expect(noAt.errorMessage, 'Please enter a valid 10-digit mobile number or email address.');

      final multipleAt = ContactValidator.validateContactInput('user@@example.com');
      expect(multipleAt.isValid, isFalse);
      expect(multipleAt.errorMessage, 'Email address cannot contain multiple @ symbols.');
    });

    test('rejects email with invalid dot placement or invalid domain', () {
      final leadingDot = ContactValidator.validateContactInput('.user@example.com');
      expect(leadingDot.isValid, isFalse);
      expect(leadingDot.errorMessage, 'Email address contains invalid dot placement.');

      final invalidDomain = ContactValidator.validateContactInput('user@invalid');
      expect(invalidDomain.isValid, isFalse);
      expect(invalidDomain.errorMessage, 'Please enter a valid email domain (e.g. example.com).');
    });
  });

  group('ContactValidator - OTP Screen Phone Formatting', () {
    test('formats 10-digit phone number as +91 XXXXX XXXXX', () {
      final formatted = ContactValidator.formatContactForOtp('9876543210');
      expect(formatted, '+91 98765 43210');
    });

    test('formats 12-digit phone with 91 as +91 XXXXX XXXXX', () {
      final formatted = ContactValidator.formatContactForOtp('919876543210');
      expect(formatted, '+91 98765 43210');
    });

    test('formats 11-digit phone with leading 0 as +91 XXXXX XXXXX', () {
      final formatted = ContactValidator.formatContactForOtp('09876543210');
      expect(formatted, '+91 98765 43210');
    });

    test('formats email as lowercase', () {
      final formatted = ContactValidator.formatContactForOtp('User@Example.COM');
      expect(formatted, 'user@example.com');
    });
  });

  group('ContactValidator - OTP Validation', () {
    test('rejects empty OTP', () {
      final res = ContactValidator.validateOtp('');
      expect(res.isValid, isFalse);
      expect(res.errorMessage, 'Please enter the 6-digit verification code.');
    });

    test('rejects incomplete OTP (< 6 digits)', () {
      final res = ContactValidator.validateOtp('1234');
      expect(res.isValid, isFalse);
      expect(res.errorMessage, contains('must be exactly 6 digits'));
      expect(res.errorMessage, contains('4 digits'));
    });

    test('accepts complete 6-digit OTP', () {
      final res = ContactValidator.validateOtp('123456');
      expect(res.isValid, isTrue);
      expect(res.sanitizedValue, '123456');
    });

    test('rejects OTP with non-digit characters', () {
      final res = ContactValidator.validateOtp('12a456');
      expect(res.isValid, isFalse);
      expect(res.errorMessage, 'Verification code must contain digits only.');
    });

    test('rejects OTP longer than 6 digits', () {
      final res = ContactValidator.validateOtp('1234567');
      expect(res.isValid, isFalse);
      expect(res.errorMessage, 'Verification code cannot exceed 6 digits.');
    });
  });

  group('AppAssets Constants and Lotus Asset Path', () {
    test('has valid path for big lotus and app assets', () {
      expect(AppAssets.bigLotus, 'assets/images/icons/big_lotus.png');
      expect(AppAssets.goldenLotus, 'assets/images/icons/golden_lotus.png');
      expect(AppAssets.goldenBook, 'assets/images/icons/golden_book.png');
      expect(AppAssets.numerologyYantra, 'assets/images/icons/numerology_yantra.png');
    });
  });
}
