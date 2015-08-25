import 'package:test/test.dart';
import 'package:trestle/src/gateway/gateway.dart';
import 'package:trestle/src/drivers/drivers.dart';
import 'dart:async';

main() {
  Gateway gateway;
  MockSqlDriver driver;
  setUp(() {
    driver = new MockSqlDriver();
    gateway = new Gateway(driver);
  });

  Future query(predicate(Query query)) async {
    var returnValue = predicate(gateway.table('test'));
    if (returnValue is Stream)
      return returnValue.toList();
    await returnValue;
  }

  expectQuery(String query, [List variables = const []]) {
    expect(driver.queries, contains(query));
    if (variables.isNotEmpty)
      expect(driver.variableSets.any((e) => equals(variables).matches(e, {})), isTrue, reason: '$variables was not passed');
  }

  group('select statements', () {
    test('without constraints', () async {
      await query((q) => q.get());
      expectQuery('SELECT * FROM "test";');
    });

    test('only some fields', () async {
      await query((q) => q.get(['field']));
      expectQuery('SELECT "field" FROM "test";');

      await query((q) => q.get(['field', 'other_fields']));
      expectQuery('SELECT "field", "other_fields" FROM "test";');
    });
  });

  group('constraints', () {
    test('where', () async {
      await query((q) => q.where((r) => r.f == 1).get());
      expectQuery('SELECT * FROM "test" WHERE "f" = 1;');

      await query((q) => q.where((r) => r.f == 2).get());
      expectQuery('SELECT * FROM "test" WHERE "f" = 2;');

      final string = 'value';
      await query((q) => q.where((r) => r.f == string).get());
      expectQuery('SELECT * FROM "test" WHERE "f" = ?;', ['value']);

      await query((q) => q.where(
              (r) => r.x > 20 && (r.y >= 10 || r.z <= "string value")
      ).get());
      expectQuery('SELECT * FROM "test" WHERE '
      '"x" > 20 AND ("10" >= ? OR "z" <= ?)'
      ';', ['string value']);
    });
  });
}

class MockSqlDriver extends SqlDriver with SqlStandards {
  final List<String> queries = [];
  final List<List> variableSets = [];

  Future connect() async {}

  Future disconnect() async {}

  Stream<Map<String, dynamic>> execute(String query, List variables) {
    queries.add(query);
    variableSets.add(variables);
    return new Stream.empty();
  }
}