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
    void assertParsesTo(Function predicate, String expression) {
      expect(PredicateParser.parse(predicate).expression(['x']), equals(expression));
    }

    test('simple expression', () {
      assertParsesTo((a) => a.f == 1, 'x.f == 1');
    });

    test('with variables', () {
      final i = 1;
      final s = "string";
      assertParsesTo((a) => a.f == i && a.f2 == s, 'x.f == 1 && x.fs == "string"');
    });
  });
}