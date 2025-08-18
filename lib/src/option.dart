import 'package:meta/meta.dart';

import 'result.dart';

/// A type that represents an optional value: either some [T] value or none.
///
/// This is inspired by Rust's Option type and Haskell's Maybe type.
/// It provides a safe way to handle nullable values without risking null pointer exceptions.
///
///
///
/// ```dart
/// // Creating Options
/// final some = Option.some(42);
/// final none = Option.none<int>();
/// final fromNullable = Option.fromNullable(getValue()); // T? -> Option<T>
///
/// // Safe access
/// final value = some.valueOr(0); // 42
/// final defaulted = none.valueOr(0); // 0
///
/// // Chaining operations
/// final doubled = some.map((x) => x * 2); // Some(84)
/// final filtered = some.filter((x) => x > 50); // None
/// ```
///
@immutable
sealed class Option<T> {
  const Option();

  /// Creates an Option containing [value].
  ///
  ///
  ///
  /// ```dart
  /// final option = Option.some('Hello');
  /// print(option.isSome); // true
  /// print(option.value); // 'Hello'
  /// ```
  ///
  const factory Option.some(T value) = Some<T>;

  /// Creates an Option containing no value.
  ///
  ///
  ///
  /// ```dart
  /// final option = Option.none<String>();
  /// print(option.isNone); // true
  /// print(option.valueOr('default')); // 'default'
  /// ```
  ///
  const factory Option.none() = None<T>;

  /// Creates an Option from a nullable value.
  /// Returns [Some] if [value] is not null, otherwise [None].
  ///
  ///
  ///
  /// ```dart
  /// String? nullableString = 'hello';
  /// final option1 = Option.fromNullable(nullableString); // Some('hello')
  ///
  /// nullableString = null;
  /// final option2 = Option.fromNullable(nullableString); // None
  /// ```
  ///
  factory Option.fromNullable(T? value) {
    return value != null ? Some(value) : None<T>();
  }

  // --- Ergonomic aliases (Rust/Kotlin-inspired) ---
  /// Alias to convert Option to Result with eager error (Rust ok_or).
  Result<T, E> okOr<E>(E error) => toResult(error);

  /// Alias to convert Option to Result with lazy error (Rust ok_or_else).
  Result<T, E> okOrElse<E>(E Function() error) => toResultElse(error);

  /// Returns value or null (Kotlin getOrNull).
  T? orNull() => toNullable();

  /// Returns value or default (Kotlin unwrapOr / getOrDefault style).
  T unwrapOr(T defaultValue) => valueOr(defaultValue);

  /// Returns value or evaluated default (Kotlin unwrapOrElse / getOrElse).
  T unwrapOrElse(T Function() defaultValue) => valueOrElse(defaultValue);

  /// Returns `true` if the option is [Some].
  ///
  ///
  ///
  /// ```dart
  /// final some = Option.some(42);
  /// final none = Option.none<int>();
  ///
  /// print(some.isSome); // true
  /// print(none.isSome); // false
  /// ```
  ///
  bool get isSome => this is Some<T>;

  /// Returns `true` if the option is [None].
  ///
  ///
  ///
  /// ```dart
  /// final some = Option.some(42);
  /// final none = Option.none<int>();
  ///
  /// print(some.isNone); // false
  /// print(none.isNone); // true
  /// ```
  ///
  bool get isNone => this is None<T>;

  /// Returns the value if [Some], otherwise throws.
  ///
  ///
  ///
  /// ```dart
  /// final some = Option.some(42);
  /// print(some.value); // 42
  ///
  /// final none = Option.none<int>();
  /// // none.value; // throws StateError
  /// ```
  ///
  T get value {
    return switch (this) {
      Some(:final value) => value,
      None() => throw StateError('Called value on None'),
    };
  }

