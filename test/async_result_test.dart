import 'package:test/test.dart';
import 'package:resx/resx.dart';

void main() {
  group('AsyncResult', () {
    group('creation from futures', () {
      test('future with success value', () async {
        final future = Future.value(42);
        final asyncResult = future.toAsyncResult<Object>();
        final result = await asyncResult;
        expect(result.isOk, isTrue);
        expect(result.value, equals(42));
      });

      test('future with error', () async {
        final future = Future<int>.error('error');
        final asyncResult = future.toAsyncResult<Object>();
        final result = await asyncResult;
        expect(result.isErr, isTrue);
        expect(result.error, equals('error'));
      });
    });

    group('working with actual async operations', () {
      test('parsing strings asynchronously', () async {
        parseAsync(String s) async {
          await Future.delayed(const Duration(milliseconds: 5));
          return int.parse(s);
        }

        final result = await parseAsync('42').toAsyncResult<Object>();
        expect(result.isOk, isTrue);
        expect(result.value, equals(42));
      });

      test('handling async parsing errors', () async {
        parseAsync(String s) async {
          await Future.delayed(const Duration(milliseconds: 5));
          return int.parse(s);
        }

        final result = await parseAsync('invalid').toAsyncResult<Object>();
        expect(result.isErr, isTrue);
        expect(result.error, isA<FormatException>());
      });

      test('complex async workflow', () async {
        fetchData(int id) async {
          await Future.delayed(const Duration(milliseconds: 10));
          if (id > 0) return 'data-$id';
          throw ArgumentError('Invalid ID');
        }

        processData(String data) async {
          await Future.delayed(const Duration(milliseconds: 5));
          return data.toUpperCase();
        }

        final result1 = await fetchData(42).toAsyncResult<Object>();
        if (result1.isOk) {
          final result2 =
              await processData(result1.value).toAsyncResult<Object>();
          expect(result2.isOk, isTrue);
          expect(result2.value, equals('DATA-42'));
        } else {
          fail('First operation should succeed');
        }
      });

      test('async workflow with error', () async {
        fetchData(int id) async {
          await Future.delayed(const Duration(milliseconds: 10));
          if (id > 0) return 'data-$id';
          throw ArgumentError('Invalid ID');
        }

        final result = await fetchData(-1).toAsyncResult<Object>();
        expect(result.isErr, isTrue);
        expect(result.error, isA<ArgumentError>());
      });
    });

    group('combining results', () {
      test('successful computation chain', () async {
        step1() async {
          await Future.delayed(const Duration(milliseconds: 5));
          return 10;
        }

        step2(int x) async {
          await Future.delayed(const Duration(milliseconds: 5));
          return x * 2;
        }

        step3(int x) async {
          await Future.delayed(const Duration(milliseconds: 5));
          return x + 5;
        }

        final result1 = await step1().toAsyncResult<Object>();
        expect(result1.isOk, isTrue);

        final result2 = await step2(result1.value).toAsyncResult<Object>();
        expect(result2.isOk, isTrue);

        final result3 = await step3(result2.value).toAsyncResult<Object>();
        expect(result3.isOk, isTrue);
        expect(result3.value, equals(25)); // 10 * 2 + 5 = 25
      });

      test('chain with error handling', () async {
        operation1() async {
          await Future.delayed(const Duration(milliseconds: 5));
          return 'valid';
        }

        operation2(String s) async {
          await Future.delayed(const Duration(milliseconds: 5));
          if (s == 'valid') return s.length;
          throw ArgumentError('Invalid input');
        }

        final result1 = await operation1().toAsyncResult<Object>();
        expect(result1.isOk, isTrue);

        final result2 = await operation2(result1.value).toAsyncResult<Object>();
        expect(result2.isOk, isTrue);
        expect(result2.value, equals(5)); // 'valid'.length
      });

      test('handling network-like operations', () async {
        networkCall(String endpoint) async {
          await Future.delayed(const Duration(milliseconds: 10));
          if (endpoint == 'valid') {
            return {'data': 'success'};
          } else {
            throw Exception('Network error');
          }
        }

        final validResult = await networkCall('valid').toAsyncResult<Object>();
        expect(validResult.isOk, isTrue);
        expect(validResult.value, equals({'data': 'success'}));

        final invalidResult =
            await networkCall('invalid').toAsyncResult<Object>();
        expect(invalidResult.isErr, isTrue);
        expect(invalidResult.error, isA<Exception>());
      });
    });

    group('manual combining results', () {
      test('combine returns success when all are successful', () async {
        final futures = [
          Future.value(const Result.ok(1)),
          Future.value(const Result.ok(2)),
          Future.value(const Result.ok(3)),
        ];

        final results = await Future.wait(futures);
        final combined = Results.combine(results);

        expect(combined.isOk, isTrue);
        expect(combined.value, equals([1, 2, 3]));
      });

      test('combine returns first error when any fails', () async {
        final futures = [
          Future.value(const Result.ok(1)),
          Future.value(const Result.err('error')),
          Future.value(const Result.ok(3)),
        ];

        final results = await Future.wait(futures);
        final combined = Results.combine(results);

        expect(combined.isErr, isTrue);
        expect(combined.error, equals('error'));
      });

      test('traverse equivalent with actual async operations', () async {
        final values = ['1', '2', '3'];
        final parseResults = <Future<Result<int, Object>>>[];

        for (final s in values) {
          parseResults.add(
              Future.delayed(const Duration(milliseconds: 5), () => int.parse(s))
                  .toAsyncResult<Object>());
        }

        final results = await Future.wait(parseResults);
        final combined = Results.combine(results);

        expect(combined.isOk, isTrue);
        expect(combined.value, equals([1, 2, 3]));
      });

      test('traverse equivalent with async failure', () async {
        final values = ['1', 'invalid', '3'];
        final parseResults = <Future<Result<int, Object>>>[];

        for (final s in values) {
          parseResults.add(
              Future.delayed(const Duration(milliseconds: 5), () => int.parse(s))
                  .toAsyncResult<Object>());
        }

        final results = await Future.wait(parseResults);
        final combined = Results.combine(results);

        expect(combined.isErr, isTrue);
        expect(combined.error, isA<FormatException>());
      });

      test('combine with actual async operations', () async {
        final asyncOperations = [
          Future.delayed(const Duration(milliseconds: 10), () => 1)
              .toAsyncResult<Object>(),
          Future.delayed(const Duration(milliseconds: 5), () => 2)
              .toAsyncResult<Object>(),
          Future.delayed(const Duration(milliseconds: 15), () => 3)
              .toAsyncResult<Object>(),
        ];

        final results = await Future.wait(asyncOperations);
        final combined = Results.combine(results);

        expect(combined.isOk, isTrue);
        expect(combined.value, equals([1, 2, 3]));
      });
    });

    test('ensure on AsyncResult', () async {
      final arOk =
          AsyncResult.ok<int, String>(10).ensure((v) => v > 5, 'small');
      final r1 = await arOk;
      expect(r1.isOk, isTrue);

      final arErr =
          AsyncResult.ok<int, String>(2).ensure((v) => v > 5, 'small');
      final r2 = await arErr;
      expect(r2.isErr, isTrue);
      expect(r2.error, equals('small'));
    });
  });
}
