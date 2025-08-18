import 'dart:async';
import 'package:meta/meta.dart';
import 'option.dart';

/// A type that represents either success ([Ok]) or failure ([Err]).
///
/// This is inspired by Rust's Result type and provides a robust way to handle
/// operations that can fail without using exceptions. Results provide a type-safe
/// way to handle both the success and error cases.
///
///
///
/// Basic usage:
///
/// ```dart
/// // Create a successful result
/// final success = Result.ok('Hello World');
/// print(success.isOk); // true
/// print(success.value); // 'Hello World'
///
/// // Create an error result
/// final error = Result.err('Something went wrong');
/// print(error.isErr); // true
/// print(error.error); // 'Something went wrong'
/// ```
///
///
///
///
/// Chaining operations:
///
/// ```dart
/// final result = Result.ok(5)
///     .map((x) => x * 2)
///     .flatMap((x) => x > 5 ? Result.ok('Success: $x') : Result.err('Too small'));
/// print(result); // Ok(Success: 10)
/// ```
///
@immutable
sealed class Result<T, E> {
  const Result();

  /// Creates a success result containing [value].
  ///
  ///
  ///
  /// ```dart
  /// final result = Result.ok('Hello World');
  /// print(result.isOk); // true
  /// print(result.value); // 'Hello World'
  /// ```
  ///
  const factory Result.ok(T value) = Ok<T, E>;

  /// Creates an error result containing [error].
  ///
  ///
  ///
  /// ```dart
  /// final result = Result.err('Something went wrong');
  /// print(result.isErr); // true
  /// print(result.error); // 'Something went wrong'
  /// ```
  ///
  const factory Result.err(E error) = Err<T, E>;

  // --- Ergonomic aliases (Rust/Kotlin-inspired) ---
  /// Alias of [valueOrElse] named like Kotlin's getOrElse.
  T getOrElse(T Function(E error) defaultValue) => valueOrElse(defaultValue);

  /// Alias of [valueOr] named like Kotlin's getOrDefault.
  T getOrDefault(T defaultValue) => valueOr(defaultValue);

  /// Returns the success value if Ok, otherwise null (Kotlin-like getOrNull).
  T? getOrNull() => toNullable();

  /// Creates a Result by executing [computation] and catching any exceptions.
  ///
  /// If [computation] completes successfully, returns [Ok] with the result.
  /// If it throws, returns [Err] with the exception.
  ///
  ///
  ///
  /// ```dart
  /// // Successful computation
  /// final result1 = Result.from(() => int.parse('42'));
  /// print(result1); // Ok(42)
  ///
  /// // Failing computation
  /// final result2 = Result.from(() => int.parse('not a number'));
  /// print(result2.isErr); // true
  /// ```
  ///
  factory Result.from(T Function() computation) {
    try {
      return Ok(computation());
    } catch (e) {
      return Err(e as E);
    }
  }

  /// Creates a Result from a [Future] by executing [computation] and catching any exceptions.
  ///
  ///
  ///
  /// ```dart
  /// // Successful async computation
  /// final result1 = await Result.fromAsync(() async => 42);
  /// print(result1); // Ok(42)
  ///
  /// // Failing async computation
  /// final result2 = await Result.fromAsync(() async {
  ///   throw Exception('Network error');
  /// });
  /// print(result2.isErr); // true
  /// ```
  ///
  static Future<Result<T, E>> fromAsync<T, E>(
    Future<T> Function() computation,
  ) async {
    try {
      final result = await computation();
      return Ok<T, E>(result);
    } catch (e) {
      return Err<T, E>(e as E);
    }
  }

  /// Ensures the [predicate] holds for an [Ok] value, otherwise converts it to [Err] with [error].
  ///
  /// If this is already [Err], it is returned unchanged.
  ///
  /// ```dart
  /// final r1 = Result.ok(10).ensure((v) => v > 5, 'too small');
  /// print(r1); // Ok(10)
  ///
  /// final r2 = Result.ok(3).ensure((v) => v > 5, 'too small');
  /// print(r2); // Err('too small')
  ///
  /// final r3 = Result<int, String>.err('boom').ensure((v) => v > 5, 'x');
  /// print(r3); // Err('boom')
  /// ```
  Result<T, E> ensure(bool Function(T value) predicate, E error) {
    return switch (this) {
      Ok(:final value) => predicate(value) ? this : Err(error),
      Err() => this,
    };
  }

