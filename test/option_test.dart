import 'package:test/test.dart';
import 'package:resx/src/option.dart';
import 'package:resx/src/result.dart';

void main() {
  group('Option', () {
    group('creation', () {
      test('Some creates some option', () {
        const option = Option.some(42);
        expect(option.isSome, isTrue);
        expect(option.isNone, isFalse);
        expect(option.value, equals(42));
      });

      test('None creates none option', () {
        const option = Option<int>.none();
        expect(option.isNone, isTrue);
        expect(option.isSome, isFalse);
        expect(() => option.value, throwsStateError);
      });

      test('fromNullable creates Some for non-null value', () {
        final option = Option.fromNullable('test');
        expect(option.isSome, isTrue);
        expect(option.value, equals('test'));
      });

      test('fromNullable creates None for null value', () {
        final option = Option.fromNullable(null);
        expect(option.isNone, isTrue);
      });
    });

    group('mapping', () {
      test('map transforms Some value', () {
        const option = Option.some(5);
        final mapped = option.map((x) => x * 2);
        expect(mapped.isSome, isTrue);
        expect(mapped.value, equals(10));
      });

      test('map does nothing to None', () {
        const option = Option<int>.none();
        final mapped = option.map((x) => x * 2);
        expect(mapped.isNone, isTrue);
      });

      test('flatMap transforms Some value', () {
        const option = Option.some(5);
        final mapped = option.flatMap((x) => Option.some(x * 2));
        expect(mapped.isSome, isTrue);
        expect(mapped.value, equals(10));
      });

      test('flatMap flattens nested options', () {
        const option = Option.some(5);
        final mapped = option.flatMap((x) => const Option<int>.none());
        expect(mapped.isNone, isTrue);
      });

      test('andThen is alias for flatMap', () {
        const option = Option.some(5);
        final mapped = option.andThen((x) => Option.some(x * 2));
        expect(mapped.isSome, isTrue);
        expect(mapped.value, equals(10));
      });
    });

    group('filtering', () {
      test('filter keeps Some when predicate is true', () {
        const option = Option.some(5);
        final filtered = option.filter((x) => x > 3);
        expect(filtered.isSome, isTrue);
        expect(filtered.value, equals(5));
      });

      test('filter converts to None when predicate is false', () {
        const option = Option.some(5);
        final filtered = option.filter((x) => x > 10);
        expect(filtered.isNone, isTrue);
      });

      test('filter does nothing to None', () {
        const option = Option<int>.none();
        final filtered = option.filter((x) => x > 3);
        expect(filtered.isNone, isTrue);
      });
    });

    group('combining', () {
      test('and returns other when Some', () {
        const option1 = Option.some(1);
        const option2 = Option.some(2);
        final result = option1.and(option2);
        expect(result.isSome, isTrue);
        expect(result.value, equals(2));
      });

      test('and returns None when None', () {
        const option1 = Option<int>.none();
        const option2 = Option.some(2);
        final result = option1.and(option2);
        expect(result.isNone, isTrue);
      });

      test('or returns self when Some', () {
        const option1 = Option.some(1);
        const option2 = Option.some(2);
        final result = option1.or(option2);
        expect(result.isSome, isTrue);
        expect(result.value, equals(1));
      });

      test('or returns other when None', () {
        const option1 = Option<int>.none();
        const option2 = Option.some(2);
        final result = option1.or(option2);
        expect(result.isSome, isTrue);
        expect(result.value, equals(2));
      });

      test('orElse with lazy computation', () {
        const option1 = Option<int>.none();
        const option2 = Option.some(42);
        final result = option1.orElse(() => option2);
        expect(result.isSome, isTrue);
        expect(result.value, equals(42));
      });
    });

    group('folding', () {
      test('fold transforms Some value', () {
        const option = Option.some(5);
        final result = option.fold((x) => x * 2, () => 0);
        expect(result, equals(10));
      });

      test('fold uses default for None', () {
        const option = Option<int>.none();
        final result = option.fold((x) => x * 2, () => 0);
        expect(result, equals(0));
      });

      test('valueOr returns value for Some', () {
        const option = Option.some(5);
        final result = option.valueOr(0);
        expect(result, equals(5));
      });

      test('valueOr returns default for None', () {
        const option = Option<int>.none();
        final result = option.valueOr(0);
        expect(result, equals(0));
      });

      test('valueOrElse returns value for Some', () {
        const option = Option.some(5);
        final result = option.valueOrElse(() => 0);
        expect(result, equals(5));
      });

      test('valueOrElse returns computed default for None', () {
        const option = Option<int>.none();
        final result = option.valueOrElse(() => 42);
        expect(result, equals(42));
      });
    });

    group('tapping', () {
      test('tap calls function for Some', () {
        var called = false;
        const option = Option.some(5);
        final result = option.tap((x) => called = true);
        expect(called, isTrue);
        expect(result, equals(option));
      });

      test('tap does nothing for None', () {
        var called = false;
        const option = Option<int>.none();
        final result = option.tap((x) => called = true);
        expect(called, isFalse);
        expect(result, equals(option));
      });
    });

    group('matching', () {
      test('match calls onSome for Some', () {
        var result = '';
        const option = Option.some(42);
        option.match((value) => result = 'some: $value', () => result = 'none');
        expect(result, equals('some: 42'));
      });

      test('match calls onNone for None', () {
        var result = '';
        const option = Option<int>.none();
        option.match((value) => result = 'some: $value', () => result = 'none');
        expect(result, equals('none'));
      });
    });

    group('conversion', () {
      test('toList returns list with value for Some', () {
        const option = Option.some(5);
        final list = option.toList();
        expect(list, equals([5]));
      });

      test('toList returns empty list for None', () {
        const option = Option<int>.none();
        final list = option.toList();
        expect(list, isEmpty);
      });

      test('toIterable returns iterable with value for Some', () {
        const option = Option.some(5);
        final iterable = option.toIterable();
        expect(iterable.toList(), equals([5]));
      });

      test('toIterable returns empty iterable for None', () {
        const option = Option<int>.none();
        final iterable = option.toIterable();
        expect(iterable.toList(), isEmpty);
      });

      test('toNullable returns value for Some', () {
        const option = Option.some(5);
        final nullable = option.toNullable();
        expect(nullable, equals(5));
      });

      test('toNullable returns null for None', () {
        const option = Option<int>.none();
        final nullable = option.toNullable();
        expect(nullable, isNull);
      });

      test('toResult returns Ok for Some', () {
        const option = Option.some(5);
        final result = option.toResult('error');
        expect(result.isOk, isTrue);
        expect(result.value, equals(5));
      });

      test('toResult returns Err for None', () {
        const option = Option<int>.none();
        final result = option.toResult('error');
        expect(result.isErr, isTrue);
        expect(result.error, equals('error'));
      });

      test('toResultElse returns Ok for Some', () {
        const option = Option.some(5);
        final result = option.toResultElse(() => 'error');
        expect(result.isOk, isTrue);
        expect(result.value, equals(5));
      });

      test('toResultElse returns Err for None', () {
        const option = Option<int>.none();
        final result = option.toResultElse(() => 'error');
        expect(result.isErr, isTrue);
        expect(result.error, equals('error'));
      });
    });

    group('equality and hash', () {
      test('Some values are equal when values are equal', () {
        const option1 = Option.some(5);
        const option2 = Option.some(5);
        expect(option1, equals(option2));
        expect(option1.hashCode, equals(option2.hashCode));
      });

      test('Some values are not equal when values differ', () {
        const option1 = Option.some(5);
        const option2 = Option.some(10);
        expect(option1, isNot(equals(option2)));
      });

      test('None values are equal', () {
        const option1 = Option<int>.none();
        const option2 = Option<int>.none();
        expect(option1, equals(option2));
        expect(option1.hashCode, equals(option2.hashCode));
      });

      test('Some and None are not equal', () {
        const option1 = Option.some(5);
        const option2 = Option<int>.none();
        expect(option1, isNot(equals(option2)));
      });
    });

    group('toString', () {
      test('Some toString includes value', () {
        const option = Option.some(5);
        expect(option.toString(), equals('Some(5)'));
      });

      test('None toString', () {
        const option = Option<int>.none();
        expect(option.toString(), equals('None'));
      });
    });
  });

  group('Options utility', () {
    test('combine returns Some list when all are Some', () {
      final options = [const Option.some(1), const Option.some(2), const Option.some(3)];
      final result = Options.combine(options);
      expect(result.isSome, isTrue);
      expect(result.value, equals([1, 2, 3]));
    });

    test('combine returns None when any is None', () {
      final options = [const Option.some(1), const Option<int>.none(), const Option.some(3)];
      final result = Options.combine(options);
      expect(result.isNone, isTrue);
    });

    test('combineAll collects all Some values', () {
      final options = [const Option.some(1), const Option<int>.none(), const Option.some(3)];
      final result = Options.combineAll(options);
      expect(result, equals([1, 3]));
    });

    test('firstSome returns first Some option', () {
      final options = [const Option<int>.none(), const Option.some(2), const Option.some(3)];
      final result = Options.firstSome(options);
      expect(result.isSome, isTrue);
      expect(result.value, equals(2));
    });

    test('firstSome returns None when all are None', () {
      final options = [const Option<int>.none(), const Option<int>.none()];
      final result = Options.firstSome(options);
      expect(result.isNone, isTrue);
    });

    test('lastSome returns last Some option', () {
      final options = [const Option.some(1), const Option<int>.none(), const Option.some(3)];
      final result = Options.lastSome(options);
      expect(result.isSome, isTrue);
      expect(result.value, equals(3));
    });

    test('traverse with success', () {
      final values = [1, 2, 3];
      final result = Options.traverse(values, (x) => Option.some(x * 2));
      expect(result.isSome, isTrue);
      expect(result.value, equals([2, 4, 6]));
    });

    test('traverse with failure', () {
      final values = [1, 2, 3];
      final result = Options.traverse(
          values, (x) => x == 2 ? const Option<int>.none() : Option.some(x * 2));
      expect(result.isNone, isTrue);
    });

    test('sequence with all Some', () {
      final options = [const Option.some(1), const Option.some(2), const Option.some(3)];
      final result = Options.sequence(options);
      expect(result.isSome, isTrue);
      expect(result.value, equals([1, 2, 3]));
    });

    test('sequence with any None', () {
      final options = [const Option.some(1), const Option<int>.none(), const Option.some(3)];
      final result = Options.sequence(options);
      expect(result.isNone, isTrue);
    });

    test('lift2 combines two Some values', () {
      const a = Option.some(2);
      const b = Option.some(3);
      final result = Options.lift2(a, b, (x, y) => x + y);
      expect(result.isSome, isTrue);
      expect(result.value, equals(5));
    });

    test('lift2 returns None when any is None', () {
      const a = Option.some(2);
      const b = Option<int>.none();
      final result = Options.lift2(a, b, (x, y) => x + y);
      expect(result.isNone, isTrue);
    });

    test('lift3 combines three Some values', () {
      const a = Option.some(1);
      const b = Option.some(2);
      const c = Option.some(3);
      final result = Options.lift3(a, b, c, (x, y, z) => x + y + z);
      expect(result.isSome, isTrue);
      expect(result.value, equals(6));
    });

    test('partition separates Some and None', () {
      final options = [const Option.some(1), const Option<int>.none(), const Option.some(2)];
      final (values, noneCount) = Options.partition(options);
      expect(values, equals([1, 2]));
      expect(noneCount, equals(1));
    });

    test('collectSome extracts all Some values', () {
      final options = [const Option.some(1), const Option<int>.none(), const Option.some(2)];
      final values = Options.collectSome(options);
      expect(values, equals([1, 2]));
    });

    test('mapM same as traverse', () {
      final values = [1, 2, 3];
      final result = Options.mapM(values, (x) => Option.some(x * 2));
      expect(result.isSome, isTrue);
      expect(result.value, equals([2, 4, 6]));
    });

    test('foldM accumulates Some values', () {
      final options = [const Option.some(1), const Option.some(2), const Option.some(3)];
      final result =
          Options.foldM(options, 0, (acc, value) => Option.some(acc + value));
      expect(result.isSome, isTrue);
      expect(result.value, equals(6));
    });

    test('foldM returns None on first None', () {
      final options = [const Option.some(1), const Option<int>.none(), const Option.some(3)];
      final result =
          Options.foldM(options, 0, (acc, value) => Option.some(acc + value));
      expect(result.isNone, isTrue);
    });

    test('fromPredicate creates Some when true', () {
      final result = Options.fromPredicate(5, (x) => x > 0);
      expect(result.isSome, isTrue);
      expect(result.value, equals(5));
    });

    test('fromPredicate creates None when false', () {
      final result = Options.fromPredicate(-1, (x) => x > 0);
      expect(result.isNone, isTrue);
    });

    test('flatten unwraps nested Option', () {
      const nested = Option.some(Option.some(42));
      final result = Options.flatten(nested);
      expect(result.isSome, isTrue);
      expect(result.value, equals(42));
    });

    test('flatten returns None for nested None', () {
      const nested = Option.some(Option<int>.none());
      final result = Options.flatten(nested);
      expect(result.isNone, isTrue);
    });

    test('when creates Some when condition is true', () {
      final result = Options.when(true, () => 'value');
      expect(result.isSome, isTrue);
      expect(result.value, equals('value'));
    });

    test('when creates None when condition is false', () {
      final result = Options.when(false, () => 'value');
      expect(result.isNone, isTrue);
    });

    test('guard creates Some when condition is true', () {
      final result = Options.guard(true, 'value');
      expect(result.isSome, isTrue);
      expect(result.value, equals('value'));
    });

    test('guard creates None when condition is false', () {
      final result = Options.guard(false, 'value');
      expect(result.isNone, isTrue);
    });

    test('zip combines two Some options', () {
      const a = Option.some(1);
      const b = Option.some('hello');
      final result = Options.zip(a, b);
      expect(result.isSome, isTrue);
      expect(result.value, equals((1, 'hello')));
    });

    test('zip returns None when any is None', () {
      const a = Option<int>.none();
      const b = Option.some('hello');
      final result = Options.zip(a, b);
      expect(result.isNone, isTrue);
    });

    test('zip3 combines three Some options', () {
      const a = Option.some(1);
      const b = Option.some('hello');
      const c = Option.some(true);
      final result = Options.zip3(a, b, c);
      expect(result.isSome, isTrue);
      expect(result.value, equals((1, 'hello', true)));
    });

    test('unzip separates tuple option', () {
      const zipped = Option.some((1, 'hello'));
      final (a, b) = Options.unzip(zipped);
      expect(a.isSome, isTrue);
      expect(a.value, equals(1));
      expect(b.isSome, isTrue);
      expect(b.value, equals('hello'));
    });

    test('unzip returns None pair for None', () {
      const zipped = Option<(int, String)>.none();
      final (a, b) = Options.unzip(zipped);
      expect(a.isNone, isTrue);
      expect(b.isNone, isTrue);
    });
  });

  group('Option additional methods', () {
    test('flatten', () {
      // Test flatten with Some(Some)
      const nested = Option.some(Option.some(42));
      final flattened = nested.flatten<int>();
      expect(flattened.isSome, isTrue);
      expect(flattened.value, equals(42));

      // Test flatten with None - skip other complex cases
      const none = Option<Option<int>>.none();
      final flattenedOuter = none.flatten<int>();
      expect(flattenedOuter.isNone, isTrue);
    });

    test('zip', () {
      // Test zip with Some, Some
      const a = Option.some(1);
      const b = Option.some('hello');
      final zipped = a.zip(b);
      expect(zipped.isSome, isTrue);
      final tuple = zipped.value;
      expect(tuple.$1, equals(1));
      expect(tuple.$2, equals('hello'));

      // Test zip with Some, None
      const c = Option.none();
      final zippedNone = a.zip(c);
      expect(zippedNone.isNone, isTrue);

      // Test zip with None, Some
      const d = Option.none();
      final zippedNone2 = d.zip(b);
      expect(zippedNone2.isNone, isTrue);
    });

    test('zipWith', () {
      const a = Option.some(1);
      const b = Option.some(2);
      final combined = a.zipWith(b, (x, y) => x + y);
      expect(combined.isSome, isTrue);
      expect(combined.value, equals(3));

      // Test with None
      const d = Option.none();
      final combinedNone = d.zipWith(b, (x, y) => x + y);
      expect(combinedNone.isNone, isTrue);
    });

    test('inspect', () {
      var inspected = false;
      final result = const Option.some(42).inspect((value) {
        inspected = true;
        expect(value, equals(42));
      });
      expect(inspected, isTrue);
      expect(result.value, equals(42));

      // Test inspect with None
      var inspectedNone = false;
      final noneResult = const Option.none().inspect((value) {
        inspectedNone = true;
      });
      expect(inspectedNone, isFalse);
      expect(noneResult.isNone, isTrue);
    });

    test('transpose', () {
      // Test transpose with Some(Ok)
      const Option<Result<int, String>> someOk = Option.some(Result.ok(42));
      final transposed = someOk.transpose<int, String>();
      expect(transposed.isOk, isTrue);
      final innerOption = transposed.value;
      expect(innerOption.isSome, isTrue);
      expect(innerOption.value, equals(42));

      // Test transpose with Some(Err)
      const Option<Result<int, String>> someErr =
          Option.some(Result.err('error'));
      final transposedErr = someErr.transpose<int, String>();
      expect(transposedErr.isErr, isTrue);
      expect(transposedErr.error, equals('error'));
    });
  });
}