  /// Returns the value if [Some], otherwise returns [defaultValue].
  ///
  ///
  ///
  /// ```dart
  /// final some = Option.some(42);
  /// final none = Option.none<int>();
  ///
  /// print(some.valueOr(0)); // 42
  /// print(none.valueOr(0)); // 0
  /// ```
  ///
  T valueOr(T defaultValue) {
    return switch (this) {
      Some(:final value) => value,
      None() => defaultValue,
    };
  }

  /// Returns the value if [Some], otherwise returns the result of [defaultValue].
  ///
  ///
  ///
  /// ```dart
  /// final some = Option.some(42);
  /// final none = Option.none<int>();
  ///
  /// print(some.valueOrElse(() => 0)); // 42
  /// print(none.valueOrElse(() => DateTime.now().millisecond)); // dynamic default
  /// ```
  ///
  T valueOrElse(T Function() defaultValue) {
    return switch (this) {
      Some(:final value) => value,
      None() => defaultValue(),
    };
  }

  /// Maps an [Option<T>] to [Option<U>] by applying a function to the contained value.
  ///
  ///
  ///
  /// ```dart
  /// final some = Option.some(5);
  /// final doubled = some.map((x) => x * 2);
  /// print(doubled); // Some(10)
  ///
  /// final none = Option.none<int>();
  /// final mapped = none.map((x) => x * 2);
  /// print(mapped); // None
  /// ```
  ///
  Option<U> map<U>(U Function(T value) fn) {
    return switch (this) {
      Some(:final value) => Some(fn(value)),
      None() => None<U>(),
    };
  }

  /// Maps the value with a function that returns an [Option].
  /// This is also known as flatMap or bind in other languages.
  ///
  ///
  ///
  /// ```dart
  /// final some = Option.some('42');
  /// final parsed = some.flatMap((s) {
  ///   try {
  ///     return Option.some(int.parse(s));
  ///   } catch (e) {
  ///     return Option.none<int>();
  ///   }
  /// });
  /// print(parsed); // Some(42)
  ///
  /// final invalid = Option.some('not a number');
  /// final failed = invalid.flatMap((s) {
  ///   try {
  ///     return Option.some(int.parse(s));
  ///   } catch (e) {
  ///     return Option.none<int>();
  ///   }
  /// });
  /// print(failed); // None
  /// ```
  ///
  Option<U> flatMap<U>(Option<U> Function(T value) fn) {
    return switch (this) {
      Some(:final value) => fn(value),
      None() => None<U>(),
    };
  }

  /// Executes [fn] if the option is [Some] and returns this option.
  ///
  ///
  ///
  /// ```dart
  /// final some = Option.some(42);
  /// some.tap((value) => print('Got value: $value')); // prints: Got value: 42
  /// // some is still Some(42)
  ///
  /// final none = Option.none<int>();
  /// none.tap((value) => print('This won\'t print'));
  /// // none is still None
  /// ```
  ///
  Option<T> tap(void Function(T value) fn) {
    if (this case Some(:final value)) {
      fn(value);
    }
    return this;
  }

  /// Returns this option if it is [Some], otherwise returns [other].
  ///
  ///
  ///
  /// ```dart
  /// final some = Option.some(42);
  /// final backup = Option.some(0);
  /// print(some.or(backup)); // Some(42)
  ///
  /// final none = Option.none<int>();
  /// print(none.or(backup)); // Some(0)
  /// ```
  ///
  Option<T> or(Option<T> other) {
    return switch (this) {
      Some() => this,
      None() => other,
    };
  }

  /// Returns this option if it is [Some], otherwise returns the result of [other].
  ///
  ///
  ///
  /// ```dart
  /// final some = Option.some(42);
  /// print(some.orElse(() => Option.some(0))); // Some(42)
  ///
  /// final none = Option.none<int>();
  /// print(none.orElse(() => Option.some(-1))); // Some(-1)
  /// ```
  ///
  Option<T> orElse(Option<T> Function() other) {
    return switch (this) {
      Some() => this,
      None() => other(),
    };
  }

