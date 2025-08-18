import 'package:meta/meta.dart';
import 'result.dart';

/// A type that represents validation results, accumulating all errors.
///
/// Unlike [Result] which short-circuits on the first error, [Validation]
/// collects all validation errors, making it useful for form validation
/// and data validation scenarios.
///
///
///
/// ```dart
/// // Creating Validations
/// final valid = Validation.valid(42);
/// final invalid = Validation.invalid(['error1', 'error2']);
///
/// // Accumulating errors
/// final validation = Validation.valid(User())
///     .validate((user) => user.email.isNotEmpty, 'Email required')
///     .validate((user) => user.age >= 18, 'Must be adult')
///     .validate((user) => user.name.length >= 2, 'Name too short');
///
/// if (validation.isInvalid) {
///   validation.errors.forEach(print); // prints all errors at once
/// }
/// ```
///
@immutable
sealed class Validation<E, T> {
  const Validation();

  /// Creates a [Valid] containing [value].
  ///
  ///
  ///
  /// ```dart
  /// final validation = Validation.valid(42);
  /// print(validation.isValid); // true
  /// print(validation.value); // 42
  /// ```
  ///
  const factory Validation.valid(T value) = Valid<E, T>;

  /// Creates an [Invalid] containing [errors].
  ///
  ///
  ///
  /// ```dart
  /// final validation = Validation.invalid<String, int>(['error1', 'error2']);
  /// print(validation.isInvalid); // true
  /// print(validation.errors); // ['error1', 'error2']
  /// ```
  ///
  const factory Validation.invalid(List<E> errors) = Invalid<E, T>;

  /// Creates an [Invalid] containing a single [error].
  ///
  ///
  ///
  /// ```dart
  /// final validation = Validation.invalidSingle<String, int>('single error');
  /// print(validation.isInvalid); // true
  /// print(validation.errors); // ['single error']
  /// ```
  ///
  factory Validation.invalidSingle(E error) = Invalid.single;

  /// Creates a Validation by executing [computation] and catching any exceptions.
  ///
  ///
  ///
  /// ```dart
  /// // Successful computation
  /// final result1 = Validation.from<Object, int>(() => int.parse('42'));
  /// print(result1); // Valid(42)
  ///
  /// // Failing computation
  /// final result2 = Validation.from<Object, int>(() => int.parse('invalid'));
  /// print(result2.isInvalid); // true
  /// ```
  ///
  factory Validation.from(T Function() computation) {
    try {
      return Valid(computation());
    } catch (e) {
      return Invalid.single(e as E);
    }
  }

  /// Returns `true` if the validation is [Valid].
  ///
  ///
  ///
  /// ```dart
  /// final valid = Validation.valid(42);
  /// final invalid = Validation.invalid<String, int>(['error']);
  ///
  /// print(valid.isValid); // true
  /// print(invalid.isValid); // false
  /// ```
  ///
  bool get isValid => this is Valid<E, T>;

  /// Returns `true` if the validation is [Invalid].
  ///
  ///
  ///
  /// ```dart
  /// final valid = Validation.valid(42);
  /// final invalid = Validation.invalid<String, int>(['error']);
  ///
  /// print(valid.isInvalid); // false
  /// print(invalid.isInvalid); // true
  /// ```
  ///
  bool get isInvalid => this is Invalid<E, T>;

  /// Returns the success value if [Valid], otherwise throws.
  ///
  ///
  ///
  /// ```dart
  /// final valid = Validation.valid(42);
  /// print(valid.value); // 42
  ///
  /// final invalid = Validation.invalid<String, int>(['error']);
  /// // invalid.value; // throws StateError
  /// ```
  ///
  T get value {
    return switch (this) {
      Valid(:final value) => value,
      Invalid(:final errors) => throw StateError(
          'Called value on Invalid: $errors',
        ),
    };
  }

  /// Returns the errors if [Invalid], otherwise throws.
  ///
  ///
  ///
  /// ```dart
  /// final invalid = Validation.invalid<String, int>(['error1', 'error2']);
  /// print(invalid.errors); // ['error1', 'error2']
  ///
  /// final valid = Validation.valid(42);
  /// // valid.errors; // throws StateError
  /// ```
  ///
  List<E> get errors {
    return switch (this) {
      Valid(:final value) => throw StateError('Called errors on Valid: $value'),
      Invalid(:final errors) => errors,
    };
  }

