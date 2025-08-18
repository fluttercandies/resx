import 'dart:async';
import 'result.dart';

/// Extensions to convert Stream events into Result streams.
extension StreamToResultExtensions<T> on Stream<T> {
  /// Maps each data event to Ok, and errors to Err.
  ///
  /// ```dart
  /// // Convert a stream of ints into a stream of Result<int, String>
  /// final controller = StreamController<int>();
  /// final results = <Result<int, String>>[];
  /// final sub = controller.stream
  ///     .toResultStream<String>()
  ///     .listen(results.add);
  ///
  /// controller
  ///   ..add(1)
  ///   ..add(2)
  ///   ..addError('boom');
  /// await controller.close();
  /// await sub.asFuture<void>();
  /// await sub.cancel();
  ///
  /// // results: [Ok(1), Ok(2), Err('boom')]
  /// ```
  Stream<Result<T, E>> toResultStream<E>() {
    late StreamController<Result<T, E>> controller;
    controller = StreamController<Result<T, E>>(
      onListen: () {
        final sub = listen(
          (data) => controller.add(Result.ok(data)),
          onError: (Object e, StackTrace st) =>
              controller.add(Result.err(e as E)),
          onDone: controller.close,
          cancelOnError: false,
        );
        controller.onCancel = () => sub.cancel();
      },
      sync: true,
    );
    return controller.stream;
  }

  /// Folds the stream into a single Result with a list of values;
  /// returns Err with the first error encountered.
  ///
  /// ```dart
  /// // Happy path collects all values
  /// final s1 = Stream.fromIterable([1, 2, 3]);
  /// final r1 = await s1.collectToResult<Object>();
  /// // r1 == Ok([1, 2, 3])
  ///
  /// // Error path returns first error as Err
  /// final c = StreamController<int>();
  /// // ignore: unawaited_futures
  /// Future(() async {
  ///   c.add(1);
  ///   c.addError(ArgumentError('x'));
  ///   await c.close();
  /// });
  /// final r2 = await c.stream.collectToResult<Object>();
  /// // r2.isErr == true, r2.error is ArgumentError
  /// ```
  Future<Result<List<T>, E>> collectToResult<E>() async {
    final values = <T>[];
    try {
      await for (final v in this) {
        values.add(v);
      }
      return Result.ok(values);
    } catch (e) {
      return Result.err(e as E);
    }
  }
}