  /// Returns [other] if this option is [Some], otherwise returns [None].
  ///
  ///
  ///
  /// ```dart
  /// final some = Option.some(42);
  /// final next = Option.some('hello');
  /// print(some.and(next)); // Some('hello')
  ///
  /// final none = Option.none<int>();
  /// print(none.and(next)); // None
  /// ```
  ///
  Option<U> and<U>(Option<U> other) {
    return switch (this) {
      Some() => other,
      None() => None<U>(),
    };
  }

  /// Returns the result of [other] if this option is [Some], otherwise returns [None].
  ///
  ///
  ///
  /// ```dart
  /// final some = Option.some(5);
  /// final doubled = some.andThen((value) => Option.some(value * 2));
  /// print(doubled); // Some(10)
  ///
  /// final none = Option.none<int>();
  /// final processed = none.andThen((value) => Option.some(value * 2));
  /// print(processed); // None
  /// ```
  ///
  Option<U> andThen<U>(Option<U> Function(T value) other) {
    return switch (this) {
      Some(:final value) => other(value),
      None() => None<U>(),
    };
  }

  /// Executes [onSome] if the option is [Some], or [onNone] if it is [None].
  R fold<R>(R Function(T value) onSome, R Function() onNone) {
    return switch (this) {
      Some(:final value) => onSome(value),
      None() => onNone(),
    };
  }

  /// Executes [onSome] if the option is [Some], or [onNone] if it is [None].
  void match(void Function(T value) onSome, void Function() onNone) {
    switch (this) {
      case Some(:final value):
        onSome(value);
      case None():
        onNone();
    }
  }

  /// Filters the option based on a predicate.
  /// Returns [Some] if the predicate returns true, otherwise [None].
  ///
  ///
  ///
  /// ```dart
  /// final some = Option.some(5);
  /// final filtered = some.filter((x) => x > 3);
  /// print(filtered); // Some(5)
  ///
  /// final tooSmall = some.filter((x) => x > 10);
  /// print(tooSmall); // None
  ///
  /// final none = Option.none<int>();
  /// final stillNone = none.filter((x) => x > 0);
  /// print(stillNone); // None
  /// ```
  ///
  Option<T> filter(bool Function(T value) predicate) {
    return switch (this) {
      Some(:final value) when predicate(value) => this,
      _ => None<T>(),
    };
  }

  /// Converts the option to a nullable value.
  T? toNullable() {
    return switch (this) {
      Some(:final value) => value,
      None() => null,
    };
  }

  /// Converts the option to a list.
  List<T> toList() {
    return switch (this) {
      Some(:final value) => [value],
      None() => [],
    };
  }

  /// Returns an iterator that yields the value if [Some], or nothing if [None].
  Iterable<T> toIterable() {
    return switch (this) {
      Some(:final value) => [value],
      None() => [],
    };
  }

  /// Converts the option to a [Result].
  /// Returns [Ok] if [Some], otherwise [Err] with the provided error.
  ///
  ///
  ///
  /// ```dart
  /// final some = Option.some(42);
  /// final result = some.toResult('No value');
  /// print(result); // Ok(42)
  ///
  /// final none = Option.none<int>();
  /// final error = none.toResult('Value missing');
  /// print(error); // Err('Value missing')
  /// ```
  ///
  Result<T, E> toResult<E>(E error) {
    return switch (this) {
      Some(:final value) => Ok(value),
      None() => Err(error),
    };
  }

  /// Converts the option to a [Result] with a lazy error.
  /// Returns [Ok] if [Some], otherwise [Err] with the result of [error].
  Result<T, E> toResultElse<E>(E Function() error) {
    return switch (this) {
      Some(:final value) => Ok(value),
      None() => Err(error()),
    };
  }