  /// Returns the success value if [Valid], otherwise returns [defaultValue].
  ///
  /// ```dart
  /// final v1 = Validation<String, int>.valid(42).valueOr(0); // 42
  /// final v2 = Validation<String, int>.invalid(['e']).valueOr(0); // 0
  /// ```
  T valueOr(T defaultValue) {
    return switch (this) {
      Valid(:final value) => value,
      Invalid() => defaultValue,
    };
  }

  /// Returns the success value if [Valid], otherwise returns the result of [defaultValue].
  ///
  /// ```dart
  /// final v1 = Validation<String, int>.valid(42)
  ///   .valueOrElse((_) => 0); // 42
  /// final v2 = Validation<String, int>.invalid(['e'])
  ///   .valueOrElse((errs) => errs.length); // 1
  /// ```
  T valueOrElse(T Function(List<E> errors) defaultValue) {
    return switch (this) {
      Valid(:final value) => value,
      Invalid(:final errors) => defaultValue(errors),
    };
  }

  /// Maps a [Validation<E, T>] to [Validation<E, U>] by applying a function to the success value.
  ///
  /// ```dart
  /// final v = Validation<String, int>.valid(2).map((x) => x * 2);
  /// print(v); // Valid(4)
  /// ```
  Validation<E, U> map<U>(U Function(T value) fn) {
    return switch (this) {
      Valid(:final value) => Valid(fn(value)),
      Invalid(:final errors) => Invalid(errors),
    };
  }

  /// Maps a [Validation<E, T>] to [Validation<F, T>] by applying a function to the error values.
  ///
  /// ```dart
  /// final inv = Validation<String, int>.invalid(['a', 'b'])
  ///   .mapErrors((e) => 'E:$e');
  /// print(inv); // Invalid(['E:a', 'E:b'])
  /// ```
  Validation<F, T> mapErrors<F>(F Function(E error) fn) {
    return switch (this) {
      Valid(:final value) => Valid(value),
      Invalid(:final errors) => Invalid(errors.map(fn).toList()),
    };
  }

  /// Maps the success value with a function that returns a [Validation].
  /// This is also known as flatMap or bind in other languages.
  ///
  /// ```dart
  /// final v = Validation<String, int>.valid(2)
  ///   .flatMap((x) => x > 1 ? Validation.valid(x * 2) : Validation.invalid(['e']));
  /// print(v); // Valid(4)
  /// ```
  Validation<E, U> flatMap<U>(Validation<E, U> Function(T value) fn) {
    return switch (this) {
      Valid(:final value) => fn(value),
      Invalid(:final errors) => Invalid(errors),
    };
  }

  /// Executes [fn] if the validation is [Valid] and returns this validation.
  ///
  /// ```dart
  /// final messages = <String>[];
  /// Validation<String, int>.valid(1)
  ///   .tap((v) => messages.add('v=$v'));
  /// // messages contains 'v=1'
  /// ```
  Validation<E, T> tap(void Function(T value) fn) {
    if (this case Valid(:final value)) {
      fn(value);
    }
    return this;
  }

  /// Executes [fn] if the validation is [Invalid] and returns this validation.
  ///
  /// ```dart
  /// final messages = <String>[];
  /// Validation<String, int>.invalid(['e'])
  ///   .tapErrors((errs) => messages.add(errs.first));
  /// // messages contains 'e'
  /// ```
  Validation<E, T> tapErrors(void Function(List<E> errors) fn) {
    if (this case Invalid(:final errors)) {
      fn(errors);
    }
    return this;
  }

  /// Combines this validation with another, accumulating errors.
  /// If both are [Valid], applies [fn] to both values.
  /// If either is [Invalid], combines all errors.
  Validation<E, V> zip<U, V>(Validation<E, U> other, V Function(T, U) fn) {
    if (this case Valid(value: final value1)) {
      if (other case Valid(value: final value2)) {
        return Valid(fn(value1, value2));
      }
    }

    final allErrors = <E>[];
    if (this case Invalid(errors: final errors1)) {
      allErrors.addAll(errors1);
    }
    if (other case Invalid(errors: final errors2)) {
      allErrors.addAll(errors2);
    }
    return Invalid(allErrors);
  }

  /// Applies [fn] if the validation is [Valid], otherwise accumulates with existing errors.
  Validation<E, V> zipWith<U, V>(Validation<E, U> other, V Function(T, U) fn) =>
      zip(other, fn);

