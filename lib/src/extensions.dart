import 'dart:async';
import 'result.dart';
import 'option.dart';

/// Quick conversions available on any non-null value.
///
/// - `value.ok<E>()` -> Result<T, E>
/// - `value.some()` -> Option<T>
extension AnyToResultAndOption<T> on T {
  /// Wrap this value into an Ok result.
  ///
  /// ```dart
  /// final r = 42.ok<String>();
  /// print(r); // Ok(42)
  /// ```
  Result<T, E> ok<E>() => Result.ok(this);

  /// Wrap this value into a Some option.
  ///
  /// ```dart
  /// final o = 'value'.some();
  /// print(o); // Some('value')
  /// ```
  Option<T> some() => Option.some(this);
}

/// Quick conversion for any value as an error into a Result's Err side.
///
/// Usage: `'boom'.err<int>()` -> `Result<int, String>.err('boom')`.
extension ToErr<E> on E {
  /// Wrap this value into an Err result.
  ///
  /// ```dart
  /// final r = 'boom'.err<int>();
  /// print(r); // Err('boom')
  /// ```
  Result<T, E> err<T>() => Result.err(this);
}

/// Extension on nullable types to convert to Option.
extension NullableToOption<T> on T? {
  /// Converts a nullable value to an Option.
  ///
  /// ```dart
  /// String? nullableString = 'hello';
  /// final option = nullableString.toOption(); // Some('hello')
  ///
  /// nullableString = null;
  /// final none = nullableString.toOption(); // None
  /// ```
  Option<T> toOption() => Option.fromNullable(this);

  /// Converts a nullable value to a Result.
  ///
  /// ```dart
  /// String? value = 'hello';
  /// final result = value.toResult('Value is null'); // Ok('hello')
  ///
  /// value = null;
  /// final error = value.toResult('Value is null'); // Err('Value is null')
  /// ```
  Result<T, E> toResult<E>(E error) => Results.fromNullable(this, error);
}

/// Extension on String for easy validation and conversion.
extension StringExtensions on String {
  /// Parses this string as an integer, returning a Result.
  ///
  /// ```dart
  /// final success = '42'.parseInt(); // Ok(42)
  /// final failure = 'abc'.parseInt(); // Err(FormatException)
  /// ```
  Result<int, FormatException> parseInt() {
    return Result.from(() => int.parse(this));
  }

  /// Parses this string as a double, returning a Result.
  ///
  /// ```dart
  /// final success = '3.14'.parseDouble(); // Ok(3.14)
  /// final failure = 'abc'.parseDouble(); // Err(FormatException)
  /// ```
  Result<double, FormatException> parseDouble() {
    return Result.from(() => double.parse(this));
  }

  /// Explicitly convert to Option only when non-empty.
  ///
  /// ```dart
  /// final nonEmpty = 'hello'.nonEmpty(); // Some('hello')
  /// final empty = ''.nonEmpty(); // None
  /// ```
  Option<String> nonEmpty() {
    return isEmpty ? const Option.none() : Option.some(this);
  }

  /// Validates this string is not empty, returning a Result.
  ///
  /// ```dart
  /// final valid = 'hello'.notEmpty('String cannot be empty'); // Ok('hello')
  /// final invalid = ''.notEmpty('String cannot be empty'); // Err('String cannot be empty')
  /// ```
  Result<String, E> notEmpty<E>(E error) {
    return isEmpty ? Result.err(error) : Result.ok(this);
  }
}

/// Extension on List for Result and Option operations.
extension ListExtensions<T> on List<T> {
  /// Gets the first element as an Option.
  ///
  /// ```dart
  /// final list = [1, 2, 3];
  /// final first = list.firstOption(); // Some(1)
  ///
  /// final empty = <int>[];
  /// final none = empty.firstOption(); // None
  /// ```
  Option<T> firstOption() {
    return isEmpty ? Option.none() : Option.some(first);
  }

  /// Gets the last element as an Option.
  ///
  /// ```dart
  /// final list = [1, 2, 3];
  /// final last = list.lastOption(); // Some(3)
  ///
  /// final empty = <int>[];
  /// final none = empty.lastOption(); // None
  /// ```
  Option<T> lastOption() {
    return isEmpty ? Option.none() : Option.some(last);
  }

  /// Gets the element at [index] as an Option.
  ///
  /// ```dart
  /// final list = [1, 2, 3];
  /// final element = list.getOption(1); // Some(2)
  /// final outOfBounds = list.getOption(10); // None
  /// ```
  Option<T> getOption(int index) {
    return (index >= 0 && index < length)
        ? Option.some(this[index])
        : Option.none();
  }

  /// Finds the first element matching [test] as an Option.
  ///
  /// ```dart
  /// final list = [1, 2, 3, 4, 5];
  /// final even = list.findOption((x) => x.isEven); // Some(2)
  /// final large = list.findOption((x) => x > 10); // None
  /// ```
  Option<T> findOption(bool Function(T) test) {
    for (final element in this) {
      if (test(element)) {
        return Option.some(element);
      }
    }
    return Option.none();
  }

  /// Validates this list is not empty, returning a Result.
  ///
  /// ```dart
  /// final list = [1, 2, 3];
  /// final valid = list.notEmpty('List cannot be empty'); // Ok([1, 2, 3])
  ///
  /// final empty = <int>[];
  /// final invalid = empty.notEmpty('List cannot be empty'); // Err('List cannot be empty')
  /// ```
  Result<List<T>, E> notEmpty<E>(E error) {
    return isEmpty ? Result.err(error) : Result.ok(this);
  }
}

