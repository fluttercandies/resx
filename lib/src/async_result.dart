import 'dart:async';
import 'result.dart';

/// Extension type for Future<Result<T, E>> providing async-aware Result operations.
///
/// AsyncResult simplifies working with asynchronous operations that can fail,
/// providing a chainable API for async Result operations.
///
/// {@tool snippet}
///
/// ```dart
/// // Creating AsyncResults
/// final asyncResult = AsyncResult.ok(42);
/// final fromFuture = AsyncResult.from(apiCall());
///
/// // Chaining operations
/// final result = AsyncResult.ok(5)
///     .map((x) => x * 2)
///     .flatMap((x) => AsyncResult.ok(x.toString()));
///
/// final finalResult = await result;
/// print(finalResult); // Ok('10')
/// ```
/// {@end-tool}
extension type AsyncResult<T, E>(Future<Result<T, E>> _future)
    implements Future<Result<T, E>> {
  /// Creates an AsyncResult from a Future<T>.
  ///
  /// If the future completes successfully, wraps the result in Ok.
  /// If the future completes with an error, wraps it in Err.
  ///
  /// {@tool snippet}
  ///
  /// ```dart
  /// Future<String> apiCall() async => 'data';
  ///
  /// final asyncResult = AsyncResult.from<String, Object>(apiCall());
  /// final result = await asyncResult;
  /// print(result); // Ok('data')
  /// ```
  /// {@end-tool}
  static AsyncResult<T, E> from<T, E>(Future<T> future) {
    return AsyncResult(
      future
          .then<Result<T, E>>((value) => Result.ok(value))
          .catchError((error) => Result.err(error as E) as Result<T, E>),
    );
  }

  /// Creates an AsyncResult that immediately resolves to Ok.
  ///
  /// {@tool snippet}
  ///
  /// ```dart
  /// final asyncResult = AsyncResult.ok('immediate value');
  /// final result = await asyncResult;
  /// print(result); // Ok('immediate value')
  /// ```
  /// {@end-tool}
  static AsyncResult<T, E> ok<T, E>(T value) {
    return AsyncResult(Future.value(Result.ok(value)));
  }

  /// Creates an AsyncResult that immediately resolves to Err.
  ///
  /// {@tool snippet}
  ///
  /// ```dart
  /// final asyncResult = AsyncResult.err('immediate error');
  /// final result = await asyncResult;
  /// print(result); // Err('immediate error')
  /// ```
  /// {@end-tool}
  static AsyncResult<T, E> err<T, E>(E error) {
    return AsyncResult(Future.value(Result.err(error)));
  }

  /// Ensures predicate holds for Ok, otherwise converts to Err with provided error.
  AsyncResult<T, E> ensure(bool Function(T) predicate, E error) {
    return AsyncResult(_future.then((r) => r.ensure(predicate, error)));
  }

  /// Maps the success value if Ok.
  ///
  /// {@tool snippet}
  ///
  /// ```dart
  /// final asyncResult = AsyncResult.ok(21);
  /// final doubled = asyncResult.map((x) => x * 2);
  /// final result = await doubled;
  /// print(result); // Ok(42)
  /// ```
  /// {@end-tool}
  AsyncResult<U, E> map<U>(U Function(T) fn) {
    return AsyncResult(_future.then((result) => result.map(fn)));
  }

  /// Maps the error value if Err.
  ///
  /// {@tool snippet}
  ///
  /// ```dart
  /// final asyncResult = AsyncResult.err<int, String>('error');
  /// final mapped = asyncResult.mapErr((e) => 'Wrapped: $e');
  /// final result = await mapped;
  /// print(result); // Err('Wrapped: error')
  /// ```
  /// {@end-tool}
  AsyncResult<T, F> mapErr<F>(F Function(E) fn) {
    return AsyncResult(_future.then((result) => result.mapErr(fn)));
  }

  /// Chains another AsyncResult operation.
  ///
  /// {@tool snippet}
  ///
  /// ```dart
  /// final asyncResult = AsyncResult.ok('42');
  /// final chained = asyncResult.flatMap((s) =>
  ///     AsyncResult.from(Future.value(int.parse(s))));
  /// final result = await chained;
  /// print(result); // Ok(42)
  /// ```
  /// {@end-tool}
  AsyncResult<U, E> flatMap<U>(AsyncResult<U, E> Function(T) fn) {
    return AsyncResult(_future.then((result) async {
      return switch (result) {
        Ok(:final value) => await fn(value),
        Err(:final error) => Result.err(error),
      };
    }));
  }

  /// Handles both success and error cases.
  ///
  /// {@tool snippet}
  ///
  /// ```dart
  /// final asyncResult = AsyncResult.ok(42);
  /// final handled = asyncResult.fold(
  ///   (value) => 'Success: $value',
  ///   (error) => 'Error: $error',
  /// );
  /// final result = await handled;
  /// print(result); // 'Success: 42'
  /// ```
  /// {@end-tool}
  Future<U> fold<U>(U Function(T) onOk, U Function(E) onErr) {
    return _future.then((result) => result.fold(onOk, onErr));
  }

  /// Recovers from an error with a new AsyncResult.
  ///
  /// {@tool snippet}
  ///
  /// ```dart
  /// final asyncResult = AsyncResult.err<int, String>('error');
  /// final recovered = asyncResult.orElse((error) => AsyncResult.ok(0));
  /// final result = await recovered;
  /// print(result); // Ok(0)
  /// ```
  /// {@end-tool}
  AsyncResult<T, E> orElse(AsyncResult<T, E> Function(E) fn) {
    return AsyncResult(_future.then((result) async {
      return switch (result) {
        Ok(:final value) => Result.ok(value),
        Err(:final error) => await fn(error),
      };
    }));
  }

  /// Executes [fn] if the result is [Ok] and returns this result.
  AsyncResult<T, E> tap(void Function(T value) fn) {
    return AsyncResult(_future.then((result) {
      if (result case Ok(:final value)) {
        fn(value);
      }
      return result;
    }));
  }

  /// Executes [fn] if the result is [Err] and returns this result.
  AsyncResult<T, E> tapErr(void Function(E error) fn) {
    return AsyncResult(_future.then((result) {
      if (result case Err(:final error)) {
        fn(error);
      }
      return result;
    }));
  }
}