  /// Ensures the [predicate] holds for an [Ok] value, otherwise converts it to [Err]
  /// with a lazily computed error from [error]. If this is already [Err], returns it unchanged.
  ///
  /// ```dart
  /// final r1 = Result.ok(10).ensureElse((v) => v > 5, (v) => 'too small: $v');
  /// print(r1); // Ok(10)
  ///
  /// final r2 = Result.ok(3).ensureElse((v) => v > 5, (v) => 'too small: $v');
  /// print(r2); // Err('too small: 3')
  /// ```
  Result<T, E> ensureElse(
      bool Function(T value) predicate, E Function(T value) error) {
    return switch (this) {
      Ok(:final value) => predicate(value) ? this : Err(error(value)),
      Err() => this,
    };
  }

  /// Returns `true` if the result is [Ok].
  ///
  ///
  ///
  /// ```dart
  /// final success = Result.ok(42);
  /// final failure = Result.err('error');
  ///
  /// print(success.isOk); // true
  /// print(failure.isOk); // false
  /// ```
  ///
  bool get isOk => this is Ok<T, E>;

  /// Returns `true` if the result is [Err].
  ///
  ///
  ///
  /// ```dart
  /// final success = Result.ok(42);
  /// final failure = Result.err('error');
  ///
  /// print(success.isErr); // false
  /// print(failure.isErr); // true
  /// ```
  ///
  bool get isErr => this is Err<T, E>;

  /// Returns the success value if [Ok], otherwise throws.
  ///
  ///
  ///
  /// ```dart
  /// final success = Result.ok(42);
  /// print(success.value); // 42
  ///
  /// final failure = Result.err('error');
  /// // failure.value; // throws StateError
  /// ```
  ///
  T get value {
    return switch (this) {
      Ok(:final value) => value,
      Err(:final error) => throw StateError('Called value on Err: $error'),
    };
  }

  /// Returns the error value if [Err], otherwise throws.
  ///
  ///
  ///
  /// ```dart
  /// final failure = Result.err('error');
  /// print(failure.error); // 'error'
  ///
  /// final success = Result.ok(42);
  /// // success.error; // throws StateError
  /// ```
  ///
  E get error {
    return switch (this) {
      Ok(:final value) => throw StateError('Called error on Ok: $value'),
      Err(:final error) => error,
    };
  }

  /// Returns the success value if [Ok], otherwise returns [defaultValue].
  ///
  ///
  ///
  /// ```dart
  /// final success = Result.ok(42);
  /// final failure = Result.err('error');
  ///
  /// print(success.valueOr(0)); // 42
  /// print(failure.valueOr(0)); // 0
  /// ```
  ///
  T valueOr(T defaultValue) {
    return switch (this) {
      Ok(:final value) => value,
      Err() => defaultValue,
    };
  }

  /// Returns the success value if [Ok], otherwise returns the result of [defaultValue].
  ///
  ///
  ///
  /// ```dart
  /// final success = Result.ok(42);
  /// final failure = Result.err('error');
  ///
  /// print(success.valueOrElse(() => 0)); // 42
  /// print(failure.valueOrElse(() => 0)); // 0
  /// print(failure.valueOrElse(() => DateTime.now().millisecond)); // dynamic default
  /// ```
  ///
  T valueOrElse(T Function(E error) defaultValue) {
    return switch (this) {
      Ok(:final value) => value,
      Err(:final error) => defaultValue(error),
    };
  }

  /// Maps a [Result<T, E>] to [Result<U, E>] by applying a function to the success value.
  ///
  ///
  ///
  /// ```dart
  /// final result = Result.ok(5);
  /// final doubled = result.map((x) => x * 2);
  /// print(doubled); // Ok(10)
  ///
  /// final error = Result.err('error');
  /// final mapped = error.map((x) => x * 2);
  /// print(mapped); // Err('error')
  /// ```
  ///
  Result<U, E> map<U>(U Function(T value) fn) {
    return switch (this) {
      Ok(:final value) => Ok(fn(value)),
      Err(:final error) => Err(error),
    };
  }