  /// Executes [onValid] if the validation is [Valid], or [onInvalid] if it is [Invalid].
  ///
  /// ```dart
  /// final text = Validation<String, int>.valid(2)
  ///   .fold((v) => 'ok:$v', (errs) => 'err:${errs.length}');
  /// print(text); // ok:2
  /// ```
  R fold<R>(R Function(T value) onValid, R Function(List<E> errors) onInvalid) {
    return switch (this) {
      Valid(:final value) => onValid(value),
      Invalid(:final errors) => onInvalid(errors),
    };
  }

  /// Executes [onValid] if the validation is [Valid], or [onInvalid] if it is [Invalid].
  ///
  /// ```dart
  /// Validation<String, int>.valid(2).match(
  ///   (v) => print('ok:$v'),
  ///   (errs) => print('err:${errs.length}'),
  /// );
  /// ```
  void match(
    void Function(T value) onValid,
    void Function(List<E> errors) onInvalid,
  ) {
    switch (this) {
      case Valid(:final value):
        onValid(value);
      case Invalid(:final errors):
        onInvalid(errors);
    }
  }

  /// Converts the validation to a [Result].
  /// [Valid] becomes [Ok] and [Invalid] becomes [Err] with the first error.
  ///
  /// ```dart
  /// final r1 = Validation<String, int>.valid(1).toResult(); // Ok(1)
  /// final r2 = Validation<String, int>.invalid(['e']).toResult(); // Err('e')
  /// ```
  Result<T, E> toResult() {
    return switch (this) {
      Valid(:final value) => Ok(value),
      Invalid(:final errors) => Err(errors.first),
    };
  }

  /// Converts the validation to a [Result] with all errors.
  ///
  /// ```dart
  /// final r = Validation<String, int>.invalid(['a','b']).toResultAll();
  /// // Err(['a','b'])
  /// ```
  Result<T, List<E>> toResultAll() {
    return switch (this) {
      Valid(:final value) => Ok(value),
      Invalid(:final errors) => Err(errors),
    };
  }

  /// Converts the validation to a nullable value.
  T? toNullable() {
    return switch (this) {
      Valid(:final value) => value,
      Invalid() => null,
    };
  }

  /// Converts the validation to a list.
  List<T> toList() {
    return switch (this) {
      Valid(:final value) => [value],
      Invalid() => [],
    };
  }

  @override
  bool operator ==(Object other) {
    return switch (this) {
      Valid(:final value) when other is Valid<E, T> => value == other.value,
      Invalid(:final errors) when other is Invalid<E, T> =>
        errors.length == other.errors.length &&
            errors.every((e) => other.errors.contains(e)),
      _ => false,
    };
  }

  @override
  int get hashCode {
    return switch (this) {
      Valid(:final value) => Object.hash('Valid', value),
      Invalid(:final errors) => Object.hash('Invalid', Object.hashAll(errors)),
    };
  }

  @override
  String toString() {
    return switch (this) {
      Valid(:final value) => 'Valid($value)',
      Invalid(:final errors) => 'Invalid($errors)',
    };
  }
}

/// A valid validation containing a [value].
final class Valid<E, T> extends Validation<E, T> {
  const Valid(this.value);

  @override
  final T value;
}

/// An invalid validation containing [errors].
final class Invalid<E, T> extends Validation<E, T> {
  const Invalid(this.errors);

  /// Creates an [Invalid] with a single error.
  Invalid.single(E error) : errors = [error];

  @override
  final List<E> errors;
}

/// Utility functions for creating Validations.
abstract final class Validations {
  /// Creates a [Valid] validation.
  static Validation<E, T> valid<E, T>(T value) => Valid<E, T>(value);

  /// Creates an [Invalid] validation with multiple errors.
  static Validation<E, T> invalid<E, T>(List<E> errors) =>
      Invalid<E, T>(errors);

  /// Creates an [Invalid] validation with a single error.
  static Validation<E, T> invalidSingle<E, T>(E error) =>
      Invalid<E, T>.single(error);

  /// Combines multiple Validations into a single Validation containing a list.
  /// Accumulates all validation errors if any validations are invalid.
  static Validation<E, List<T>> combine<E, T>(
    Iterable<Validation<E, T>> validations,
  ) {
    final values = <T>[];
    final allErrors = <E>[];

    for (final validation in validations) {
      switch (validation) {
        case Valid(:final value):
          values.add(value);
        case Invalid(:final errors):
          allErrors.addAll(errors);
      }
    }

    if (allErrors.isEmpty) {
      return Valid(values);
    } else {
      return Invalid(allErrors);
    }
  }

