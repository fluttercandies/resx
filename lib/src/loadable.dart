import 'package:meta/meta.dart';
import 'result.dart';

/// A minimal state container representing loading states for async data.
///
/// Keeps API surface tiny while being expressive: Loading, Data, Error.
@immutable
sealed class Loadable<T, E> {
  const Loadable();

  const factory Loadable.loading() = Loading<T, E>;
  const factory Loadable.data(T value) = Data<T, E>;
  const factory Loadable.error(E error) = LoadError<T, E>;

  /// Whether the state is Loading.
  ///
  /// ```dart
  /// final s = Loadable<int, String>.loading();
  /// print(s.isLoading); // true
  /// ```
  bool get isLoading => this is Loading<T, E>;

  /// Whether the state holds Data.
  ///
  /// ```dart
  /// final s = Loadable<int, String>.data(42);
  /// print(s.hasData); // true
  /// ```
  bool get hasData => this is Data<T, E>;

  /// Whether the state holds Error.
  ///
  /// ```dart
  /// final s = Loadable<int, String>.error('oops');
  /// print(s.hasError); // true
  /// ```
  bool get hasError => this is LoadError<T, E>;

  /// Get the data value or throw if not Data.
  ///
  /// ```dart
  /// final d = Loadable<int, String>.data(1);
  /// print(d.value); // 1
  /// ```
  T get value => switch (this) {
        Data(:final value) => value,
        _ => throw StateError('No data'),
      };

  /// Get the error value or throw if not Error.
  ///
  /// ```dart
  /// final e = Loadable<int, String>.error('x');
  /// print(e.error); // 'x'
  /// ```
  E get error => switch (this) {
        LoadError(:final error) => error,
        _ => throw StateError('No error'),
      };

  /// Pattern-match the state.
  ///
  /// ```dart
  /// final s = Loadable<int, String>.data(2);
  /// final text = s.fold(
  ///   () => 'loading',
  ///   (v) => 'data $v',
  ///   (e) => 'error $e',
  /// );
  /// // text == 'data 2'
  /// ```
  R fold<R>(R Function() onLoading, R Function(T) onData,
          R Function(E) onError) =>
      switch (this) {
        Loading() => onLoading(),
        Data(:final value) => onData(value),
        LoadError(:final error) => onError(error),
      };

  /// Convert from Result to Loadable
  ///
  /// ```dart
  /// final ok = Result<int, String>.ok(1);
  /// final s1 = Loadable.fromResult(ok); // Data(1)
  /// final err = Result<int, String>.err('e');
  /// final s2 = Loadable.fromResult(err); // Error('e')
  /// ```
  static Loadable<T, E> fromResult<T, E>(Result<T, E> r) =>
      r.fold<Loadable<T, E>>(Data.new, LoadError.new);

  @override
  String toString() => switch (this) {
        Loading() => 'Loading',
        Data(:final value) => 'Data($value)',
        LoadError(:final error) => 'Error($error)',
      };
}

final class Loading<T, E> extends Loadable<T, E> {
  const Loading();
}

final class Data<T, E> extends Loadable<T, E> {
  const Data(this.value);
  @override
  final T value;
}

final class LoadError<T, E> extends Loadable<T, E> {
  const LoadError(this.error);
  @override
  final E error;
}

/// A tiny controller to manage Loadable state transitions.
class LoadableController<T, E> {
  Loadable<T, E> _state = Loadable<T, E>.loading();
  Loadable<T, E> get state => _state;

  /// Set state to Loading.
  ///
  /// ```dart
  /// final c = LoadableController<int, String>();
  /// c.setLoading();
  /// print(c.state.isLoading); // true
  /// ```
  void setLoading() => _state = Loadable<T, E>.loading();

  /// Set state to Data.
  ///
  /// ```dart
  /// final c = LoadableController<int, String>();
  /// c.setData(42);
  /// print(c.state.hasData); // true
  /// ```
  void setData(T value) => _state = Loadable<T, E>.data(value);

  /// Set state to Error.
  ///
  /// ```dart
  /// final c = LoadableController<int, String>();
  /// c.setError('x');
  /// print(c.state.hasError); // true
  /// ```
  void setError(E error) => _state = Loadable<T, E>.error(error);

  /// Set state from a Result value.
  ///
  /// ```dart
  /// final c = LoadableController<int, String>();
  /// c.setFromResult(Result.ok(1));
  /// print(c.state.hasData); // true
  /// ```
  void setFromResult(Result<T, E> r) => _state = Loadable.fromResult(r);
}
