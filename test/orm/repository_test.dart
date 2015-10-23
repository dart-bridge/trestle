import 'package:test/test.dart';
import 'package:trestle/trestle.dart';
import 'package:trestle/gateway.dart';
import 'models.dart';
import 'dart:mirrors';
import 'dart:async';

main() {
  Gateway gateway;
  Repository repo;

  setUp(() {
    gateway = new Gateway(new InMemoryDriver());
  });

  Repository modelRepo(Type model) {
    return new Repository.of(
        new ModelEntity(gateway, reflectType(model)),
        gateway);
  }

  Repository dataRepo(Type model) {
    return new Repository.of(
        new DataStructureEntity(reflectType(model)), gateway);
  }

  Future seed(String table, List<Map<String, dynamic>> rows) {
    return gateway.table(table).addAll(rows);
  }

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

  group('relationships', () {
    Repository childRepo;

    group('one to one', () {
      setUp(() {
        repo = modelRepo(ConventionalOneToOneParent);
        childRepo = modelRepo(ConventionalOneToOneChild);
      });

      test('read', () async {
        // Seed
        await seed('parents', [
          {'id': 11, 'conventional_one_to_one_child_id': 22},
        ]);
        await seed('children', [
          {'id': 22},
        ]);

        // Read
        final ConventionalOneToOneParent parent = await repo.find(11);
        final ConventionalOneToOneChild child = await childRepo.find(22);

        // Assert
        await parent.expectChild(child);
        await child.expectParent(parent);
      });
    });

    group('one to many', () {
      setUp(() {
        repo = modelRepo(ConventionalOneToManyParent);
        childRepo = modelRepo(ConventionalOneToManyChild);
      });

      test('read', () async {
        // Seed
        await seed('parents', [
          {'id': 33}
        ]);
        await seed('children', [
          {'id': 44, 'parent_id': 33},
          {'id': 55, 'parent_id': 33},
        ]);

        // Read
        final ConventionalOneToManyParent parent = await repo.find(33);
        final List<ConventionalOneToManyChild> children =
        await childRepo.all().toList();

        // Assert
        await parent.expectChildren(children);
        await Future.wait(children.map((c) => c.expectParent(parent)));
      });
    }, skip: 'not yet implemeted');

    group('many to one', () {
      setUp(() {
        repo = modelRepo(ConventionalManyToOneParent);
        childRepo = modelRepo(ConventionalManyToOneChild);
      });

      test('read', () async {
        // Seed
        await seed('parents', [
          {'id': 66, 'child_id': 88},
          {'id': 77, 'child_id': 88},
        ]);
        await seed('children', [
          {'id': 88}
        ]);

        // Read
        final List<ConventionalManyToOneParent> parents =
        await repo.all().toList();
        final ConventionalManyToOneChild child = await childRepo.find(88);

        // Assert
        await Future.wait(parents.map((c) => c.expectChild(child)));
        await child.expectParents(parents);
      });
    }, skip: 'not yet implemeted');

    group('one to many', () {
      setUp(() {
        repo = modelRepo(ConventionalManyToManyParent);
        childRepo = modelRepo(ConventionalManyToManyChild);
      });

      test('read', () async {
        // Seed
        await seed('parents', [
          {'id': 99},
          {'id': 1010},
        ]);
        await seed('children', [
          {'id': 1111},
          {'id': 1212},
        ]);
        await seed('parents_children', [
          {'parent_id': 99, 'child_id': 1111},
          {'parent_id': 99, 'child_id': 1212},
          {'parent_id': 1010, 'child_id': 1111},
          {'parent_id': 1010, 'child_id': 1212},
        ]);

        // Read
        final List<ConventionalManyToManyParent> parents =
        await repo.all().toList();
        final List<ConventionalManyToManyChild> children =
        await childRepo.all().toList();

        // Assert
        await Future.wait(parents.map((c) => c.expectChildren(children)));
        await Future.wait(children.map((c) => c.expectParents(parents)));
      });
    }, skip: 'not yet implemeted');
  });
}
