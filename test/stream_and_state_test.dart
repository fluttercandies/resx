import 'dart:async';
import 'package:test/test.dart';
import 'package:resx/resx.dart';

void main() {
  group('Stream extensions', () {
    test('toResultStream maps data to Ok and errors to Err', () async {
      final controller = StreamController<int>();
      final results = <Result<int, String>>[];
      final sub =
          controller.stream.toResultStream<String>().listen(results.add);

      controller.add(1);
      controller.add(2);
      controller.addError('boom');
      await controller.close();
      await sub.asFuture<void>();

      expect(results[0].isOk, isTrue);
      expect(results[1].isOk, isTrue);
      expect(results[2].isErr, isTrue);
      expect((results[2] as Err<int, String>).error, equals('boom'));
    });

    test('collectToResult collects values or returns first error', () async {
      final s1 = Stream.fromIterable([1, 2, 3]);
      final r1 = await s1.collectToResult<Object>();
      expect(r1.isOk, isTrue);
      expect(r1.value, equals([1, 2, 3]));

      final controller = StreamController<int>();
      // ignore: unawaited_futures
      Future(() async {
        controller.add(1);
        controller.addError(ArgumentError('x'));
        await controller.close();
      });
      final r2 = await controller.stream.collectToResult<Object>();
      expect(r2.isErr, isTrue);
      expect(r2.error, isA<ArgumentError>());
    });
  });

  group('Loadable state', () {
    test('fold and transitions', () {
      final c = LoadableController<int, String>();
      expect(c.state.isLoading, isTrue);

      c.setData(42);
      expect(c.state.hasData, isTrue);
      expect(c.state.value, equals(42));

      c.setError('e');
      expect(c.state.hasError, isTrue);
      expect(c.state.error, equals('e'));

      final text = c.state.fold(
        () => 'loading',
        (v) => 'data $v',
        (e) => 'error $e',
      );
      expect(text, equals('error e'));
    });

    test('from Result', () {
      final ok = Loadable.fromResult<int, String>(const Result.ok(1));
      expect(ok.hasData, isTrue);
      final err = Loadable.fromResult<int, String>(const Result.err('x'));
      expect(err.hasError, isTrue);
    });
  });
}
