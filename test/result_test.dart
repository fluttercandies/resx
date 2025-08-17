import 'package:test/test.dart';
import 'package:resx/resx.dart';

void main() {
  group('Result', () {
    group('Creation', () {
      test('creates Ok result', () {
        const result = Result.ok(42);
        expect(result.isOk, isTrue);
        expect(result.isErr, isFalse);
        expect(result.value, equals(42));
      });

      test('creates Err result', () {
        const result = Result<int, String>.err('error');
        expect(result.isOk, isFalse);
        expect(result.isErr, isTrue);
        expect(result.error, equals('error'));
      });

      test('creates from function that succeeds', () {
        final result = Result.from(() => 42);
        expect(result.isOk, isTrue);
        expect(result.value, equals(42));
      });

      test('creates from function that throws', () {
        final result = Result.from(() => int.parse('abc'));
        expect(result.isErr, isTrue);
        expect(result.error, isA<FormatException>());
      });

      test('creates from async function that succeeds', () async {
        final result = await Result.fromAsync<int, Object>(() async => 42);
        expect(result.isOk, isTrue);
        expect(result.value, equals(42));
      });

      test('creates from async function that throws', () async {
        final result = await Result.fromAsync<int, String>(() async {
          throw 'error';
        });
        expect(result.isErr, isTrue);
        expect(result.error, equals('error'));
      });
    });

    group('Map operations', () {
      test('maps Ok value', () {
        final result = const Result.ok(5).map((x) => x * 2);
        expect(result.isOk, isTrue);
        expect(result.value, equals(10));
      });

      test('maps Err value', () {
        final result = const Result<int, String>.err('error').map((x) => x * 2);
        expect(result.isErr, isTrue);
        expect(result.error, equals('error'));
      });

      test('maps error value', () {
        final result =
            const Result<int, String>.err('error').mapErr((e) => 'Error: $e');
        expect(result.isErr, isTrue);
        expect(result.error, equals('Error: error'));
      });

      test('bimaps both values', () {
        final okResult = const Result.ok(5).bimap((x) => x * 2, (e) => 'Error: $e');
        expect(okResult.isOk, isTrue);
        expect(okResult.value, equals(10));

        final errResult = const Result<int, String>.err('fail')
            .bimap((x) => x * 2, (e) => 'Error: $e');
        expect(errResult.isErr, isTrue);
        expect(errResult.error, equals('Error: fail'));
      });
    });

    group('FlatMap operations', () {
      test('flatMaps Ok value', () {
        final result = const Result.ok(5).flatMap((x) => Result.ok(x * 2));
        expect(result.isOk, isTrue);
        expect(result.value, equals(10));
      });

      test('flatMaps Ok to Err', () {
        final result = const Result.ok(5).flatMap((x) => const Result.err('error'));
        expect(result.isErr, isTrue);
        expect(result.error, equals('error'));
      });

      test('flatMaps Err value', () {
        final result =
            const Result<int, String>.err('error').flatMap((x) => Result.ok(x * 2));
        expect(result.isErr, isTrue);
        expect(result.error, equals('error'));
      });

      test('flatMapErr with Err value', () {
        final result =
            const Result<int, String>.err('error').flatMapErr((e) => const Result.ok(0));
        expect(result.isOk, isTrue);
        expect(result.value, equals(0));
      });
    });

    group('Utility methods', () {
      test('valueOr returns value for Ok', () {
        const result = Result.ok(42);
        expect(result.valueOr(0), equals(42));
      });

      test('valueOr returns default for Err', () {
        const result = Result<int, String>.err('error');
        expect(result.valueOr(0), equals(0));
      });

      test('valueOrElse returns value for Ok', () {
        const result = Result.ok(42);
        expect(result.valueOrElse((e) => 0), equals(42));
      });

      test('valueOrElse returns computed default for Err', () {
        const result = Result<int, String>.err('error');
        expect(result.valueOrElse((e) => e.length), equals(5));
      });

      test('tap executes for Ok', () {
        var called = false;
        final result = const Result.ok(42).tap((value) => called = true);
        expect(called, isTrue);
        expect(result.value, equals(42));
      });

      test('tap does not execute for Err', () {
        var called = false;
        final result =
            const Result<int, String>.err('error').tap((value) => called = true);
        expect(called, isFalse);
        expect(result.error, equals('error'));
      });

      test('tapErr executes for Err', () {
        var called = false;
        final result =
            const Result<int, String>.err('error').tapErr((error) => called = true);
        expect(called, isTrue);
        expect(result.error, equals('error'));
      });

      test('tapErr does not execute for Ok', () {
        var called = false;
        final result = const Result.ok(42).tapErr((error) => called = true);
        expect(called, isFalse);
        expect(result.value, equals(42));
      });
    });

    group('Combining operations', () {
      test('or returns first if Ok', () {
        const result1 = Result.ok(42);
        const result2 = Result.ok(10);
        expect(result1.or(result2).value, equals(42));
      });

      test('or returns second if first is Err', () {
        const result1 = Result<int, String>.err('error');
        const result2 = Result<int, String>.ok(10);
        expect(result1.or(result2).value, equals(10));
      });

      test('orElse returns first if Ok', () {
        const result = Result.ok(42);
        expect(result.orElse((e) => const Result.ok(0)).value, equals(42));
      });

      test('orElse returns computed if Err', () {
        const result = Result<int, String>.err('error');
        expect(result.orElse((e) => Result.ok(e.length)).value, equals(5));
      });

      test('and returns second if first is Ok', () {
        const result1 = Result.ok(42);
        const result2 = Result.ok('hello');
        expect(result1.and(result2).value, equals('hello'));
      });

      test('and returns first if first is Err', () {
        const result1 = Result<int, String>.err('error');
        const result2 = Result<String, String>.ok('hello');
        expect(result1.and(result2).error, equals('error'));
      });

      test('andThen returns computed if first is Ok', () {
        const result = Result.ok(5);
        expect(
            result.andThen((value) => Result.ok(value * 2)).value, equals(10));
      });

      test('andThen returns first if first is Err', () {
        const result = Result<int, String>.err('error');
        expect(result.andThen((value) => Result.ok(value * 2)).error,
            equals('error'));
      });
    });

    group('Fold operations', () {
      test('fold executes onOk for Ok', () {
        const result = Result.ok(42);
        final folded =
            result.fold((value) => 'Value: $value', (error) => 'Error: $error');
        expect(folded, equals('Value: 42'));
      });

      test('fold executes onErr for Err', () {
        const result = Result<int, String>.err('error');
        final folded =
            result.fold((value) => 'Value: $value', (error) => 'Error: $error');
        expect(folded, equals('Error: error'));
      });

      test('match executes onOk for Ok', () {
        var result = '';
        const Result.ok(42).match(
          (value) => result = 'Value: $value',
          (error) => result = 'Error: $error',
        );
        expect(result, equals('Value: 42'));
      });

      test('match executes onErr for Err', () {
        var result = '';
        const Result<int, String>.err('error').match(
          (value) => result = 'Value: $value',
          (error) => result = 'Error: $error',
        );
        expect(result, equals('Error: error'));
      });
    });

    group('Conversion operations', () {
      test('toNullable returns value for Ok', () {
        const result = Result.ok(42);
        expect(result.toNullable(), equals(42));
      });

      test('toNullable returns null for Err', () {
        const result = Result<int, String>.err('error');
        expect(result.toNullable(), isNull);
      });

      test('toList returns list with value for Ok', () {
        const result = Result.ok(42);
        expect(result.toList(), equals([42]));
      });

      test('toList returns empty list for Err', () {
        const result = Result<int, String>.err('error');
        expect(result.toList(), isEmpty);
      });

      test('toIterable returns iterable with value for Ok', () {
        const result = Result.ok(42);
        expect(result.toIterable().toList(), equals([42]));
      });

      test('toIterable returns empty iterable for Err', () {
        const result = Result<int, String>.err('error');
        expect(result.toIterable().toList(), isEmpty);
      });
    });

    group('Equality and hashCode', () {
      test('equal Ok results are equal', () {
        const result1 = Result.ok(42);
        const result2 = Result.ok(42);
        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('equal Err results are equal', () {
        const result1 = Result<int, String>.err('error');
        const result2 = Result<int, String>.err('error');
        expect(result1, equals(result2));
        expect(result1.hashCode, equals(result2.hashCode));
      });

      test('different results are not equal', () {
        const result1 = Result.ok(42);
        const result2 = Result<int, String>.err('error');
        expect(result1, isNot(equals(result2)));
      });
    });

    group('toString', () {
      test('Ok toString', () {
        const result = Result.ok(42);
        expect(result.toString(), equals('Ok(42)'));
      });

      test('Err toString', () {
        const result = Result<int, String>.err('error');
        expect(result.toString(), equals('Err(error)'));
      });
    });
  });

  group('Results utility', () {
    test('combine all Ok results', () {
      final results = [const Result.ok(1), const Result.ok(2), const Result.ok(3)];
      final combined = Results.combine(results);
      expect(combined.isOk, isTrue);
      expect(combined.value, equals([1, 2, 3]));
    });

    test('combine with one Err result', () {
      final results = [
        const Result.ok(1),
        const Result<int, String>.err('error'),
        const Result.ok(3)
      ];
      final combined = Results.combine(results);
      expect(combined.isErr, isTrue);
      expect(combined.error, equals('error'));
    });

    test('traverse with success', () {
      final values = ['1', '2', '3'];
      final result = Results.traverse<String, int, FormatException>(
        values,
        (s) => Result.from(() => int.parse(s)),
      );
      expect(result.isOk, isTrue);
      expect(result.value, equals([1, 2, 3]));
    });

    test('traverse with failure', () {
      final values = ['1', 'abc', '3'];
      final result = Results.traverse<String, int, FormatException>(
        values,
        (s) => Result.from(() => int.parse(s)),
      );
      expect(result.isErr, isTrue);
      expect(result.error, isA<FormatException>());
    });

    test('fromNullable with value', () {
      final result = Results.fromNullable(42, 'null error');
      expect(result.isOk, isTrue);
      expect(result.value, equals(42));
    });

    test('fromNullable with null', () {
      final result = Results.fromNullable<int, String>(null, 'null error');
      expect(result.isErr, isTrue);
      expect(result.error, equals('null error'));
    });

    test('lift2 with two Ok results', () {
      const result1 = Result.ok(2);
      const result2 = Result.ok(3);
      final result = Results.lift2(result1, result2, (a, b) => a + b);
      expect(result.isOk, isTrue);
      expect(result.value, equals(5));
    });

    test('lift2 with one Err result', () {
      const result1 = Result<int, String>.err('error');
      const result2 = Result.ok(3);
      final result = Results.lift2(result1, result2, (a, b) => a + b);
      expect(result.isErr, isTrue);
      expect(result.error, equals('error'));
    });

    test('sequence equals combine', () {
      final results = [const Result.ok(1), const Result.ok(2)];
      final seq = Results.sequence(results);
      expect(seq.isOk, isTrue);
      expect(seq.value, equals([1, 2]));
    });

    test('partition splits oks and errs', () {
      final results = [
        const Result.ok(1),
        const Result<int, String>.err('e1'),
        const Result.ok(3)
      ];
      final (oks, errs) = Results.partition(results);
      expect(oks, equals([1, 3]));
      expect(errs, equals(['e1']));
    });
  });

  group('Result additional methods', () {
    test('flatten', () {
      // Test flatten with nested Ok
      const nested = Result.ok(Result.ok(42));
      final flattened = nested.flatten<int>();
      expect(flattened.isOk, isTrue);
      expect(flattened.value, equals(42));

      // Test flatten with Err containing Result
      const errWithResult =
          Result<Result<int, String>, String>.err('outer error');
      final flattenedErr = errWithResult.flatten<int>();
      expect(flattenedErr.isErr, isTrue);
      expect(flattenedErr.error, equals('outer error'));
    });

    test('inspect', () {
      var inspected = false;
      final result = const Result.ok(42).inspect((value) {
        inspected = true;
        expect(value, equals(42));
      });
      expect(inspected, isTrue);
      expect(result.value, equals(42));

      // Test inspect with Err
      var inspectedErr = false;
      final errResult = const Result.err('error').inspect((value) {
        inspectedErr = true;
      });
      expect(inspectedErr, isFalse);
      expect(errResult.error, equals('error'));
    });

    test('inspectErr', () {
      var inspected = false;
      final result = const Result.err('error').inspectErr((error) {
        inspected = true;
        expect(error, equals('error'));
      });
      expect(inspected, isTrue);
      expect(result.error, equals('error'));

      // Test inspectErr with Ok
      var inspectedOk = false;
      final okResult = const Result.ok(42).inspectErr((error) {
        inspectedOk = true;
      });
      expect(inspectedOk, isFalse);
      expect(okResult.value, equals(42));
    });

    test('transpose', () {
      // Test transpose with Ok(Some)
      const okSome = Result.ok(Option.some(42));
      final transposed = okSome.transpose<int>();
      expect(transposed.isSome, isTrue);
      final innerResult = transposed.value;
      expect(innerResult.isOk, isTrue);
      expect(innerResult.value, equals(42));

      // Test transpose with Ok(None)
      const okNone = Result.ok(Option<int>.none());
      final transposedNone = okNone.transpose<int>();
      expect(transposedNone.isNone, isTrue);
    });

    test('ensure and ensureElse', () {
      final r1 = const Result.ok(10).ensure((v) => v > 5, 'too small');
      expect(r1.isOk, isTrue);

      final r2 = const Result.ok(3).ensure((v) => v > 5, 'too small');
      expect(r2.isErr, isTrue);
      expect(r2.error, equals('too small'));

      final r3 = const Result.ok(3).ensureElse((v) => v > 5, (v) => 'min 6, got $v');
      expect(r3.isErr, isTrue);
      expect(r3.error, equals('min 6, got 3'));
    });

    test('swap', () {
      final r1 = const Result.ok(42).swap();
      expect(r1.isErr, isTrue);
      expect(r1.error, equals(42));

      final r2 = const Result<int, String>.err('e').swap();
      expect(r2.isOk, isTrue);
      expect(r2.value, equals('e'));
    });
  });
}