/// Extension on Map for Option operations.
extension MapExtensions<K, V> on Map<K, V> {
  /// Gets the value for [key] as an Option.
  ///
  /// ```dart
  /// final map = {'a': 1, 'b': 2};
  /// final value = map.getOption('a'); // Some(1)
  /// final missing = map.getOption('c'); // None
  /// ```
  Option<V> getOption(K key) {
    final value = this[key];
    return value != null ? Option.some(value) : Option.none();
  }
}

/// Extension on Future for Result operations.
extension FutureExtensions<T> on Future<T> {
  /// Converts this Future to an AsyncResult, catching exceptions.
  ///
  /// ```dart
  /// Future<int> computation() async => 42;
  ///
  /// final asyncResult = computation().toAsyncResult<String>();
  /// final result = await asyncResult; // Ok(42)
  /// ```
  Future<Result<T, E>> toAsyncResult<E>() async {
    try {
      final value = await this;
      return Result.ok(value);
    } catch (error) {
      return Result.err(error as E);
    }
  }

  /// Converts this Future to a Result, catching exceptions.
  ///
  /// ```dart
  /// Future<int> computation() async => 42;
  ///
  /// final result = await computation().toResult<String>();
  /// print(result); // Ok(42)
  /// ```
  Future<Result<T, E>> toResult<E>() async {
    return Result.fromAsync<T, E>(() => this);
  }
}

/// Extension on Iterable<Result> for convenient operations.
extension IterableResultExtensions<T, E> on Iterable<Result<T, E>> {
  /// Combines all Results, returning Ok with all values or the first Err.
  ///
  /// ```dart
  /// final results = [Result.ok(1), Result.ok(2), Result.ok(3)];
  /// final combined = results.combine(); // Ok([1, 2, 3])
  /// ```
  Result<List<T>, E> combine() => Results.combine(this);

  /// Collects all Ok values, ignoring Err values.
  ///
  /// ```dart
  /// final results = [Result.ok(1), Result.err('error'), Result.ok(3)];
  /// final values = results.collectOk(); // [1, 3]
  /// ```
  List<T> collectOk() {
    return where((r) => r.isOk).map((r) => (r as Ok<T, E>).value).toList();
  }

  /// Collects all Err values, ignoring Ok values.
  ///
  /// ```dart
  /// final results = [Result.ok(1), Result.err('error1'), Result.err('error2')];
  /// final errors = results.collectErr(); // ['error1', 'error2']
  /// ```
  List<E> collectErr() {
    return where((r) => r.isErr).map((r) => (r as Err<T, E>).error).toList();
  }
}

/// Extension on Iterable<Option> for convenient operations.
extension IterableOptionExtensions<T> on Iterable<Option<T>> {
  /// Combines all Options, returning Some with all values or None if any is None.
  ///
  /// ```dart
  /// final options = [Option.some(1), Option.some(2), Option.some(3)];
  /// final combined = options.combine(); // Some([1, 2, 3])
  /// ```
  Option<List<T>> combine() => Options.combine(this);

  /// Collects all Some values, ignoring None values.
  ///
  /// ```dart
  /// final options = [Option.some(1), Option.none<int>(), Option.some(3)];
  /// final values = options.collectSome(); // [1, 3]
  /// ```
  List<T> collectSome() => Options.collectSome(this);
}

/// Extension on bool for Option operations.
extension BoolExtensions on bool {
  /// Converts this bool to an Option, returning Some(value) if true, None if false.
  ///
  /// ```dart
  /// final option1 = true.then(() => 42); // Some(42)
  /// final option2 = false.then(() => 42); // None
  /// ```
  Option<T> then<T>(T Function() value) {
    return this ? Option.some(value()) : Option.none();
  }

  /// Converts this bool to a Result, returning Ok(value) if true, Err(error) if false.
  ///
  /// ```dart
  /// final result1 = true.thenResult(() => 42, 'Failed'); // Ok(42)
  /// final result2 = false.thenResult(() => 42, 'Failed'); // Err('Failed')
  /// ```
  Result<T, E> thenResult<T, E>(T Function() value, E error) {
    return this ? Result.ok(value()) : Result.err(error);
  }
}

/// Extension on num for validation operations.
extension NumExtensions on num {
  /// Validates this number is positive, returning a Result.
  ///
  /// ```dart
  /// final valid = 5.positive('Must be positive'); // Ok(5)
  /// final invalid = (-1).positive('Must be positive'); // Err('Must be positive')
  /// ```
  Result<num, E> positive<E>(E error) {
    return this > 0 ? Result.ok(this) : Result.err(error);
  }

  /// Validates this number is non-negative, returning a Result.
  ///
  /// ```dart
  /// final valid = 0.nonNegative('Must be non-negative'); // Ok(0)
  /// final invalid = (-1).nonNegative('Must be non-negative'); // Err('Must be non-negative')
  /// ```
  Result<num, E> nonNegative<E>(E error) {
    return this >= 0 ? Result.ok(this) : Result.err(error);
  }

  /// Validates this number is in range [min, max], returning a Result.
  ///
  /// ```dart
  /// final valid = 5.inRange(0, 10, 'Out of range'); // Ok(5)
  /// final invalid = 15.inRange(0, 10, 'Out of range'); // Err('Out of range')
  /// ```
  Result<num, E> inRange<E>(num min, num max, E error) {
    return (this >= min && this <= max) ? Result.ok(this) : Result.err(error);
  }
}
