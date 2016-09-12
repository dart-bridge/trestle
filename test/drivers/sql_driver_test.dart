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
      expect(driver.variableSets.any((e) => equals(variables).matches(e, {})),
          isTrue, reason: '$variables was not passed');
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
      await query((q) => q.join('other', (a, b) => a.x == b.y).get());
      expectQuery('SELECT * FROM "test" JOIN "other" ON test.x = other.y;');
    });

    test('sort by', () async {
      await query((q) => q.sortBy('x', 'desc').get());
      expectQuery('SELECT * FROM "test" ORDER BY "x" DESC;');
    });

    test('group by', () async {
      await query((q) => q.groupBy('x').get());
      expectQuery('SELECT * FROM "test" GROUP BY "x";');
    });

    test('integration', () async {
      const foreign = 'address_id';
      const id = 'id';
      await gateway.table('users')
          .where((user) => user.age > 20 && user.first_name == 'John')
          .sortBy('first_name')
          .limit(1)
          .join('addresses', (user, address) => user[foreign] == address[id])
          .get(['address', 'first_name', 'last_name']).toList();

      expectQuery(
          'SELECT "address", "first_name", "last_name" FROM "users" '
              'WHERE "age" > 20 AND "first_name" = ? '
              'ORDER BY "first_name" ASC '
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

    test('average', () async {
      driver.willReturn = [{'average': 123.123}];
      double average = await query((q) => q.average('field'));

      expect(average, equals(123.123));
      expectQuery('SELECT AVG("field") AS average FROM "test";');
    });

    test('max', () async {
      driver.willReturn = [{'max': 123}];
      int max = await query((q) => q.max('field'));

      expect(max, equals(123));
      expectQuery('SELECT MAX("field") AS max FROM "test";');
    });

    test('min', () async {
      driver.willReturn = [{'min': 123}];
      int min = await query((q) => q.min('field'));

      expect(min, equals(123));
      expectQuery('SELECT MIN("field") AS min FROM "test";');
    });

    test('sum', () async {
      driver.willReturn = [{'sum': 123}];
      int sum = await query((q) => q.sum('field'));

      expect(sum, equals(123));
      expectQuery('SELECT SUM("field") AS sum FROM "test";');
    });
  });

  group('insert statements', () {
    test('simple insert', () async {
      await query((q) => q.add({'x': 'y'}));
      expectQuery('INSERT INTO "test" ("x") VALUES (?);', ['y']);
    });

    test('add all', () async {
      await query((q) => q.addAll([{'x': 'y'}, {'x': 'z'}]));
      expectQuery('INSERT INTO "test" ("x") VALUES (?);', ['y']);
      expectQuery('INSERT INTO "test" ("x") VALUES (?);', ['z']);
    });
  });

  group('delete statments', () {
    test('truncate', () async {
      await query((q) => q.delete());
      expectQuery('DELETE FROM "test";');
    });

    test('with constraints', () async {
      await query((q) => q.where((f) => f.x == f.y).limit(10).delete());
      expectQuery('DELETE FROM "test" '
          'WHERE "x" = "y" '
          'LIMIT 10;');
    });
  });

  test('update statements', () async {
    await query((q) =>
        q.where((f) => f.x == '1').update({'f': '2', 'f2': '3'}));
    expectQuery('UPDATE "test" '
        'SET "f" = ?, "f2" = ? '
        'WHERE "x" = ?;', ['2', '3', '1']);
  });

  test('increments', () async {
    await query((q) => q.limit(3).increment('f', 7));
    expectQuery('UPDATE "test" SET "f" = "f" + 7 LIMIT 3;');
  });

  test('decrements', () async {
    await query((q) => q.limit(3).decrement('f', 7));
    expectQuery('UPDATE "test" SET "f" = "f" - 7 LIMIT 3;');
  });

  group('schema', () {
    test('dropping a table', () async {
      await gateway.drop('t');
      expectQuery('DROP TABLE "t";');
    });

    group('creating a table', () {
      test('with no fields', () async {
        await gateway.create('t', (Schema schema) {});
        expectQuery('CREATE TABLE "t" ();');
      });

      test('with a single field', () async {
        await gateway.create('t', (Schema schema) {
          schema.string('f');
        });
        expectQuery('CREATE TABLE "t" ("f" VARCHAR(255));');
      });

      test('with multiple fields and field properties', () async {
        await gateway.create('t', (Schema schema) {
          schema.id();
          schema.integer('i').nullable(false);
          schema.string('f').unique();
        });
        expectQuery('CREATE TABLE "t" ('
            '"id" INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, '
            '"i" INTEGER NOT NULL, '
            '"f" VARCHAR(255) UNIQUE'
            ');');
      });
    });

    group('altering a table', () {
      test('dropping columns', () async {
        await gateway.alter('t', (Schema schema) {
          schema.drop('f');
          schema.drop('f2');
        });
        expectQuery('ALTER TABLE "t" DROP COLUMN "f", "f2";');
      });

      test('modifying', () async {
        await gateway.alter('t', (Schema schema) {
          schema.int('i');
        });
        expectQuery('ALTER TABLE "t" ADD COLUMN "i" INTEGER;');
      });
    });
  });
}

class MockSqlDriver extends SqlDriver with SqlStandards {
  final List<String> queries = [];
  final List<List> variableSets = [];
  var willReturn = [];

  String get autoIncrementKeyword => 'AUTOINCREMENT';

  Future connect() async {}

  Future disconnect() async {}

  Stream<Map<String, dynamic>> execute(String query, List variables) {
    queries.add(query);
    variableSets.add(variables);
    return new Stream.fromIterable(willReturn);
  }

  String insertedIdQuery(String table) => '';
}
