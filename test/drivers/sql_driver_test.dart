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
    return returnValue;
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
      '"x" > 20 AND ("y" >= 10 OR "z" <= ?)'
      ';', ['string value']);
    });

    test('limit', () async {
      await query((q) => q.limit(10).get());
      expectQuery('SELECT * FROM "test" LIMIT 10;');
    });

    test('distinct', () async {
      await query((q) => q.distinct().get());
      expectQuery('SELECT * FROM "test" DISTINCT;');
    });

    test('offset', () async {
      await query((q) => q.offset(10).get());
      expectQuery('SELECT * FROM "test" OFFSET 10;');
    });

    test('join', () async {
      await query((q) => q.join('other', (a,b) => a.x == b.y).get());
      expectQuery('SELECT * FROM "test" JOIN "other" ON test.x = other.y;');
    });

    test('sort by', () async {
      await query((q) => q.sortBy('x', 'desc').get());
      expectQuery('SELECT * FROM "test" SORT BY "x" DESC;');
    });

    test('group by', () async {
      await query((q) => q.groupBy('x').get());
      expectQuery('SELECT * FROM "test" GROUP BY "x";');
    });

    test('integration', () async {
      await gateway.table('users')
      .where((user) => user.age > 20 && user.first_name == 'John')
      .sortBy('first_name')
      .limit(1)
      .join('addresses', (user, address) => user.address_id == address.id)
      .get(['address','first_name','last_name']).toList();

      expectQuery(
          'SELECT "address", "first_name", "last_name" FROM "users" '
          'WHERE "age" > 20 AND "first_name" = ? '
          'SORT BY "first_name" ASC '
          'LIMIT 1 '
          'JOIN "addresses" ON users.address_id = addresses.id;',
          ['John']
      );
    });
  });

  group('aggregates', () {
    test('count', () async {
      driver.willReturn = [{'count': 123}];
      int length = await query((q) => q.count());

      expect(length, equals(123));
      expectQuery('SELECT COUNT(*) AS count FROM "test";');
    });
  });
}

class MockSqlDriver extends SqlDriver with SqlStandards {
  final List<String> queries = [];
  final List<List> variableSets = [];
  var willReturn = [];

  Future connect() async {}

  Future disconnect() async {}

  Stream<Map<String, dynamic>> execute(String query, List variables) {
    queries.add(query);
    variableSets.add(variables);
    return new Stream.fromIterable(willReturn);
  }
}