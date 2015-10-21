import 'package:test/test.dart';
import 'package:trestle/trestle.dart';
import 'package:trestle/gateway.dart';
import 'dart:mirrors';
import 'dart:async';

main() {
  Gateway gateway;

  setUp(() {
    gateway = new Gateway(new InMemoryDriver());
  });

  Repository modelRepo(Type model) {
    return new Repository.of(new ModelEntity(reflectType(model)))
      ..connect(gateway);
  }

  Repository dataRepo(Type model) {
    return new Repository.of(new DataStructureEntity(reflectType(model)))
      ..connect(gateway);
  }

  Future seed(String table, List<Map<String, dynamic>> rows) {
    return gateway.table(table).addAll(rows);
  }

  Future expectTable(String table, List<Map<String, dynamic>> rows) async {
    expect(await gateway.table(table).get().toList(), equals(rows));
  }

  Future expectModelTable(String table, List<Map<String, dynamic>> rows) async {
    expect(await gateway.table(table)
        .get().map((m) {
      m.remove('created_at');
      m.remove('updated_at');
      return m;
    }).toList(), equals(rows));
  }

  group('inserts', () {
    test('it has a collection of items', () async {
      await seed('empties', [
        {},
      ]);

      await dataRepo(Empty).save(new Empty());

      await expectTable('empties', [
        {}, {}
      ]);
    });

    test('is supports data structures with fields', () async {
      await seed('single_properties', [
        {'property': 'a'},
      ]);

      await dataRepo(SingleProperty).save(
          new SingleProperty()
            ..property = 'b');

      await expectTable('single_properties', [
        {'property': 'a'},
        {'property': 'b'},
      ]);
    });

    test('is supports models with fields', () async {
      await dataRepo(SimpleModel).save(new SimpleModel());

      await expectModelTable('simple_models', [
        {'id': 1},
      ]);
    });
  });
}

class Empty {}

class SingleProperty {
  String property;
}

class SimpleModel extends Model {}
