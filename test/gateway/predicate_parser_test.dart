import 'package:test/test.dart';
import 'package:trestle/src/gateway/gateway.dart';

main() {
  group('invalid predicates', () {
    void invalidPredicate(Function predicate) {
      expect(
              () => PredicateParser.parse(predicate),
          throwsA(new isInstanceOf<PredicateParserException>()));
    }

    test('not lambda', () {
      invalidPredicate((x) {
        return x == 1;
      });
    });

    test('degenerate predicates', () {
      invalidPredicate(null);
      invalidPredicate(() => null);
    });
  });

  group('single argument', () {
    void assertParsesTo(Function predicate, String expression, [List variables = const []]) {
      final exp = PredicateParser.parse(predicate);
      expect(exp.expression(['x']), equals(expression));
      expect(exp.variables, equals(variables));
    }

    test('simple expression', () {
      assertParsesTo((a) => a.f == 1, 'x.f == 1');
    });

    test('with variables', () {
      final i = 1;
      final s = "string";
      assertParsesTo((a) => a.f == s, 'x.f == ?', ['string']);
      assertParsesTo((a) => a.f == i && a.f2 == s, 'x.f == 1 && x.f2 == ?', ['string']);
      assertParsesTo((a) => a.f == 1 && a.f2 == s, 'x.f == 1 && x.f2 == ?', ['string']);
      assertParsesTo((a) => a.f == i + 3 && a.f2 == s, 'x.f == 4 && x.f2 == ?', ['string']);
      assertParsesTo((a) => a['f'] == i + 3 || (a.f == i && a.f2 == s), 'x.f == 4 || (x.f == 1 && x.f2 == ?)', ['string']);
      assertParsesTo((a) => a['f'] == i + 3 && a[s] == i, 'x.f == 4 && x.string == 1');
    });

    test('with expressions', () {
      assertParsesTo(
              (a) => a.f == new DateTime.utc(2015, 01, 01),
          'x.f == date(2015-01-01T00:00:00.000Z)');
    });
  });

  group('multiple arguments', () {
    void assertParsesTo(Function predicate, String expression) {
      expect(PredicateParser.parse(predicate).expression(['x', 'y']), equals(expression));
    }

    test('integration', () {
      final age = 20;
      assertParsesTo((user, address) => user.age > age && user.addressId == address.id,
      'x.age > 20 && x.addressId == y.id');
    });
  });
}