  @override
  bool operator ==(Object other) {
    return switch (this) {
      Some(:final value) when other is Some<T> => value == other.value,
      None() when other is None<T> => true,
      _ => false,
    };
  }

  @override
  int get hashCode {
    return switch (this) {
      Some(:final value) => Object.hash('Some', value),
      None() => 'None'.hashCode,
    };
  }

  /// Flattens a nested Option.
  ///
  ///
  ///
  /// ```dart
  /// final nested = Option.some(Option.some(42));
  /// final flattened = nested.flatten();
  /// print(flattened); // Some(42)
  ///
  /// final nestedNone = Option.some(Option.none<int>());
  /// final flattenedNone = nestedNone.flatten();
  /// print(flattenedNone); // None
  /// ```
  ///
  Option<U> flatten<U>() {
    return switch (this) {
      Some(:final value) when value is Option<U> => value as Option<U>,
      Some(:final value) => throw ArgumentError(
          'Cannot flatten Option with non-Option value: $value',
        ),
      None() => None<U>(),
    };
  }

  /// Combines two Options into one containing a tuple.
  ///
  ///
  ///
  /// ```dart
  /// final a = Option.some(1);
  /// final b = Option.some('hello');
  /// final zipped = a.zip(b);
  /// print(zipped); // Some((1, 'hello'))
  ///
  /// final c = Option.none<int>();
  /// final zippedNone = a.zip(c);
  /// print(zippedNone); // None
  /// ```
  ///
  Option<(T, U)> zip<U>(Option<U> other) {
    return switch (this) {
      Some(:final value) => switch (other) {
          Some(value: final otherValue) => Some((value, otherValue)),
          None() => None<(T, U)>(),
        },
      None() => None<(T, U)>(),
    };
  }

  /// Combines two Options using a function.
  ///
  ///
  ///
  /// ```dart
  /// final a = Option.some(1);
  /// final b = Option.some(2);
  /// final combined = a.zipWith(b, (x, y) => x + y);
  /// print(combined); // Some(3)
  /// ```
  ///
  Option<R> zipWith<U, R>(Option<U> other, R Function(T, U) fn) {
    return zip(other).map((tuple) => fn(tuple.$1, tuple.$2));
  }

  /// Performs a side effect without changing the Option.
  ///
  ///
  ///
  /// ```dart
  /// final result = Option.some(42)
  ///   .inspect((value) => print('Value: $value'))
  ///   .map((x) => x * 2);
  /// // Prints: Value: 42
  /// print(result); // Some(84)
  /// ```
  ///
  Option<T> inspect(void Function(T value) fn) {
    return switch (this) {
      Some(:final value) => () {
          fn(value);
          return this;
        }(),
      None() => this,
    };
  }

  /// Transposes an Option of a Result into a Result of an Option.
  ///
  ///
  ///
  /// ```dart
  /// final some = Option.some(Result.ok(42));
  /// final transposed = some.transpose();
  /// print(transposed); // Ok(Some(42))
  ///
  /// final someErr = Option.some(Result.err('error'));
  /// final transposedErr = someErr.transpose();
  /// print(transposedErr); // Err('error')
  ///
  /// final none = Option.none<Result<int, String>>();
  /// final transposedNone = none.transpose();
  /// print(transposedNone); // Ok(None)
  /// ```
  ///
  Result<Option<U>, E> transpose<U, E>() {
    return switch (this) {
      Some(:final value) when value is Result<U, E> => () {
          final result = value as Result<U, E>;
          return switch (result) {
            Ok(value: final innerValue) =>
              Result<Option<U>, E>.ok(Option.some(innerValue)),
            Err(error: final error) => Result<Option<U>, E>.err(error),
          };
        }(),
      Some(:final value) => throw ArgumentError(
          'Cannot transpose Option with non-Result value: $value',
        ),
      None() => Result<Option<U>, E>.ok(Option<U>.none()),
    };
  }

