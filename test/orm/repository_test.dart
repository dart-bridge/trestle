import 'package:test/test.dart';
import 'package:trestle/trestle.dart';
import 'package:trestle/gateway.dart';
import 'dart:async';

main() {
  Repository<Thing> repo;
  MockInMemoryDriver driver;

  Future table(String table, List<Map<String, dynamic>> fields) {
    return driver.addAll(new Query(driver, table), fields);
  }

  expectModel(Thing model, {int a, int b, int c}) {
    expect(model.a, equals(a));
    expect(model.b, equals(b));
    expect(model.c, equals(c));
  }

  void testsForBothRepoStyles() {
    test('contains models', () async {
      await table(repo.table, [
        {'a': 1, 'b': 2, 'c': 3},
        {'a': 4, 'b': 5, 'c': 6},
        {'a': 7, 'b': 8, 'c': 9},
      ]);

      final res = await repo.all().toList();

      expectModel(res[0], a: 1, b: 2, c: 3);
      expectModel(res[1], a: 4, b: 5, c: 6);
      expectModel(res[2], a: 7, b: 8, c: 9);
    });

    test('extends the gateway query', () async {
      await table(repo.table, [
        {'a': 1, 'b': 2, 'c': 3},
        {'a': 4, 'b': 5, 'c': 6},
        {'a': 7, 'b': 8, 'c': 9},
      ]);

      final res = await repo
          .where((m) => m.a == 4).get()
          .toList();

      expect(res.length, equals(1));

      expectModel(res[0], a: 4, b: 5, c: 6);
    });

    test('can insert new models', () async {
      await repo.add(new Thing()
        ..a = 1
        ..b = 2
        ..c = 3);

      expectModel(await repo.first(), a: 1, b: 2, c: 3);
    });

    test('models can have ids', () async {
      final thing = new Thing()
        ..id = 1
        ..a = 4
        ..b = 5
        ..c = 6;
      await repo.add(thing);

      thing.a = 7;

      await repo.update(thing);

      final persistedThing = await repo.find(1);

      expectModel(persistedThing, a: 7, b: 5, c: 6);
      expect(await repo.count(), equals(1));
      expect(persistedThing.id, equals(1));
    });
  }

  group('not extended repo', () {
    setUp(() {
      repo = new Repository<Thing>();
      repo.connect(new Gateway(driver = new MockInMemoryDriver()));
    });

    test('infers table name', () {
      expect(repo.table, equals('things'));
    });

    testsForBothRepoStyles();
  });

  group('extended repo', () {
    ThingRepository things;
    BelongingRepository belongings;

    expectBelonging(Belonging model, {int d}) {
      expect(model.d, equals(d));
    }

    setUp(() {
      final gateway = new Gateway(driver = new MockInMemoryDriver());
      repo = things = new ThingRepository();
      repo.connect(gateway);
      belongings = new BelongingRepository();
      belongings.connect(gateway);
    });

    test('overrides table name', () {
      expect(repo.table, equals('overriden'));
    });

    group('relationships', () {
      test('one to many', () async {
        await table(repo.table, [
          {'id': 1,'a': 1, 'b': 2, 'c': 3},
        ]);
        await table('belongings', [
          {'id': 1,'d': 1, 'overriden_id': 1},
          {'id': 2,'d': 2, 'overriden_id': 1},
          {'id': 3,'d': 3, 'overriden_id': 2},
        ]);

        final thing = await repo.find(1);
        final belongingsOfThing = await things.belongingsOf(thing).get().toList();
        final belonging = belongingsOfThing[0];
        final thingCopy = await belongings.thingOf(belonging);

        expect([
          thingCopy.id,
          thingCopy.a,
          thingCopy.b,
          thingCopy.c,
        ], equals([
          thing.id,
          thing.a,
          thing.b,
          thing.c,
        ]));

        expect(belongingsOfThing.length, equals(2));
        expectBelonging(belonging, d: 1);
      });
    });

    testsForBothRepoStyles();
  });
}

class Thing {
  int id;
  int a;
  int b;
  int c;
}

class Belonging {
  int id;
  int overriden_id;
  int d;
}

class ThingRepository extends Repository<Thing> {
  String get table => 'overriden';

  RepositoryQuery<Belonging> belongingsOf(Thing thing) {
    return relationship(thing).hasMany(Belonging);
  }
}

class BelongingRepository extends Repository<Belonging> {
  Future<Thing> thingOf(Belonging belonging) {
    return relationship(belonging).belongsTo(Thing, field: 'overriden_id', table: 'overriden');
  }
}

class MockInMemoryDriver extends InMemoryDriver {
  final List<Query> queries = [];

  @override
  Stream<Map<String, dynamic>> get(Query query, Iterable<String> fields) {
    queries.add(query);
    return super.get(query, fields);
  }
}