  /// Traverses a list of values, applying [fn] to each and collecting the results.
  static Validation<E, List<U>> traverse<T, E, U>(
    Iterable<T> values,
    Validation<E, U> Function(T) fn,
  ) {
    final results = values.map(fn);
    return combine(results);
  }

  /// Applies a function to the values inside two Validations.
  /// Accumulates errors from both validations if either is invalid.
  static Validation<E, C> lift2<E, A, B, C>(
    Validation<E, A> a,
    Validation<E, B> b,
    C Function(A, B) fn,
  ) {
    return a.zip(b, fn);
  }

  /// Applies a function to the values inside three Validations.
  /// Accumulates errors from all validations if any are invalid.
  static Validation<E, D> lift3<E, A, B, C, D>(
    Validation<E, A> a,
    Validation<E, B> b,
    Validation<E, C> c,
    D Function(A, B, C) fn,
  ) {
    if (a case Valid(value: final valueA)) {
      if (b case Valid(value: final valueB)) {
        if (c case Valid(value: final valueC)) {
          return Valid(fn(valueA, valueB, valueC));
        }
      }
    }

    final allErrors = <E>[];
    if (a case Invalid(errors: final errors)) allErrors.addAll(errors);
    if (b case Invalid(errors: final errors)) allErrors.addAll(errors);
    if (c case Invalid(errors: final errors)) allErrors.addAll(errors);
    return Invalid(allErrors);
  }
}

/// Common validation functions.
abstract final class Validators {
  /// Validates that a value is not null.
  static Validation<String, T> notNull<T>(T? value, [String? message]) {
    return value != null
        ? Valid(value)
        : Invalid.single(message ?? 'Value cannot be null');
  }

  /// Validates that a string is not empty.
  static Validation<String, String> notEmpty(String? value, [String? message]) {
    return value != null && value.isNotEmpty
        ? Valid(value)
        : Invalid.single(message ?? 'String cannot be empty');
  }

  /// Validates that a string has a minimum length.
  static Validation<String, String> minLength(
    String value,
    int min, [
    String? message,
  ]) {
    return value.length >= min
        ? Valid(value)
        : Invalid.single(
            message ?? 'String must be at least $min characters long',
          );
  }

  /// Validates that a string has a maximum length.
  static Validation<String, String> maxLength(
    String value,
    int max, [
    String? message,
  ]) {
    return value.length <= max
        ? Valid(value)
        : Invalid.single(
            message ?? 'String must be at most $max characters long',
          );
  }

  /// Validates that a number is within a range.
  static Validation<String, num> range(
    num value,
    num min,
    num max, [
    String? message,
  ]) {
    return value >= min && value <= max
        ? Valid(value)
        : Invalid.single(message ?? 'Value must be between $min and $max');
  }

  /// Validates that a string matches a pattern.
  static Validation<String, String> pattern(
    String value,
    RegExp pattern, [
    String? message,
  ]) {
    return pattern.hasMatch(value)
        ? Valid(value)
        : Invalid.single(message ?? 'Value does not match required pattern');
  }

  /// Validates an email address.
  static Validation<String, String> email(String value, [String? message]) {
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return pattern(value, emailRegex, message ?? 'Invalid email address');
  }

  /// Validates with a custom predicate function.
  static Validation<E, T> predicate<E, T>(
    T value,
    bool Function(T) test,
    E error,
  ) {
    return test(value) ? Valid(value) : Invalid.single(error);
  }

  /// Validates that a number is positive.
  static Validation<String, num> positive(num value, [String? message]) {
    return value > 0
        ? Valid(value)
        : Invalid.single(message ?? 'Value must be positive');
  }

  /// Validates that a number is non-negative.
  static Validation<String, num> nonNegative(num value, [String? message]) {
    return value >= 0
        ? Valid(value)
        : Invalid.single(message ?? 'Value must be non-negative');
  }

  /// Validates that a number is negative.
  static Validation<String, num> negative(num value, [String? message]) {
    return value < 0
        ? Valid(value)
        : Invalid.single(message ?? 'Value must be negative');
  }

  /// Validates that a number is zero.
  static Validation<String, num> zero(num value, [String? message]) {
    return value == 0
        ? Valid(value)
        : Invalid.single(message ?? 'Value must be zero');
  }

  /// Validates that a string contains another string.
  static Validation<String, String> contains(
    String value,
    String substring, [
    String? message,
  ]) {
    return value.contains(substring)
        ? Valid(value)
        : Invalid.single(
            message ?? 'String must contain "$substring"',
          );
  }