  @override
  String toString() {
    return switch (this) {
      Some(:final value) => 'Some($value)',
      None() => 'None',
    };
  }
}

/// An option containing a [value].
final class Some<T> extends Option<T> {
  const Some(this.value);

  @override
  final T value;
}

/// An option containing no value.
final class None<T> extends Option<T> {
  const None();
}

/// Utility functions for creating Options.
abstract final class Options {
  /// Creates a [Some] option.
  static Option<T> some<T>(T value) => Some<T>(value);

  /// Creates a [None] option.
  static Option<T> none<T>() => None<T>();

  /// Creates an option from a nullable value.
  static Option<T> fromNullable<T>(T? value) => Option.fromNullable(value);

  /// Combines multiple Options into a single Option containing a list.
  /// Returns [Some] with all values if all options are [Some], otherwise returns [None].
  ///
  /// ```dart
  /// final options = [Option.some(1), Option.some(2)];
  /// final combined = Options.combine(options);
  /// print(combined); // Some([1, 2])
  ///
  /// final withNone = [Option.some(1), Option.none<int>()];
  /// final failed = Options.combine(withNone);
  /// print(failed); // None
  /// ```
  static Option<List<T>> combine<T>(Iterable<Option<T>> options) {
    final values = <T>[];
    for (final option in options) {
      switch (option) {
        case Some(:final value):
          values.add(value);
        case None():
          return None<List<T>>();
      }
    }
    return Some(values);
  }

  /// Combines multiple Options and collects all values.
  /// Returns a list of all [Some] values, ignoring [None] values.
  ///
  /// ```dart
  /// final options = [Option.some(1), Option.none<int>(), Option.some(3)];
  /// final values = Options.combineAll(options);
  /// print(values); // [1, 3]
  /// ```
  static List<T> combineAll<T>(Iterable<Option<T>> options) {
    final values = <T>[];
    for (final option in options) {
      if (option case Some(:final value)) {
        values.add(value);
      }
    }
    return values;
  }

  /// Traverses a list of values, applying [fn] to each and collecting the results.
  static Option<List<U>> traverse<T, U>(
    Iterable<T> values,
    Option<U> Function(T) fn,
  ) {
    final results = values.map(fn);
    return combine(results);
  }

  /// Applies a function to the values inside two Options.
  static Option<C> lift2<A, B, C>(
    Option<A> a,
    Option<B> b,
    C Function(A, B) fn,
  ) {
    if (a case Some(value: final valueA)) {
      if (b case Some(value: final valueB)) {
        return Some(fn(valueA, valueB));
      }
    }
    return None<C>();
  }

  /// Applies a function to the values inside three Options.
  static Option<D> lift3<A, B, C, D>(
    Option<A> a,
    Option<B> b,
    Option<C> c,
    D Function(A, B, C) fn,
  ) {
    if (a case Some(value: final valueA)) {
      if (b case Some(value: final valueB)) {
        if (c case Some(value: final valueC)) {
          return Some(fn(valueA, valueB, valueC));
        }
      }
    }
    return None<D>();
  }

  /// Partitions a list of Options into Some values and None count.
  /// Inspired by Haskell's `partitionEithers`.
  ///
  ///
  ///
  /// ```dart
  /// final options = [Option.some(1), Option.none<int>(), Option.some(2)];
  /// final (values, noneCount) = Options.partition(options);
  /// print(values); // [1, 2]
  /// print(noneCount); // 1
  /// ```
  ///
  static (List<T>, int) partition<T>(Iterable<Option<T>> options) {
    final values = <T>[];
    var noneCount = 0;

    for (final option in options) {
      switch (option) {
        case Some(:final value):
          values.add(value);
        case None():
          noneCount++;
      }
    }

    return (values, noneCount);
  }

