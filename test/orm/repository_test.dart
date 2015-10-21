import 'package:test/test.dart';
import 'package:trestle/trestle.dart';
import 'package:trestle/gateway.dart';
import 'models.dart';
import 'dart:mirrors';

main() {
  Gateway gateway;
  Repository repo;

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

//  Future seed(String table, List<Map<String, dynamic>> rows) {
//    return gateway.table(table).addAll(rows);
//  }

//  Future expectTable(String table, List<Map<String, dynamic>> rows) async {
//    expect(await gateway.table(table).get().toList(), equals(rows));
//  }
//
//  Future expectModelTable(String table, List<Map<String, dynamic>> rows) async {
//    expect(await gateway.table(table)
//        .get().map((m) {
//      m.remove('created_at');
//      m.remove('updated_at');
//      return m;
//    }).toList(), equals(rows));
//  }

  group('with a data structure', () {
    setUp(() {
      repo = dataRepo(DataStructure);
    });

    test('properties are mapped correctly', () async {
      final model = new DataStructure()
        ..property = 'a'
        ..camelCase = 'b';
      await repo.save(model);
      model.expectTable(repo.table);
      model.expectContent(await gateway.table('data_structures').first());
    });
  });

  group('with a simple model', () {
    setUp(() {
      repo = modelRepo(SimpleModel);
    });

    test('properties are mapped correctly', () async {
      final model = new SimpleModel()
        ..property = 'a'
        ..camelCase = 'b';
      await repo.save(model);
      model.expectTable(repo.table);
      model.id = 1;
      model.expectContent(await gateway.table('simple_models').first());
    });
  });

  group('with a model with overridden table name', () {
    setUp(() {
      repo = modelRepo(ModelWithOverriddenTableName);
    });

    test('table name is overriden', () async {
      final model = new ModelWithOverriddenTableName();
      model.expectTable(repo.table);
    });
  });

  group('with a simple model', () {
    setUp(() {
      repo = modelRepo(ConventionalOneToOneParent);
    });
  });

  group('with a simple model', () {
    setUp(() {
      repo = modelRepo(ConventionalOneToOneChild);
    });
  });

  group('with a simple model', () {
    setUp(() {
      repo = modelRepo(ConventionalOneToManyParent);
    });
  });

  group('with a simple model', () {
    setUp(() {
      repo = modelRepo(ConventionalOneToManyChild);
    });
  });

  group('with a simple model', () {
    setUp(() {
      repo = modelRepo(ConventionalManyToOneParent);
    });
  });

  group('with a simple model', () {
    setUp(() {
      repo = modelRepo(ConventionalManyToOneChild);
    });
  });

  group('with a simple model', () {
    setUp(() {
      repo = modelRepo(ConventionalManyToManyParent);
    });
  });

  group('with a simple model', () {
    setUp(() {
      repo = modelRepo(ConventionalManyToManyChild);
    });
  });
}