  /// Maps a [Result<T, E>] to [Result<T, F>] by applying a function to the error value.
  ///
  ///
  ///
  /// ```dart
  /// final success = Result.ok(42);
  /// final mapped = success.mapErr((e) => 'Error: $e');
  /// print(mapped); // Ok(42)
  ///
  /// final error = Result.err('network failure');
  /// final mappedErr = error.mapErr((e) => 'Error: $e');
  /// print(mappedErr); // Err('Error: network failure')
  /// ```
  ///
  Result<T, F> mapErr<F>(F Function(E error) fn) {
    return switch (this) {
      Ok(:final value) => Ok(value),
      Err(:final error) => Err(fn(error)),
    };
  }

  /// Maps both the success and error values.
  ///
  /// Applies [onSuccess] to the success value if [Ok], or [onError] to the error value if [Err].
  ///
  ///
  ///
  /// ```dart
  /// final success = Result.ok(42);
  /// final mapped = success.bimap(
  ///   (value) => value.toString(),
  ///   (error) => 'Error: $error',
  /// );
  /// print(mapped); // Ok('42')
  ///
  /// final error = Result<int, String>.err('failure');
  /// final mappedErr = error.bimap(
  ///   (value) => value.toString(),
  ///   (error) => 'Error: $error',
  /// );
  /// print(mappedErr); // Err('Error: failure')
  /// ```
  ///
  Result<U, F> bimap<U, F>(
    U Function(T value) onSuccess,
    F Function(E error) onError,
  ) {
    return switch (this) {
      Ok(:final value) => Ok(onSuccess(value)),
      Err(:final error) => Err(onError(error)),
    };
  }

  /// Maps the success value with a function that returns a [Result].
  /// This is also known as flatMap or bind in other languages.
  ///
  ///
  ///
  /// ```dart
  /// final result = Result.ok('42');
  /// final parsed = result.flatMap((s) {
  ///   try {
  ///     return Result.ok(int.parse(s));
  ///   } catch (e) {
  ///     return Result.err('Parse error');
  ///   }
  /// });
  /// print(parsed); // Ok(42)
  ///
  /// final invalid = Result.ok('not a number');
  /// final failed = invalid.flatMap((s) {
  ///   try {
  ///     return Result.ok(int.parse(s));
  ///   } catch (e) {
  ///     return Result.err('Parse error');
  ///   }
  /// });
  /// print(failed); // Err('Parse error')
  /// ```
  ///
  Result<U, E> flatMap<U>(Result<U, E> Function(T value) fn) {
    return switch (this) {
      Ok(:final value) => fn(value),
      Err(:final error) => Err(error),
    };
  }

  /// Maps the error value with a function that returns a [Result].
  ///
  ///
  ///
  /// ```dart
  /// final success = Result.ok(42);
  /// final recovered = success.flatMapErr((e) => Result.ok(0));
  /// print(recovered); // Ok(42)
  ///
  /// final error = Result.err('network failure');
  /// final recovered2 = error.flatMapErr((e) => Result.ok(0));
  /// print(recovered2); // Ok(0)
  /// ```
  ///
  Result<T, F> flatMapErr<F>(Result<T, F> Function(E error) fn) {
    return switch (this) {
      Ok(:final value) => Ok(value),
      Err(:final error) => fn(error),
    };
  }

  /// Executes [fn] if the result is [Ok] and returns this result.
  ///
  ///
  ///
  /// ```dart
  /// final result = Ok(42);
  /// result.tap((value) => print('Got value: $value')); // prints: Got value: 42
  /// // result is still Ok(42)
  ///
  /// final error = Err('failed');
  /// error.tap((value) => print('This won\'t print'));
  /// // error is still Err('failed')
  /// ```
  ///
  Result<T, E> tap(void Function(T value) fn) {
    if (this case Ok(:final value)) {
      fn(value);
    }
    return this;
  }

  /// Executes [fn] if the result is [Err] and returns this result.
  ///
  ///
  ///
  /// ```dart
  /// final success = Ok(42);
  /// success.tapErr((error) => print('This won\'t print'));
  /// // success is still Ok(42)
  ///
  /// final error = Err('failed');
  /// error.tapErr((err) => print('Got error: $err')); // prints: Got error: failed
  /// // error is still Err('failed')
  /// ```
  ///
  Result<T, E> tapErr(void Function(E error) fn) {
    if (this case Err(:final error)) {
      fn(error);
    }
    return this;
  }

