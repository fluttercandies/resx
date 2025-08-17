import 'package:test/test.dart';
import 'package:resx/resx.dart';

void main() {
  group('Universal conversions', () {
    test('value.ok and value.some', () {
      final r = 42.ok<String>();
      expect(r.isOk, isTrue);
      expect(r.value, 42);

      final o = 'hi'.some();
      expect(o.isSome, isTrue);
      expect(o.value, 'hi');
    });

    test('error.err', () {
      final r = 'boom'.err<int>();
      expect(r.isErr, isTrue);
      expect(r.error, 'boom');
    });

    test('nullable.toOption and toResult', () async {
      String? s = 'x';
      expect(s.toOption().isSome, isTrue);
      expect(s.toResult('null').isOk, isTrue);
      s = null;
      expect(s.toOption().isNone, isTrue);
      final rr = s.toResult('null');
      expect(rr.isErr, isTrue);
      expect(rr.error, 'null');
    });
  });

  group('Aliases', () {
    test('Result getOrNull/getOrDefault/getOrElse', () {
      const ok = Result.ok(1);
      const er = Result<int, String>.err('e');
      expect(ok.getOrNull(), 1);
      expect(er.getOrNull(), isNull);
      expect(ok.getOrDefault(9), 1);
      expect(er.getOrDefault(9), 9);
      expect(ok.getOrElse((_) => 7), 1);
      expect(er.getOrElse((e) => e.length), 1);
    });

    test('Option okOr/okOrElse/orNull/unwrapOr/unwrapOrElse', () {
      const some = Option.some(2);
      const none = Option<int>.none();
      expect(some.okOr('e').isOk, isTrue);
      expect(none.okOr('e').isErr, isTrue);
      expect(none.okOr('e').error, 'e');
      expect(some.okOrElse(() => 'e').isOk, isTrue);
      expect(none.okOrElse(() => 'e').isErr, isTrue);
      expect(some.orNull(), 2);
      expect(none.orNull(), isNull);
      expect(some.unwrapOr(9), 2);
      expect(none.unwrapOr(9), 9);
      expect(some.unwrapOrElse(() => 7), 2);
      expect(none.unwrapOrElse(() => 7), 7);
    });
  });
}
