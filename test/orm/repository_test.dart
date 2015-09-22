import 'package:test/test.dart';
import 'package:trestle/trestle.dart';
import 'package:trestle/gateway.dart';
import 'dart:async';

main() {
  Repository repo;
  MockInMemoryDriver driver;

  Future table(String table, List<Map<String, dynamic>> fields) {
    return driver.addAll(new Query(driver, table), fields);
  }

  expectThing(dynamic model, {int a, int b, int c}) {
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

      expectThing(res[0], a: 1, b: 2, c: 3);
      expectThing(res[1], a: 4, b: 5, c: 6);
      expectThing(res[2], a: 7, b: 8, c: 9);
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

      expectThing(res[0], a: 4, b: 5, c: 6);
    });

    test('can insert new models', () async {
      await repo.add(new Thing()
        ..a = 1
        ..b = 2
        ..c = 3);

      expectThing(await repo.first(), a: 1, b: 2, c: 3);
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

      expectThing(persistedThing, a: 7, b: 5, c: 6);
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

  group('extending Model', () {
    Gateway gateway;

    setUp(() {
      repo = new Repository<ThingModel>();
      repo.connect(gateway = new Gateway(driver = new MockInMemoryDriver()));
    });

    test('persists as usual', () async {
      await table('thing_models', [
        {'id': 1, 'a': 1, 'b': 2, 'c': 3},
        {'id': 2, 'a': 4, 'b': 5, 'c': 6},
        {'id': 3, 'a': 7, 'b': 8, 'c': 9},
      ]);

      ThingModel model1 = await repo.find(1);
      ThingModel model2 = await repo.find(2);
      ThingModel model3 = await repo.find(3);

      expectThing(model1, a: 1, b: 2, c: 3);
      expectThing(model2, a: 4, b: 5, c: 6);
      expectThing(model3, a: 7, b: 8, c: 9);
    });

    test('only persists annotated fields', () async {
      final model = new ThingModel()
          ..id = 1
          ..a = 1
          ..b = 2
          ..c = 3
          ..willNotBePersisted = 'x';

      await repo.add(model);

      final ThingModel retrieved = await repo.find(1);

      expect(retrieved.willNotBePersisted, isNot(equals('x')));
    });

    test('annotations override column name', () async {
      await table('thing_models', [
        {'id': 1, 'created_at': new DateTime(2015)}
      ]);

      final ThingModel retrieved = await repo.find(1);

      expect(retrieved.createdAt, equals(new DateTime(2015)));

      retrieved.createdAt = new DateTime(2016);

      await repo.update(retrieved);

      expect(await gateway.table('thing_models').get(['created_at']).toList(), equals([
        {'created_at': new DateTime(2016)}
      ]));
    });
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

class ThingModel extends Model {
  @field int a;
  @field int b;
  @field int c;
  String willNotBePersisted;
}

class BelongingModel extends Model {
  @Field('overriden_id') int overridenId;
  @field int d;
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