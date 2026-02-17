import 'package:flutter_test/flutter_test.dart';
import 'package:my_circle/core/validation/input_validator.dart';

void main() {
  group('InputValidator', () {
    group('isValidEmail', () {
      test('should return true for valid email', () {
        expect(InputValidator.isValidEmail('test@example.com'), isTrue);
        expect(InputValidator.isValidEmail('user.name+tag@domain.co.uk'), isTrue);
        expect(InputValidator.isValidEmail('user123@test-domain.com'), isTrue);
      });

      test('should return false for invalid email', () {
        expect(InputValidator.isValidEmail(''), isFalse);
        expect(InputValidator.isValidEmail('invalid-email'), isFalse);
        expect(InputValidator.isValidEmail('@domain.com'), isFalse);
        expect(InputValidator.isValidEmail('user@'), isFalse);
        expect(InputValidator.isValidEmail('user..name@domain.com'), isFalse);
      });
    });

    group('validatePassword', () {
      test('should validate strong password', () {
        const password = 'StrongP@ssw0rd123!';
        final result = InputValidator.validatePassword(password);

        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
        expect(result.strength, equals(PasswordStrength.strong));
      });

      test('should reject empty password', () {
        const password = '';
        final result = InputValidator.validatePassword(password);

        expect(result.isValid, isFalse);
        expect(result.errors, contains('Password cannot be empty'));
        expect(result.strength, equals(PasswordStrength.none));
      });

      test('should reject weak password', () {
        const password = 'weak';
        final result = InputValidator.validatePassword(password);

        expect(result.isValid, isFalse);
        expect(result.errors, contains('Password must be at least 8 characters'));
        expect(result.errors, contains('Password must contain uppercase letters'));
        expect(result.errors, contains('Password must contain numbers'));
        expect(result.errors, contains('Password must contain special characters'));
      });

      test('should reject common password', () {
        const password = 'password123';
        final result = InputValidator.validatePassword(password);

        expect(result.isValid, isFalse);
        expect(result.errors, contains('Password is too common'));
      });

      test('should provide suggestions for improvement', () {
        const password = 'GoodPassword123';
        final result = InputValidator.validatePassword(password);

        expect(result.isValid, isTrue);
        expect(result.suggestions, contains('Consider using 12+ characters for better security'));
      });
    });

    group('validateUsername', () {
      test('should validate correct username', () {
        const username = 'valid_user123';
        final result = InputValidator.validateUsername(username);

        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should reject empty username', () {
        const username = '';
        final result = InputValidator.validateUsername(username);

        expect(result.isValid, isFalse);
        expect(result.errors, contains('Username cannot be empty'));
      });

      test('should reject short username', () {
        const username = 'ab';
        final result = InputValidator.validateUsername(username);

        expect(result.isValid, isFalse);
        expect(result.errors, contains('Username must be at least 3 characters'));
      });

      test('should reject long username', () {
        const username = 'very_long_username_that_exceeds_limit';
        final result = InputValidator.validateUsername(username);

        expect(result.isValid, isFalse);
        expect(result.errors, contains('Username cannot exceed 20 characters'));
      });

      test('should reject username with invalid characters', () {
        const username = 'user@name';
        final result = InputValidator.validateUsername(username);

        expect(result.isValid, isFalse);
        expect(result.errors, contains('Username can only contain letters, numbers, underscores, and hyphens'));
      });

      test('should reject username starting with underscore', () {
        const username = '_username';
        final result = InputValidator.validateUsername(username);

        expect(result.isValid, isFalse);
        expect(result.errors, contains('Username cannot start with underscore or hyphen'));
      });

      test('should reject reserved username', () {
        const username = 'admin';
        final result = InputValidator.validateUsername(username);

        expect(result.isValid, isFalse);
        expect(result.errors, contains('Username is not allowed'));
      });
    });

    group('isValidUrl', () {
      test('should return true for valid URLs', () {
        expect(InputValidator.isValidUrl('https://example.com'), isTrue);
        expect(InputValidator.isValidUrl('http://test.domain.org'), isTrue);
        expect(InputValidator.isValidUrl('https://sub.domain.co.uk/path'), isTrue);
      });

      test('should return false for invalid URLs', () {
        expect(InputValidator.isValidUrl(''), isFalse);
        expect(InputValidator.isValidUrl('not-a-url'), isFalse);
        expect(InputValidator.isValidUrl('ftp://example.com'), isFalse);
        expect(InputValidator.isValidUrl('www.example.com'), isFalse);
      });
    });

    group('isValidPhoneNumber', () {
      test('should return true for valid phone numbers', () {
        expect(InputValidator.isValidPhoneNumber('+1234567890'), isTrue);
        expect(InputValidator.isValidPhoneNumber('(123) 456-7890'), isTrue);
        expect(InputValidator.isValidPhoneNumber('123 456 7890'), isTrue);
      });

      test('should return false for invalid phone numbers', () {
        expect(InputValidator.isValidPhoneNumber(''), isFalse);
        expect(InputValidator.isValidPhoneNumber('123'), isFalse);
        expect(InputValidator.isValidPhoneNumber('abc-def-ghij'), isFalse);
      });
    });

    group('validateText', () {
      test('should validate required text field', () {
        final result = InputValidator.validateText(
          'Some text',
          fieldName: 'Description',
          required: true,
        );

        expect(result.isValid, isTrue);
        expect(result.errors, isEmpty);
      });

      test('should reject empty required field', () {
        final result = InputValidator.validateText(
          '',
          fieldName: 'Description',
          required: true,
        );

        expect(result.isValid, isFalse);
        expect(result.errors, contains('Description is required'));
      });

      test('should validate text length constraints', () {
        final result = InputValidator.validateText(
          'Short',
          fieldName: 'Content',
          minLength: 10,
          maxLength: 100,
        );

        expect(result.isValid, isFalse);
        expect(result.errors, contains('Content must be at least 10 characters'));
      });

      test('should validate pattern matching', () {
        final result = InputValidator.validateText(
          'ABC123',
          fieldName: 'Code',
          pattern: r'^[A-Z]{2}\d{4}$',
        );

        expect(result.isValid, isFalse);
        expect(result.errors, contains('Code contains invalid characters'));
      });
    });

    group('sanitizeInput', () {
      test('should remove HTML tags', () {
        const input = '<script>alert("xss")</script>Hello World';
        final result = InputValidator.sanitizeInput(input);

        expect(result, equals('Hello World'));
      });

      test('should trim whitespace', () {
        const input = '  Hello World  ';
        final result = InputValidator.sanitizeInput(input);

        expect(result, equals('Hello World'));
      });
    });

    group('containsSqlInjection', () {
      test('should detect SQL injection patterns', () {
        expect(InputValidator.containsSqlInjection("'; DROP TABLE users; --"), isTrue);
        expect(InputValidator.containsSqlInjection("' OR '1'='1"), isTrue);
        expect(InputValidator.containsSqlInjection("UNION SELECT * FROM users"), isTrue);
        expect(InputValidator.containsSqlInjection("'; INSERT INTO users"), isTrue);
      });

      test('should not flag safe input', () {
        expect(InputValidator.containsSqlInjection("John Doe"), isFalse);
        expect(InputValidator.containsSqlInjection("Hello, world!"), isFalse);
        expect(InputValidator.containsSqlInjection("user@example.com"), isFalse);
      });
    });

    group('containsXss', () {
      test('should detect XSS patterns', () {
        expect(InputValidator.containsXss("<script>alert('xss')</script>"), isTrue);
        expect(InputValidator.containsXss("javascript:alert('xss')"), isTrue);
        expect(InputValidator.containsXss("<img src='x' onerror='alert(1)'>"), isTrue);
        expect(InputValidator.containsXss("<iframe src='evil.com'></iframe>"), isTrue);
      });

      test('should not flag safe input', () {
        expect(InputValidator.containsXss("Hello, world!"), isFalse);
        expect(InputValidator.containsXss("This is <b>bold</b> text"), isFalse);
        expect(InputValidator.containsXss("user@example.com"), isFalse);
      });
    });
  });
}