  /// Returns this result if it is [Ok], otherwise returns [other].
  ///
  ///
  ///
  /// ```dart
  /// final success = Ok(42);
  /// final backup = Ok(0);
  /// print(success.or(backup)); // Ok(42)
  ///
  /// final failure = Err('error');
  /// print(failure.or(backup)); // Ok(0)
  /// ```
  ///
  Result<T, E> or(Result<T, E> other) {
    return switch (this) {
      Ok() => this,
      Err() => other,
    };
  }

  /// Returns this result if it is [Ok], otherwise returns the result of [other].
  ///
  ///
  ///
  /// ```dart
  /// final success = Ok(42);
  /// print(success.orElse((error) => Ok(0))); // Ok(42)
  ///
  /// final failure = Err('network error');
  /// print(failure.orElse((error) => Ok(-1))); // Ok(-1)
  /// print(failure.orElse((error) => Err('fallback: $error'))); // Err('fallback: network error')
  /// ```
  ///
  Result<T, E> orElse(Result<T, E> Function(E error) other) {
    return switch (this) {
      Ok() => this,
      Err(:final error) => other(error),
    };
  }

  /// Returns [other] if this result is [Ok], otherwise returns this result.
  ///
  ///
  ///
  /// ```dart
  /// final success = Ok(42);
  /// final next = Ok('hello');
  /// print(success.and(next)); // Ok('hello')
  ///
  /// final failure = Err('error');
  /// print(failure.and(next)); // Err('error')
  /// ```
  ///
  Result<U, E> and<U>(Result<U, E> other) {
    return switch (this) {
      Ok() => other,
      Err() => Err(error),
    };
  }

  /// Returns the result of [other] if this result is [Ok], otherwise returns this result.
  ///
  ///
  ///
  /// ```dart
  /// final success = Ok(5);
  /// final doubled = success.andThen((value) => Ok(value * 2));
  /// print(doubled); // Ok(10)
  ///
  /// final failure = Err('error');
  /// final processed = failure.andThen((value) => Ok(value * 2));
  /// print(processed); // Err('error')
  /// ```
  ///
  Result<U, E> andThen<U>(Result<U, E> Function(T value) other) {
    return switch (this) {
      Ok(:final value) => other(value),
      Err() => Err(error),
    };
  }

  /// Executes [onOk] if the result is [Ok], or [onErr] if it is [Err].
  ///
  ///
  ///
  /// ```dart
  /// final success = Ok(42);
  /// final message = success.fold(
  ///   (value) => 'Success: $value',
  ///   (error) => 'Error: $error',
  /// );
  /// print(message); // 'Success: 42'
  ///
  /// final failure = Err('failed');
  /// final errorMessage = failure.fold(
  ///   (value) => 'Success: $value',
  ///   (error) => 'Error: $error',
  /// );
  /// print(errorMessage); // 'Error: failed'
  /// ```
  ///
  R fold<R>(R Function(T value) onOk, R Function(E error) onErr) {
    return switch (this) {
      Ok(:final value) => onOk(value),
      Err(:final error) => onErr(error),
    };
  }

  /// Swaps [Ok] and [Err], turning a [Result<T, E>] into [Result<E, T>].
  ///
  /// ```dart
  /// final swapped1 = Result.ok(1).swap();
  /// print(swapped1); // Err(1)
  ///
  /// final swapped2 = Result<int, String>.err('e').swap();
  /// print(swapped2); // Ok('e')
  /// ```
  Result<E, T> swap() {
    return switch (this) {
      Ok(:final value) => Err(value),
      Err(:final error) => Ok(error),
    };
  }

  /// Executes [onOk] if the result is [Ok], or [onErr] if it is [Err].
  ///
  ///
  ///
  /// ```dart
  /// final success = Ok(42);
  /// success.match(
  ///   (value) => print('Success: $value'),
  ///   (error) => print('Error: $error'),
  /// ); // prints: Success: 42
  ///
  /// final failure = Err('failed');
  /// failure.match(
  ///   (value) => print('Success: $value'),
  ///   (error) => print('Error: $error'),
  /// ); // prints: Error: failed
  /// ```
  ///
  void match(void Function(T value) onOk, void Function(E error) onErr) {
    switch (this) {
      case Ok(:final value):
        onOk(value);
      case Err(:final error):
        onErr(error);
    }
  }

  /// Converts the result to a nullable value, returning null for [Err].
  ///
  ///
  ///
  /// ```dart
  /// final success = Ok(42);
  /// print(success.toNullable()); // 42
  ///
  /// final failure = Err('error');
  /// print(failure.toNullable()); // null
  /// ```
  ///
  T? toNullable() {
    return switch (this) {
      Ok(:final value) => value,
      Err() => null,
    };
  }