  /// Collects all Some values, ignoring None values.
  /// Similar to Rust's `Iterator::filter_map`.
  ///
  ///
  ///
  /// ```dart
  /// final options = [Option.some(1), Option.none<int>(), Option.some(2)];
  /// final values = Options.collectSome(options);
  /// print(values); // [1, 2]
  /// ```
  ///
  static List<T> collectSome<T>(Iterable<Option<T>> options) {
    return options
        .where((o) => o.isSome)
        .map((o) => (o as Some<T>).value)
        .toList();
  }

  /// Applies a function that may fail to each element, short-circuiting on first None.
  /// Similar to Haskell's `mapM`.
  ///
  ///
  ///
  /// ```dart
  /// final numbers = [1, 2, 3];
  /// final doubled = Options.mapM<int, int>(
  ///   numbers,
  ///   (n) => Option.some(n * 2),
  /// );
  /// print(doubled); // Some([2, 4, 6])
  /// ```
  ///
  static Option<List<U>> mapM<T, U>(
    Iterable<T> values,
    Option<U> Function(T) fn,
  ) =>
      traverse(values, fn);

  /// Folds over a list of Options, accumulating values.
  /// Similar to Haskell's `foldM`.
  ///
  ///
  ///
  /// ```dart
  /// final options = [Option.some(1), Option.some(2), Option.some(3)];
  /// final sum = Options.foldM<int, int>(
  ///   options,
  ///   0,
  ///   (acc, value) => Option.some(acc + value),
  /// );
  /// print(sum); // Some(6)
  /// ```
  ///
  static Option<U> foldM<T, U>(
    Iterable<Option<T>> options,
    U initial,
    Option<U> Function(U acc, T value) fn,
  ) {
    var accumulator = initial;
    for (final option in options) {
      switch (option) {
        case Some(:final value):
          final newResult = fn(accumulator, value);
          switch (newResult) {
            case Some(:final value):
              accumulator = value;
            case None():
              return None<U>();
          }
        case None():
          return None<U>();
      }
    }
    return Some(accumulator);
  }

  /// Creates an Option by applying a predicate to a value.
  /// Similar to filtering patterns in functional programming.
  ///
  ///
  ///
  /// ```dart
  /// final positive = Options.fromPredicate(5, (n) => n > 0);
  /// print(positive); // Some(5)
  ///
  /// final negative = Options.fromPredicate(-1, (n) => n > 0);
  /// print(negative); // None
  /// ```
  ///
  static Option<T> fromPredicate<T>(T value, bool Function(T) predicate) {
    return predicate(value) ? Some(value) : None<T>();
  }

  /// Sequences a list of Options into an Option of a list.
  /// Similar to Haskell's `sequence`.
  ///
  ///
  ///
  /// ```dart
  /// final options = [Option.some(1), Option.some(2), Option.some(3)];
  /// final sequenced = Options.sequence(options);
  /// print(sequenced); // Some([1, 2, 3])
  /// ```
  ///
  static Option<List<T>> sequence<T>(Iterable<Option<T>> options) =>
      combine(options);

  /// Returns the first Some value, or None if all are None.
  /// Similar to the "alternative" pattern in functional programming.
  ///
  ///
  ///
  /// ```dart
  /// final options = [Option.none<int>(), Option.some(42), Option.some(10)];
  /// final first = Options.firstSome(options);
  /// print(first); // Some(42)
  ///
  /// final allNone = [Option.none<int>(), Option.none<int>()];
  /// final empty = Options.firstSome(allNone);
  /// print(empty); // None
  /// ```
  ///
  static Option<T> firstSome<T>(Iterable<Option<T>> options) {
    for (final option in options) {
      if (option case Some()) {
        return option;
      }
    }
    return None<T>();
  }

  /// Returns the last Some value, or None if all are None.
  ///
  ///
  ///
  /// ```dart
  /// final options = [Option.some(1), Option.none<int>(), Option.some(42)];
  /// final last = Options.lastSome(options);
  /// print(last); // Some(42)
  /// ```
  ///
  static Option<T> lastSome<T>(Iterable<Option<T>> options) {
    Option<T> result = None<T>();
    for (final option in options) {
      if (option case Some()) {
        result = option;
      }
    }
    return result;
  }

