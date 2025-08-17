import 'dart:async';
import 'result.dart';

/// Extensions to convert Stream events into Result streams.
extension StreamToResultExtensions<T> on Stream<T> {
  /// Maps each data event to Ok, and errors to Err.
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