  /// Converts the result to a list, returning an empty list for [Err].
  ///
  ///
  ///
  /// ```dart
  /// final success = Ok(42);
  /// print(success.toList()); // [42]
  ///
  /// final failure = Err('error');
  /// print(failure.toList()); // []
  /// ```
  ///
  List<T> toList() {
    return switch (this) {
      Ok(:final value) => [value],
      Err() => [],
    };
  }

  /// Returns an iterator that yields the value if [Ok], or nothing if [Err].
  ///
  ///
  ///
  /// ```dart
  /// final success = Ok(42);
  /// for (final value in success.toIterable()) {
  ///   print(value); // prints: 42
  /// }
  ///
  /// final failure = Err('error');
  /// for (final value in failure.toIterable()) {
  ///   print(value); // nothing printed
  /// }
  ///
  /// // Convert to list
  /// print(success.toIterable().toList()); // [42]
  /// print(failure.toIterable().toList()); // []
  /// ```
  ///
  Iterable<T> toIterable() {
    return switch (this) {
      Ok(:final value) => [value],
      Err() => [],
    };
  }

  @override
  bool operator ==(Object other) {
    return switch (this) {
      Ok(:final value) when other is Ok<T, E> => value == other.value,
      Err(:final error) when other is Err<T, E> => error == other.error,
      _ => false,
    };
  }

  @override
  int get hashCode {
    return switch (this) {
      Ok(:final value) => Object.hash('Ok', value),
      Err(:final error) => Object.hash('Err', error),
    };
  }

  /// Flattens a nested Result.
  ///
  ///
  ///
  /// ```dart
  /// final nested = Result.ok(Result.ok(42));
  /// final flattened = nested.flatten();
  /// print(flattened); // Ok(42)
  ///
  /// final nestedErr = Result.ok(Result.err('inner error'));
  /// final flattenedErr = nestedErr.flatten();
  /// print(flattenedErr); // Err('inner error')
  /// ```
  ///
  Result<U, E> flatten<U>() {
    return switch (this) {
      Ok(:final value) when value is Result<U, E> => value as Result<U, E>,
      Ok(:final value) => throw ArgumentError(
          'Cannot flatten Result with non-Result value: $value',
        ),
      Err(:final error) => Err(error),
    };
  }

  /// Performs a side effect without changing the Result.
  ///
  ///
  ///
  /// ```dart
  /// final result = Result.ok(42)
  ///   .inspect((value) => print('Success: $value'))
  ///   .map((x) => x * 2);
  /// // Prints: Success: 42
  /// print(result); // Ok(84)
  /// ```
  ///
  Result<T, E> inspect(void Function(T value) fn) {
    return switch (this) {
      Ok(:final value) => () {
          fn(value);
          return this;
        }(),
      Err() => this,
    };
  }

  /// Performs a side effect on the error without changing the Result.
  ///
  ///
  ///
  /// ```dart
  /// final result = Result.err('network failure')
  ///   .inspectErr((error) => print('Error occurred: $error'))
  ///   .orElse((e) => Result.ok(0));
  /// // Prints: Error occurred: network failure
  /// print(result); // Ok(0)
  /// ```
  ///
  Result<T, E> inspectErr(void Function(E error) fn) {
    return switch (this) {
      Ok() => this,
      Err(:final error) => () {
          fn(error);
          return this;
        }(),
    };
  }

  /// Transposes a Result of an Option into an Option of a Result.
  ///
  ///
  ///
  /// ```dart
  /// final success = Result.ok(Option.some(42));
  /// final transposed = success.transpose();
  /// print(transposed); // Some(Ok(42))
  ///
  /// final successNone = Result.ok(Option.none<int>());
  /// final transposedNone = successNone.transpose();
  /// print(transposedNone); // None
  ///
  /// final failure = Result.err('error');
  /// final transposedErr = failure.transpose();
  /// print(transposedErr); // Some(Err('error'))
  /// ```
  ///
  Option<Result<U, E>> transpose<U>() {
    return switch (this) {
      Ok(:final value) when value is Option<U> => () {
          final option = value as Option<U>;
          return switch (option) {
            Some(value: final innerValue) =>
              Option.some(Result<U, E>.ok(innerValue)),
            None() => Option<Result<U, E>>.none(),
          };
        }(),
      Ok(:final value) => throw ArgumentError(
          'Cannot transpose Result with non-Option value: $value',
        ),
      Err(:final error) => Option.some(Result<U, E>.err(error)),
    };
  }