  /// Validates that a string starts with a prefix.
  static Validation<String, String> startsWith(
    String value,
    String prefix, [
    String? message,
  ]) {
    return value.startsWith(prefix)
        ? Valid(value)
        : Invalid.single(
            message ?? 'String must start with "$prefix"',
          );
  }

  /// Validates that a string ends with a suffix.
  static Validation<String, String> endsWith(
    String value,
    String suffix, [
    String? message,
  ]) {
    return value.endsWith(suffix)
        ? Valid(value)
        : Invalid.single(
            message ?? 'String must end with "$suffix"',
          );
  }

  /// Validates a URL format.
  static Validation<String, String> url(String value, [String? message]) {
    final urlRegex = RegExp(
      r'^https?:\/\/(?:www\.)?[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9\-]{0,61}[a-zA-Z0-9])?)*\/?.*$',
    );
    return pattern(value, urlRegex, message ?? 'Invalid URL format');
  }

  /// Validates a phone number format.
  static Validation<String, String> phoneNumber(
    String value, [
    String? message,
  ]) {
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]{10,}$');
    return pattern(value, phoneRegex, message ?? 'Invalid phone number format');
  }

  /// Validates that a number is an integer.
  static Validation<String, num> integer(num value, [String? message]) {
    return value == value.truncate()
        ? Valid(value)
        : Invalid.single(message ?? 'Value must be an integer');
  }

  /// Validates that a collection is not empty.
  static Validation<String, Iterable<T>> notEmptyCollection<T>(
    Iterable<T> value, [
    String? message,
  ]) {
    return value.isNotEmpty
        ? Valid(value)
        : Invalid.single(message ?? 'Collection cannot be empty');
  }

  /// Validates that a collection has a minimum size.
  static Validation<String, Iterable<T>> minSize<T>(
    Iterable<T> value,
    int min, [
    String? message,
  ]) {
    return value.length >= min
        ? Valid(value)
        : Invalid.single(
            message ?? 'Collection must have at least $min items',
          );
  }

  /// Validates that a collection has a maximum size.
  static Validation<String, Iterable<T>> maxSize<T>(
    Iterable<T> value,
    int max, [
    String? message,
  ]) {
    return value.length <= max
        ? Valid(value)
        : Invalid.single(
            message ?? 'Collection must have at most $max items',
          );
  }

  /// Validates that a value is in a list of allowed values.
  static Validation<String, T> oneOf<T>(
    T value,
    Iterable<T> allowed, [
    String? message,
  ]) {
    return allowed.contains(value)
        ? Valid(value)
        : Invalid.single(
            message ?? 'Value must be one of ${allowed.toList()}',
          );
  }
}

/// Extension methods for adding validation to any type.
extension ValidationExtensions<T> on T {
  /// Validates this value with a predicate.
  Validation<E, T> validate<E>(bool Function(T) test, E error) {
    return test(this) ? Valid(this) : Invalid.single(error);
  }

  /// Validates this value is not null.
  Validation<String, T> validateNotNull([String? message]) {
    return this != null
        ? Valid(this)
        : Invalid.single(message ?? 'Value cannot be null');
  }
}

/// Extension methods for String validation.
extension StringValidationExtensions on String {
  /// Validates this string is not empty.
  Validation<String, String> validateNotEmpty([String? message]) =>
      Validators.notEmpty(this, message);

  /// Validates this string has minimum length.
  Validation<String, String> validateMinLength(int min, [String? message]) =>
      Validators.minLength(this, min, message);

  /// Validates this string has maximum length.
  Validation<String, String> validateMaxLength(int max, [String? message]) =>
      Validators.maxLength(this, max, message);

  /// Validates this string matches a pattern.
  Validation<String, String> validatePattern(
    RegExp pattern, [
    String? message,
  ]) =>
      Validators.pattern(this, pattern, message);

  /// Validates this string is a valid email.
  Validation<String, String> validateEmail([String? message]) =>
      Validators.email(this, message);
}

/// Extension methods for num validation.
extension NumValidationExtensions on num {
  /// Validates this number is within a range.
  Validation<String, num> validateRange(num min, num max, [String? message]) =>
      Validators.range(this, min, max, message);

  /// Validates this number is positive.
  Validation<String, num> validatePositive([String? message]) =>
      Validators.positive(this, message);

  /// Validates this number is non-negative.
  Validation<String, num> validateNonNegative([String? message]) =>
      Validators.nonNegative(this, message);
}
