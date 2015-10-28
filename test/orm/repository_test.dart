import 'package:test/test.dart';
import 'package:trestle/trestle.dart';
import 'package:trestle/gateway.dart';
import 'models.dart';
import 'dart:mirrors';
import 'dart:async';

main() {
  Gateway gateway;
  Repository repo;

  setUp(() async {
//    gateway = new Gateway(new SqliteDriver(':memory:'));
    gateway = new Gateway(new InMemoryDriver());
    await gateway.connect();
    final modelSchema = (Schema schema) {
      schema.id();
      schema.timestamp('created_at').nullable(true);
      schema.timestamp('updated_at').nullable(true);
      schema.string('property').nullable(true);
      schema.string('camel_case').nullable(true);
    };
    await gateway.create('data_structures', modelSchema);
    await gateway.create('value_objects', modelSchema);
    await gateway.create('simple_models', modelSchema);
    await gateway.create('parents', (schema) {
      schema.id();
      schema.timestamp('created_at').nullable(true);
      schema.timestamp('updated_at').nullable(true);
      schema.int('conventional_one_to_one_child_id').nullable(true);
      schema.int('conventional_many_to_one_child_id').nullable(true);
    });
    await gateway.create('children', (schema) {
      schema.id();
      schema.timestamp('created_at').nullable(true);
      schema.timestamp('updated_at').nullable(true);
      schema.int('conventional_one_to_many_parent_id').nullable(true);
    });
    await gateway.create('parents_x', (schema) {
      schema.int('id_x').incrementingPrimaryKey();
      schema.timestamp('created_at').nullable(true);
      schema.timestamp('updated_at').nullable(true);
      schema.int('child_id_x').nullable(true);
    });
    await gateway.create('children_x', (schema) {
      schema.int('id_x').incrementingPrimaryKey();
      schema.timestamp('created_at').nullable(true);
      schema.timestamp('updated_at').nullable(true);
      schema.int('parent_id_x').nullable(true);
    });
    await gateway.create('parents_x_mtm', (schema) {
      schema.int('id_x').incrementingPrimaryKey();
      schema.timestamp('created_at').nullable(true);
      schema.timestamp('updated_at').nullable(true);
    });
    await gateway.create('children_x_mtm', (schema) {
      schema.int('id_x').incrementingPrimaryKey();
      schema.timestamp('created_at').nullable(true);
      schema.timestamp('updated_at').nullable(true);
    });
    await gateway.create('parents_children', (schema) {
      schema.int('conventional_many_to_many_parent_id').nullable(true);
      schema.int('conventional_many_to_many_child_id').nullable(true);
    });
    await gateway.create('parents_children_x', (schema) {
      schema.int('parent_id_x').nullable(true);
      schema.int('child_id_x').nullable(true);
    });
  });

  tearDown(() async {
    await gateway.drop('data_structures');
    await gateway.drop('value_objects');
    await gateway.drop('simple_models');
    await gateway.drop('parents');
    await gateway.drop('children');
    await gateway.drop('parents_x');
    await gateway.drop('children_x');
    await gateway.drop('parents_x_mtm');
    await gateway.drop('children_x_mtm');
    await gateway.drop('parents_children');
    await gateway.drop('parents_children_x');
    await gateway.disconnect();
  });

  Repository modelRepo(Type model) {
    return new Repository.of(
        new MapsFieldsToModel(gateway, reflectType(model)),
        gateway);
  }

  Repository dataRepo(Type model) {
    return new Repository.of(
        new MapsFieldsToDataStructure(reflectType(model)), gateway);
  }

  Repository valueRepo(Type model) {
    return new Repository.of(
        new MapsFieldsToValueObject(reflectType(model)), gateway);
  }

  Repository unconventionalModelRepo(Type model) {
    return new UnconventionalRepository.of(
        new MapsFieldsToModel(gateway, reflectType(model)),
        gateway);
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
      model.expectContent(await gateway.table(repo.table).first());
    });
  });

  group('with a value object', () {
    setUp(() {
      repo = valueRepo(ValueObject);
    });

    test('properties are mapped correctly', () async {
      final model = new ValueObject('a', 'b');
      await repo.save(model);
      model.expectTable(repo.table);
      model.expectContent(await gateway.table(repo.table).first());
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

  group('conventional relationships', () {
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
          {'id': 44, 'conventional_one_to_many_parent_id': 33},
          {'id': 55, 'conventional_one_to_many_parent_id': 33},
        ]);

        // Read
        final ConventionalOneToManyParent parent = await repo.find(33);
        final List<ConventionalOneToManyChild> children =
        await childRepo.all().toList();

        // Assert
        await parent.expectChildren(children);
        await Future.wait(children.map((c) => c.expectParent(parent)));
      });
    });

    group('many to one', () {
      setUp(() {
        repo = modelRepo(ConventionalManyToOneParent);
        childRepo = modelRepo(ConventionalManyToOneChild);
      });

      test('read', () async {
        // Seed
        await seed('parents', [
          {'id': 66, 'conventional_many_to_one_child_id': 88},
          {'id': 77, 'conventional_many_to_one_child_id': 88},
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
    });

    group('many to many', () {
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
        const parentId = 'conventional_many_to_many_parent_id';
        const childId = 'conventional_many_to_many_child_id';
        await seed('parents_children', [
          {parentId: 99, childId: 1111},
          {parentId: 99, childId: 1212},
          {parentId: 1010, childId: 1111},
          {parentId: 1010, childId: 1212},
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
    });
  });

  group('unconventional relationships', () {
    Repository childRepo;

    group('one to one', () {
      setUp(() {
        repo = unconventionalModelRepo(UnconventionalOneToOneParent);
        childRepo = unconventionalModelRepo(UnconventionalOneToOneChild);
      });

      test('read', () async {
        // Seed
        await seed('parents_x', [
          {'id_x': 11, 'child_id_x': 22},
        ]);
        await seed('children_x', [
          {'id_x': 22},
        ]);

        // Read
        final UnconventionalOneToOneParent parent = await repo.find(11);
        final UnconventionalOneToOneChild child = await childRepo.find(22);

        // Assert
        await parent.expectChild(child);
        await child.expectParent(parent);
      });
    });

    group('one to many', () {
      setUp(() {
        repo = unconventionalModelRepo(UnconventionalOneToManyParent);
        childRepo = unconventionalModelRepo(UnconventionalOneToManyChild);
      });

      test('read', () async {
        // Seed
        await seed('parents_x', [
          {'id_x': 33}
        ]);
        await seed('children_x', [
          {'id_x': 44, 'parent_id_x': 33},
          {'id_x': 55, 'parent_id_x': 33},
        ]);

        // Read
        final UnconventionalOneToManyParent parent = await repo.find(33);
        final List<UnconventionalOneToManyChild> children =
        await childRepo.all().toList();

        // Assert
        await parent.expectChildren(children);
        await Future.wait(children.map((c) => c.expectParent(parent)));
      });
    });

    group('many to one', () {
      setUp(() {
        repo = unconventionalModelRepo(UnconventionalManyToOneParent);
        childRepo = unconventionalModelRepo(UnconventionalManyToOneChild);
      });

      test('read', () async {
        // Seed
        await seed('parents_x', [
          {'id_x': 66, 'child_id_x': 88},
          {'id_x': 77, 'child_id_x': 88},
        ]);
        await seed('children_x', [
          {'id_x': 88}
        ]);

        // Read
        final List<UnconventionalManyToOneParent> parents =
        await repo.all().toList();
        final UnconventionalManyToOneChild child = await childRepo.find(88);

//        print(parents[0].child);
//        print(child.parents[0]);

        // Assert
        await Future.wait(parents.map((c) => c.expectChild(child)));
        await child.expectParents(parents);
      });
    });

    group('many to many', () {
      setUp(() {
        repo = unconventionalModelRepo(UnconventionalManyToManyParent);
        childRepo = unconventionalModelRepo(UnconventionalManyToManyChild);
      });

      test('read', () async {
        // Seed
        await seed('parents_x_mtm', [
          {'id_x': 99},
          {'id_x': 1010},
        ]);
        await seed('children_x_mtm', [
          {'id_x': 1111},
          {'id_x': 1212},
        ]);
        await seed('parents_children_x', [
          {'parent_id_x': 99, 'child_id_x': 1111},
          {'parent_id_x': 99, 'child_id_x': 1212},
          {'parent_id_x': 1010, 'child_id_x': 1111},
          {'parent_id_x': 1010, 'child_id_x': 1212},
        ]);

        // Read
        final List<UnconventionalManyToManyParent> parents =
        await repo.all().toList();
        final List<UnconventionalManyToManyChild> children =
        await childRepo.all().toList();

        // Assert
        await Future.wait(parents.map((c) => c.expectChildren(children)));
        await Future.wait(children.map((c) => c.expectParents(parents)));
      });
    });
  });
}

class UnconventionalRepository<M> extends Repository<M> {
  UnconventionalRepository.of(MapsFieldsToObject<M> mapper, Gateway gateway)
      : super.of(mapper, gateway);

  @override
  Future<M> find(int id) => where((model) => model['id_x'] == id).first();
}