  /// Flattens an Option of Option into a single Option.
  /// Similar to Haskell's `join`.
  ///
  ///
  ///
  /// ```dart
  /// final nested = Option.some(Option.some(42));
  /// final flattened = Options.flatten(nested);
  /// print(flattened); // Some(42)
  ///
  /// final nestedNone = Option.some(Option.none<int>());
  /// final flattenedNone = Options.flatten(nestedNone);
  /// print(flattenedNone); // None
  /// ```
  ///
  static Option<T> flatten<T>(Option<Option<T>> nested) {
    return switch (nested) {
      Some(:final value) => value,
      None() => None<T>(),
    };
  }

  /// Creates an Option that contains the provided value if the condition is true.
  /// Useful for conditional Option creation.
  ///
  ///
  ///
  /// ```dart
  /// final option1 = Options.when(true, () => 42);
  /// print(option1); // Some(42)
  ///
  /// final option2 = Options.when(false, () => 42);
  /// print(option2); // None
  /// ```
  ///
  static Option<T> when<T>(bool condition, T Function() value) {
    return condition ? Some(value()) : None<T>();
  }

  /// Creates an Option that contains the provided value if the condition is true.
  /// Non-lazy version of `when`.
  ///
  ///
  ///
  /// ```dart
  /// final option1 = Options.guard(true, 42);
  /// print(option1); // Some(42)
  ///
  /// final option2 = Options.guard(false, 42);
  /// print(option2); // None
  /// ```
  ///
  static Option<T> guard<T>(bool condition, T value) {
    return condition ? Some(value) : None<T>();
  }

  /// Converts an Option to a nullable value.
  static T? toNullable<T>(Option<T> option) {
    return switch (option) {
      Some(:final value) => value,
      None() => null,
    };
  }

  /// Zips two Options together.
  /// Returns Some with a tuple if both Options are Some, otherwise None.
  ///
  ///
  ///
  /// ```dart
  /// final a = Option.some(1);
  /// final b = Option.some('hello');
  /// final zipped = Options.zip(a, b);
  /// print(zipped); // Some((1, 'hello'))
  ///
  /// final none = Option.none<int>();
  /// final failed = Options.zip(none, b);
  /// print(failed); // None
  /// ```
  ///
  static Option<(A, B)> zip<A, B>(Option<A> a, Option<B> b) {
    return switch ((a, b)) {
      (Some(:final value), Some(value: final valueB)) => Some((value, valueB)),
      _ => None<(A, B)>(),
    };
  }

  /// Zips three Options together.
  static Option<(A, B, C)> zip3<A, B, C>(
    Option<A> a,
    Option<B> b,
    Option<C> c,
  ) {
    return switch ((a, b, c)) {
      (
        Some(:final value),
        Some(value: final valueB),
        Some(value: final valueC),
      ) =>
        Some((value, valueB, valueC)),
      _ => None<(A, B, C)>(),
    };
  }

  /// Unzips an Option of tuple into a tuple of Options.
  ///
  ///
  ///
  /// ```dart
  /// final zipped = Option.some((1, 'hello'));
  /// final (a, b) = Options.unzip(zipped);
  /// print(a); // Some(1)
  /// print(b); // Some('hello')
  ///
  /// final none = Option.none<(int, String)>();
  /// final (noneA, noneB) = Options.unzip(none);
  /// print(noneA); // None
  /// print(noneB); // None
  /// ```
  ///
  static (Option<A>, Option<B>) unzip<A, B>(Option<(A, B)> option) {
    return switch (option) {
      Some(:final value) => (Some(value.$1), Some(value.$2)),
      None() => (None<A>(), None<B>()),
    };
  }
}
