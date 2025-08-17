import 'package:test/test.dart';
import 'package:resx/src/validation.dart';

void main() {
  group('Validation', () {
    group('creation', () {
      test('Valid creates valid validation', () {
        const validation = Validation.valid(42);
        expect(validation.isValid, isTrue);
        expect(validation.isInvalid, isFalse);
        expect(validation.value, equals(42));
      });

      test('Invalid creates invalid validation', () {
        const validation = Validation<String, int>.invalid(['error']);
        expect(validation.isInvalid, isTrue);
        expect(validation.isValid, isFalse);
        expect(validation.errors, equals(['error']));
      });

      test('invalidSingle creates invalid validation with single error', () {
        final validation = Validation<String, int>.invalidSingle('error');
        expect(validation.isInvalid, isTrue);
        expect(validation.errors, equals(['error']));
      });

      test('from creates Valid for successful computation', () {
        final validation = Validation.from(() => int.parse('42'));
        expect(validation.isValid, isTrue);
        expect(validation.value, equals(42));
      });

      test('from creates Invalid for failing computation', () {
        final validation = Validation.from(() => int.parse('invalid'));
        expect(validation.isInvalid, isTrue);
        expect(validation.errors.length, equals(1));
      });
    });

    group('mapping', () {
      test('map transforms Valid value', () {
        const validation = Validation.valid(5);
        final mapped = validation.map((x) => x * 2);
        expect(mapped.isValid, isTrue);
        expect(mapped.value, equals(10));
      });

      test('map does nothing to Invalid', () {
        const validation = Validation<String, int>.invalid(['error']);
        final mapped = validation.map((x) => x * 2);
        expect(mapped.isInvalid, isTrue);
        expect(mapped.errors, equals(['error']));
      });

      test('flatMap transforms Valid value', () {
        const validation = Validation.valid(5);
        final mapped = validation.flatMap((x) => Validation.valid(x * 2));
        expect(mapped.isValid, isTrue);
        expect(mapped.value, equals(10));
      });

      test('flatMap preserves errors', () {
        const validation = Validation<String, int>.invalid(['error1']);
        final mapped = validation
            .flatMap((x) => const Validation<String, int>.invalid(['error2']));
        expect(mapped.isInvalid, isTrue);
        expect(mapped.errors, equals(['error1']));
      });

      test('mapErrors transforms error values', () {
        const validation = Validation<String, int>.invalid(['error']);
        final mapped = validation.mapErrors((e) => 'prefix: $e');
        expect(mapped.isInvalid, isTrue);
        expect(mapped.errors, equals(['prefix: error']));
      });
    });

    group('combining', () {
      test('zip accumulates errors from both Invalid validations', () {
        const validation1 = Validation<String, int>.invalid(['error1']);
        const validation2 = Validation<String, String>.invalid(['error2']);
        final result = validation1.zip(validation2, (a, b) => '$a$b');
        expect(result.isInvalid, isTrue);
        expect(result.errors, containsAll(['error1', 'error2']));
      });

      test('zip returns Invalid when only first is Valid', () {
        const validation1 = Validation.valid(1);
        const validation2 = Validation<String, String>.invalid(['error2']);
        final result = validation1.zip(validation2, (a, b) => '$a$b');
        expect(result.isInvalid, isTrue);
        expect(result.errors, equals(['error2']));
      });

      test('zip returns Valid when both are Valid', () {
        const validation1 = Validation.valid(1);
        const validation2 = Validation.valid('hello');
        final result = validation1.zip(validation2, (a, b) => '$a$b');
        expect(result.isValid, isTrue);
        expect(result.value, equals('1hello'));
      });

      test('zipWith is alias for zip', () {
        const validation1 = Validation.valid(1);
        const validation2 = Validation.valid(2);
        final result = validation1.zipWith(validation2, (a, b) => a + b);
        expect(result.isValid, isTrue);
        expect(result.value, equals(3));
      });
    });

    group('folding', () {
      test('fold transforms Valid value', () {
        const validation = Validation.valid(5);
        final result = validation.fold((x) => x * 2, (errors) => 0);
        expect(result, equals(10));
      });

      test('fold uses error handler for Invalid', () {
        const validation = Validation<String, int>.invalid(['error']);
        final result = validation.fold((x) => x * 2, (errors) => errors.length);
        expect(result, equals(1));
      });

      test('valueOr returns value for Valid', () {
        const validation = Validation.valid(5);
        final result = validation.valueOr(0);
        expect(result, equals(5));
      });

      test('valueOr returns default for Invalid', () {
        const validation = Validation<String, int>.invalid(['error']);
        final result = validation.valueOr(0);
        expect(result, equals(0));
      });

      test('valueOrElse returns value for Valid', () {
        const validation = Validation.valid(5);
        final result = validation.valueOrElse((errors) => 0);
        expect(result, equals(5));
      });

      test('valueOrElse returns computed default for Invalid', () {
        const validation = Validation<String, int>.invalid(['error']);
        final result = validation.valueOrElse((errors) => errors.length);
        expect(result, equals(1));
      });
    });

    group('tapping', () {
      test('tap calls function for Valid', () {
        var called = false;
        const validation = Validation.valid(5);
        final result = validation.tap((x) => called = true);
        expect(called, isTrue);
        expect(result, equals(validation));
      });

      test('tap does nothing for Invalid', () {
        var called = false;
        const validation = Validation<String, int>.invalid(['error']);
        final result = validation.tap((x) => called = true);
        expect(called, isFalse);
        expect(result, equals(validation));
      });

      test('tapErrors calls function for Invalid', () {
        var called = false;
        const validation = Validation<String, int>.invalid(['error']);
        final result = validation.tapErrors((errors) => called = true);
        expect(called, isTrue);
        expect(result, equals(validation));
      });

      test('tapErrors does nothing for Valid', () {
        var called = false;
        const validation = Validation.valid(5);
        final result = validation.tapErrors((errors) => called = true);
        expect(called, isFalse);
        expect(result, equals(validation));
      });
    });

    group('matching', () {
      test('match calls onValid for Valid', () {
        var result = '';
        const validation = Validation.valid(42);
        validation.match((value) => result = 'valid: $value',
            (errors) => result = 'invalid');
        expect(result, equals('valid: 42'));
      });

      test('match calls onInvalid for Invalid', () {
        var result = '';
        const validation = Validation<String, int>.invalid(['error']);
        validation.match((value) => result = 'valid',
            (errors) => result = 'invalid: ${errors.length}');
        expect(result, equals('invalid: 1'));
      });
    });

    group('conversion', () {
      test('toResult returns Ok for Valid', () {
        const validation = Validation.valid(5);
        final result = validation.toResult();
        expect(result.isOk, isTrue);
        expect(result.value, equals(5));
      });

      test('toResult returns Err with first error for Invalid', () {
        const validation =
            Validation<String, int>.invalid(['error1', 'error2']);
        final result = validation.toResult();
        expect(result.isErr, isTrue);
        expect(result.error, equals('error1'));
      });

      test('toResultAll returns Ok for Valid', () {
        const validation = Validation.valid(5);
        final result = validation.toResultAll();
        expect(result.isOk, isTrue);
        expect(result.value, equals(5));
      });

      test('toResultAll returns Err with all errors for Invalid', () {
        const validation =
            Validation<String, int>.invalid(['error1', 'error2']);
        final result = validation.toResultAll();
        expect(result.isErr, isTrue);
        expect(result.error, equals(['error1', 'error2']));
      });

      test('toNullable returns value for Valid', () {
        const validation = Validation.valid(5);
        final nullable = validation.toNullable();
        expect(nullable, equals(5));
      });

      test('toNullable returns null for Invalid', () {
        const validation = Validation<String, int>.invalid(['error']);
        final nullable = validation.toNullable();
        expect(nullable, isNull);
      });

      test('toList returns list with value for Valid', () {
        const validation = Validation.valid(5);
        final list = validation.toList();
        expect(list, equals([5]));
      });

      test('toList returns empty list for Invalid', () {
        const validation = Validation<String, int>.invalid(['error']);
        final list = validation.toList();
        expect(list, isEmpty);
      });
    });

    group('equality and hash', () {
      test('Valid values are equal when values are equal', () {
        const validation1 = Validation.valid(5);
        const validation2 = Validation.valid(5);
        expect(validation1, equals(validation2));
        expect(validation1.hashCode, equals(validation2.hashCode));
      });

      test('Valid values are not equal when values differ', () {
        const validation1 = Validation.valid(5);
        const validation2 = Validation.valid(10);
        expect(validation1, isNot(equals(validation2)));
      });

      test('Invalid values are equal when errors are equal', () {
        const validation1 = Validation<String, int>.invalid(['error']);
        const validation2 = Validation<String, int>.invalid(['error']);
        expect(validation1, equals(validation2));
        expect(validation1.hashCode, equals(validation2.hashCode));
      });

      test('Valid and Invalid are not equal', () {
        const validation1 = Validation.valid(5);
        const validation2 = Validation<String, int>.invalid(['error']);
        expect(validation1, isNot(equals(validation2)));
      });
    });

    group('toString', () {
      test('Valid toString includes value', () {
        const validation = Validation.valid(5);
        expect(validation.toString(), equals('Valid(5)'));
      });

      test('Invalid toString includes errors', () {
        const validation =
            Validation<String, int>.invalid(['error1', 'error2']);
        expect(validation.toString(), equals('Invalid([error1, error2])'));
      });
    });
  });

  group('Validations utility', () {
    test('combine returns Valid list when all are Valid', () {
      final validations = [
        const Validation.valid(1),
        const Validation.valid(2),
        const Validation.valid(3),
      ];
      final result = Validations.combine(validations);
      expect(result.isValid, isTrue);
      expect(result.value, equals([1, 2, 3]));
    });

    test('combine accumulates all errors', () {
      final validations = [
        const Validation<String, int>.invalid(['error1']),
        const Validation<String, int>.invalid(['error2']),
        const Validation.valid(3),
      ];
      final result = Validations.combine(validations);
      expect(result.isInvalid, isTrue);
      expect(result.errors, containsAll(['error1', 'error2']));
    });

    test('traverse validates all elements', () {
      final values = [1, 2, 3];
      final result = Validations.traverse(
        values,
        (x) => x.validate((n) => n > 0, 'must be positive'),
      );
      expect(result.isValid, isTrue);
      expect(result.value, equals([1, 2, 3]));
    });

    test('traverse accumulates all errors', () {
      final values = [-1, 0, 1];
      final result = Validations.traverse(
        values,
        (x) => x.validate((n) => n > 0, 'must be positive'),
      );
      expect(result.isInvalid, isTrue);
      expect(result.errors.length, equals(2)); // -1 and 0 fail
    });

    test('lift2 combines two Valid values', () {
      const a = Validation.valid(2);
      const b = Validation.valid(3);
      final result = Validations.lift2(a, b, (x, y) => x + y);
      expect(result.isValid, isTrue);
      expect(result.value, equals(5));
    });

    test('lift2 accumulates errors when any is Invalid', () {
      const a = Validation<String, int>.invalid(['error1']);
      const b = Validation<String, int>.invalid(['error2']);
      final result = Validations.lift2(a, b, (x, y) => x + y);
      expect(result.isInvalid, isTrue);
      expect(result.errors, containsAll(['error1', 'error2']));
    });

    test('lift3 combines three Valid values', () {
      const a = Validation.valid(1);
      const b = Validation.valid(2);
      const c = Validation.valid(3);
      final result = Validations.lift3(a, b, c, (x, y, z) => x + y + z);
      expect(result.isValid, isTrue);
      expect(result.value, equals(6));
    });

    test('lift3 accumulates all errors', () {
      const a = Validation<String, int>.invalid(['error1']);
      const b = Validation.valid(2);
      const c = Validation<String, int>.invalid(['error3']);
      final result = Validations.lift3(a, b, c, (x, y, z) => x + y + z);
      expect(result.isInvalid, isTrue);
      expect(result.errors, containsAll(['error1', 'error3']));
    });
  });

  group('Validators utility', () {
    test('notNull validates non-null values', () {
      final result = Validators.notNull('test');
      expect(result.isValid, isTrue);
      expect(result.value, equals('test'));
    });

    test('notNull fails for null values', () {
      final result = Validators.notNull(null, 'field is required');
      expect(result.isInvalid, isTrue);
      expect(result.errors, equals(['field is required']));
    });

    test('notEmpty validates non-empty strings', () {
      final result = Validators.notEmpty('test');
      expect(result.isValid, isTrue);
      expect(result.value, equals('test'));
    });

    test('notEmpty fails for empty strings', () {
      final result = Validators.notEmpty('', 'field cannot be empty');
      expect(result.isInvalid, isTrue);
      expect(result.errors, equals(['field cannot be empty']));
    });

    test('minLength validates strings with sufficient length', () {
      final result = Validators.minLength('hello', 3);
      expect(result.isValid, isTrue);
      expect(result.value, equals('hello'));
    });

    test('minLength fails for strings that are too short', () {
      final result = Validators.minLength('hi', 3, 'too short');
      expect(result.isInvalid, isTrue);
      expect(result.errors, equals(['too short']));
    });

    test('maxLength validates strings within length limit', () {
      final result = Validators.maxLength('hello', 10);
      expect(result.isValid, isTrue);
      expect(result.value, equals('hello'));
    });

    test('maxLength fails for strings that are too long', () {
      final result = Validators.maxLength('this is very long', 5, 'too long');
      expect(result.isInvalid, isTrue);
      expect(result.errors, equals(['too long']));
    });

    test('range validates numbers within range', () {
      final result = Validators.range(5, 1, 10);
      expect(result.isValid, isTrue);
      expect(result.value, equals(5));
    });

    test('range fails for numbers below minimum', () {
      final result = Validators.range(0, 1, 10, 'out of range');
      expect(result.isInvalid, isTrue);
      expect(result.errors, equals(['out of range']));
    });

    test('range fails for numbers above maximum', () {
      final result = Validators.range(15, 1, 10, 'out of range');
      expect(result.isInvalid, isTrue);
      expect(result.errors, equals(['out of range']));
    });

    test('pattern validates matching strings', () {
      final result = Validators.pattern('abc123', RegExp(r'[a-z]+\d+'));
      expect(result.isValid, isTrue);
      expect(result.value, equals('abc123'));
    });

    test('pattern fails for non-matching strings', () {
      final result =
          Validators.pattern('123abc', RegExp(r'[a-z]+\d+'), 'invalid format');
      expect(result.isInvalid, isTrue);
      expect(result.errors, equals(['invalid format']));
    });

    test('email validates valid email addresses', () {
      final result = Validators.email('test@example.com');
      expect(result.isValid, isTrue);
      expect(result.value, equals('test@example.com'));
    });

    test('email fails for invalid email addresses', () {
      final result = Validators.email('invalid-email');
      expect(result.isInvalid, isTrue);
      expect(result.errors.first, contains('Invalid email'));
    });

    test('predicate validates when predicate is true', () {
      final result = Validators.predicate(5, (x) => x > 0, 'must be positive');
      expect(result.isValid, isTrue);
      expect(result.value, equals(5));
    });

    test('predicate fails when predicate is false', () {
      final result = Validators.predicate(-1, (x) => x > 0, 'must be positive');
      expect(result.isInvalid, isTrue);
      expect(result.errors, equals(['must be positive']));
    });

    test('positive validates positive numbers', () {
      final result = Validators.positive(5);
      expect(result.isValid, isTrue);
      expect(result.value, equals(5));
    });

    test('positive fails for non-positive numbers', () {
      final result = Validators.positive(0, 'must be positive');
      expect(result.isInvalid, isTrue);
      expect(result.errors, equals(['must be positive']));
    });

    test('nonNegative validates non-negative numbers', () {
      final result = Validators.nonNegative(0);
      expect(result.isValid, isTrue);
      expect(result.value, equals(0));
    });

    test('nonNegative fails for negative numbers', () {
      final result = Validators.nonNegative(-1, 'must be non-negative');
      expect(result.isInvalid, isTrue);
      expect(result.errors, equals(['must be non-negative']));
    });
  });

  group('Extensions', () {
    test('validate extension validates with predicate', () {
      final result = 5.validate((x) => x > 0, 'must be positive');
      expect(result.isValid, isTrue);
      expect(result.value, equals(5));
    });

    test('validateNotNull extension validates non-null values', () {
      final result = 'test'.validateNotNull();
      expect(result.isValid, isTrue);
      expect(result.value, equals('test'));
    });

    test('validateNotEmpty string extension', () {
      final result = 'test'.validateNotEmpty();
      expect(result.isValid, isTrue);
      expect(result.value, equals('test'));
    });

    test('validateMinLength string extension', () {
      final result = 'hello'.validateMinLength(3);
      expect(result.isValid, isTrue);
      expect(result.value, equals('hello'));
    });

    test('validateMaxLength string extension', () {
      final result = 'hello'.validateMaxLength(10);
      expect(result.isValid, isTrue);
      expect(result.value, equals('hello'));
    });

    test('validatePattern string extension', () {
      final result = 'abc123'.validatePattern(RegExp(r'[a-z]+\d+'));
      expect(result.isValid, isTrue);
      expect(result.value, equals('abc123'));
    });

    test('validateEmail string extension', () {
      final result = 'test@example.com'.validateEmail();
      expect(result.isValid, isTrue);
      expect(result.value, equals('test@example.com'));
    });

    test('validateRange num extension', () {
      final result = 5.validateRange(1, 10);
      expect(result.isValid, isTrue);
      expect(result.value, equals(5));
    });

    test('validatePositive num extension', () {
      final result = 5.validatePositive();
      expect(result.isValid, isTrue);
      expect(result.value, equals(5));
    });

    test('negative validates negative numbers', () {
      final result = Validators.negative(-5);
      expect(result.isValid, isTrue);
      expect(result.value, equals(-5));

      final invalidResult = Validators.negative(5);
      expect(invalidResult.isInvalid, isTrue);
      expect(invalidResult.errors, contains('Value must be negative'));
    });

    test('zero validates zero', () {
      final result = Validators.zero(0);
      expect(result.isValid, isTrue);
      expect(result.value, equals(0));

      final invalidResult = Validators.zero(5);
      expect(invalidResult.isInvalid, isTrue);
      expect(invalidResult.errors, contains('Value must be zero'));
    });

    test('contains validates string contains substring', () {
      final result = Validators.contains('hello world', 'world');
      expect(result.isValid, isTrue);
      expect(result.value, equals('hello world'));

      final invalidResult = Validators.contains('hello', 'world');
      expect(invalidResult.isInvalid, isTrue);
      expect(invalidResult.errors, contains('String must contain "world"'));
    });

    test('startsWith validates string starts with prefix', () {
      final result = Validators.startsWith('hello world', 'hello');
      expect(result.isValid, isTrue);
      expect(result.value, equals('hello world'));

      final invalidResult = Validators.startsWith('world', 'hello');
      expect(invalidResult.isInvalid, isTrue);
      expect(invalidResult.errors, contains('String must start with "hello"'));
    });

    test('endsWith validates string ends with suffix', () {
      final result = Validators.endsWith('hello world', 'world');
      expect(result.isValid, isTrue);
      expect(result.value, equals('hello world'));

      final invalidResult = Validators.endsWith('hello', 'world');
      expect(invalidResult.isInvalid, isTrue);
      expect(invalidResult.errors, contains('String must end with "world"'));
    });

    test('url validates URL format', () {
      final result = Validators.url('https://www.example.com');
      expect(result.isValid, isTrue);
      expect(result.value, equals('https://www.example.com'));

      final invalidResult = Validators.url('not a url');
      expect(invalidResult.isInvalid, isTrue);
      expect(invalidResult.errors, contains('Invalid URL format'));
    });

    test('phoneNumber validates phone number format', () {
      final result = Validators.phoneNumber('+1234567890');
      expect(result.isValid, isTrue);
      expect(result.value, equals('+1234567890'));

      final invalidResult = Validators.phoneNumber('123');
      expect(invalidResult.isInvalid, isTrue);
      expect(invalidResult.errors, contains('Invalid phone number format'));
    });

    test('integer validates integer numbers', () {
      final result = Validators.integer(42);
      expect(result.isValid, isTrue);
      expect(result.value, equals(42));

      final invalidResult = Validators.integer(42.5);
      expect(invalidResult.isInvalid, isTrue);
      expect(invalidResult.errors, contains('Value must be an integer'));
    });

    test('notEmptyCollection validates non-empty collections', () {
      final result = Validators.notEmptyCollection([1, 2, 3]);
      expect(result.isValid, isTrue);
      expect(result.value, equals([1, 2, 3]));

      final invalidResult = Validators.notEmptyCollection(<int>[]);
      expect(invalidResult.isInvalid, isTrue);
      expect(invalidResult.errors, contains('Collection cannot be empty'));
    });

    test('minSize validates collection minimum size', () {
      final result = Validators.minSize([1, 2, 3], 2);
      expect(result.isValid, isTrue);
      expect(result.value, equals([1, 2, 3]));

      final invalidResult = Validators.minSize([1], 2);
      expect(invalidResult.isInvalid, isTrue);
      expect(invalidResult.errors,
          contains('Collection must have at least 2 items'));
    });

    test('maxSize validates collection maximum size', () {
      final result = Validators.maxSize([1, 2], 3);
      expect(result.isValid, isTrue);
      expect(result.value, equals([1, 2]));

      final invalidResult = Validators.maxSize([1, 2, 3, 4], 3);
      expect(invalidResult.isInvalid, isTrue);
      expect(invalidResult.errors,
          contains('Collection must have at most 3 items'));
    });

    test('oneOf validates value is in allowed list', () {
      final result = Validators.oneOf('apple', ['apple', 'banana', 'orange']);
      expect(result.isValid, isTrue);
      expect(result.value, equals('apple'));

      final invalidResult =
          Validators.oneOf('grape', ['apple', 'banana', 'orange']);
      expect(invalidResult.isInvalid, isTrue);
      expect(invalidResult.errors.first, contains('Value must be one of'));
    });

    test('validateNonNegative num extension', () {
      final result = 0.validateNonNegative();
      expect(result.isValid, isTrue);
      expect(result.value, equals(0));
    });
  });
}
