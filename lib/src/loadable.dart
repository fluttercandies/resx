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

  bool get isLoading => this is Loading<T, E>;
  bool get hasData => this is Data<T, E>;
  bool get hasError => this is LoadError<T, E>;

  T get value => switch (this) {
        Data(:final value) => value,
        _ => throw StateError('No data'),
      };

  E get error => switch (this) {
        LoadError(:final error) => error,
        _ => throw StateError('No error'),
      };

  R fold<R>(R Function() onLoading, R Function(T) onData,
          R Function(E) onError) =>
      switch (this) {
        Loading() => onLoading(),
        Data(:final value) => onData(value),
        LoadError(:final error) => onError(error),
      };

  /// Convert from Result to Loadable
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

  void setLoading() => _state = Loadable<T, E>.loading();
  void setData(T value) => _state = Loadable<T, E>.data(value);
  void setError(E error) => _state = Loadable<T, E>.error(error);

  void setFromResult(Result<T, E> r) => _state = Loadable.fromResult(r);
}