  @override
  String toString() {
    return switch (this) {
      Ok(:final value) => 'Ok($value)',
      Err(:final error) => 'Err($error)',
    };
  }
}

/// A successful result containing a [value].
final class Ok<T, E> extends Result<T, E> {
  const Ok(this.value);

  @override
  final T value;
}

/// An error result containing an [error].
final class Err<T, E> extends Result<T, E> {
  const Err(this.error);

  @override
  final E error;
}

/// Utility functions for creating Results.
abstract final class Results {
  /// Creates an [Ok] result.
  static Result<T, E> ok<T, E>(T value) => Ok<T, E>(value);

  /// Creates an [Err] result.
  static Result<T, E> err<T, E>(E error) => Err<T, E>(error);

  /// Combines multiple Results into a single Result containing a list.
  /// Returns [Ok] with all values if all results are [Ok], otherwise returns the first [Err].
  ///
  ///
  ///
  /// ```dart
  /// final results = [Result.ok(1), Result.ok(2), Result.ok(3)];
  /// final combined = Results.combine(results);
  /// print(combined); // Ok([1, 2, 3])
  ///
  /// final mixedResults = [Result.ok(1), Result.err('error'), Result.ok(3)];
  /// final failed = Results.combine(mixedResults);
  /// print(failed); // Err('error')
  /// ```
  ///
  static Result<List<T>, E> combine<T, E>(Iterable<Result<T, E>> results) {
    final values = <T>[];
    for (final result in results) {
      switch (result) {
        case Ok(:final value):
          values.add(value);
        case Err(:final error):
          return Err(error);
      }
    }
    return Ok(values);
  }

  /// Traverses a list of values, applying [fn] to each and collecting the results.
  ///
  ///
  ///
  /// ```dart
  /// final numbers = ['1', '2', '3'];
  /// final parsed = Results.traverse<String, int, String>(
  ///   numbers,
  ///   (s) => Result.from(() => int.parse(s)),
  /// );
  /// print(parsed); // Ok([1, 2, 3])
  /// ```
  ///
  static Result<List<U>, E> traverse<T, U, E>(
    Iterable<T> values,
    Result<U, E> Function(T) fn,
  ) {
    final results = values.map(fn);
    return combine(results);
  }

  /// Creates a Result from a nullable value.
  ///
  ///
  ///
  /// ```dart
  /// final value = Results.fromNullable(42, 'Value is null');
  /// print(value); // Ok(42)
  ///
  /// final nullValue = Results.fromNullable<int, String>(null, 'Value is null');
  /// print(nullValue); // Err('Value is null')
  /// ```
  ///
  static Result<T, E> fromNullable<T, E>(T? value, E error) {
    return value != null ? Ok(value) : Err(error);
  }

  /// Applies a function to the values inside two Results.
  ///
  ///
  ///
  /// ```dart
  /// final a = Result.ok(2);
  /// final b = Result.ok(3);
  /// final result = Results.lift2(a, b, (x, y) => x + y);
  /// print(result); // Ok(5)
  /// ```
  ///
  static Result<C, E> lift2<A, B, C, E>(
    Result<A, E> a,
    Result<B, E> b,
    C Function(A, B) fn,
  ) {
    return switch ((a, b)) {
      (Ok(:final value), Ok(value: final valueB)) => Ok(fn(value, valueB)),
      (Err(:final error), _) => Err(error),
      (_, Err(:final error)) => Err(error),
    };
  }

  /// Sequences a collection of Results into a single Result of a list.
  /// Returns Ok with all values if all are Ok, otherwise the first Err.
  static Result<List<T>, E> sequence<T, E>(Iterable<Result<T, E>> results) =>
      combine(results);

  /// Partitions results into (oks, errs) preserving order.
  static (List<T>, List<E>) partition<T, E>(Iterable<Result<T, E>> results) {
    final oks = <T>[];
    final errs = <E>[];
    for (final r in results) {
      switch (r) {
        case Ok(:final value):
          oks.add(value);
        case Err(:final error):
          errs.add(error);
      }
    }
    return (oks, errs);
  }
}