/// Utilities for working with AsyncResult.
abstract final class AsyncResults {
  /// Combines multiple AsyncResults into a single AsyncResult containing a list.
  /// Returns [Ok] with all values if all results are [Ok], otherwise returns the first [Err].
  ///
  /// {@tool snippet}
  ///
  /// ```dart
  /// final asyncResults = [
  ///   AsyncResult.ok(1),
  ///   AsyncResult.ok(2),
  ///   AsyncResult.ok(3),
  /// ];
  /// final combined = await AsyncResults.combine(asyncResults);
  /// print(combined); // Ok([1, 2, 3])
  /// ```
  /// {@end-tool}
  static Future<Result<List<T>, E>> combine<T, E>(
    Iterable<Future<Result<T, E>>> asyncResults,
  ) async {
    final results = await Future.wait(asyncResults);
    return Results.combine(results);
  }

  /// Traverses a list of values, applying [fn] to each and collecting the results.
  ///
  /// {@tool snippet}
  ///
  /// ```dart
  /// final numbers = ['1', '2', '3'];
  /// final parsed = await AsyncResults.traverse<String, int, String>(
  ///   numbers,
  ///   (s) => AsyncResult.from(Future.value(int.parse(s))),
  /// );
  /// print(parsed); // Ok([1, 2, 3])
  /// ```
  /// {@end-tool}
  static Future<Result<List<U>, E>> traverse<T, U, E>(
    Iterable<T> values,
    Future<Result<U, E>> Function(T) fn,
  ) async {
    final asyncResults = values.map(fn);
    return combine(asyncResults);
  }

  /// Sequences a list of AsyncResults into a single AsyncResult of list.
  static Future<Result<List<T>, E>> sequence<T, E>(
    Iterable<Future<Result<T, E>>> asyncResults,
  ) =>
      combine(asyncResults);

  /// Partitions results into (oks, errs) preserving order.
  static Future<(List<T>, List<E>)> partition<T, E>(
    Iterable<Future<Result<T, E>>> asyncResults,
  ) async {
    final results = await Future.wait(asyncResults);
    return Results.partition(results);
  }
}
