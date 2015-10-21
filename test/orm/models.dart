import 'package:test/test.dart';
import 'dart:async';
import 'package:trestle/trestle.dart';

typedef void TableExpectation(String table);

typedef void ContentExpectation(Map<String, dynamic> content);

typedef Future ModelExpectation(Model model);

typedef Future ModelsExpectation(List<Model> models);

TableExpectation expectedTable(String expected) {
  return (String table) {
    expect(table, equals(expected));
  };
}

ContentExpectation expectedContent(Map<String, dynamic> expected) {
  return (Map<String, dynamic> content) {
    expect(content, equals(expected));
  };
}

ModelExpectation expectedModel(List expected()) {
  return (Model model) async {
    final both = expected();
    Model eager = both[0];
    Model lazy = await both[1];
    expect(model.id, equals(lazy.id));
    expect(model.id, equals(eager.id));
  };
}

void expectModels(List<Model> models, List<Model> expected) {
  if (models.length != expected.length)
    fail('Model lists are of different length');
  for (var i = 0; i < models.length; i++)
    expect(models[i].id, equals(expected[i].id));
}

ModelsExpectation expectedModels(List expected()) {
  return (List<Model> models) async {
    final all = expected();
    List<Model> eager = all[0];
    List<Model> lazy = await all[1].toList();
    List<Model> query = await all[2].get().toList();
    expectModels(eager, lazy);
    expectModels(eager, query);
    expectModels(eager, expected);
  };
}

class DataStructure {
  String property;
  String camelCase;

  ContentExpectation get expectContent => expectedContent({
    'property': property,
    'camel_case': camelCase,
  });

  TableExpectation get expectTable => expectedTable('data_structures');
}

class SimpleModel extends Model {
  @field String property;
  @field String camelCase;
  @Field('completely_overridden') String overridden;
  String willNotBeSerialized;

  ContentExpectation get expectContent => expectedContent({
    'id': id,
    'created_at': createdAt,
    'updated_at': updatedAt,
    'property': property,
    'camel_case': camelCase,
    'completely_overridden': overridden,
  });

  TableExpectation get expectTable => expectedTable('simple_models');
}

class ModelWithOverriddenTableName extends Model {
  static const table = 'overriden';

  TableExpectation get expectTable => expectedTable(table);
}

// Relationships

class ConventionalOneToOneParent extends Model {
  static const table = 'parent';

  @hasOne ConventionalOneToOneChild child;
  @hasOne Future<ConventionalOneToOneChild> lazyChild;

  ModelExpectation get expectModel => expectedModel(() => [child, lazyChild]);
}

class ConventionalOneToOneChild extends Model {
  static const table = 'child';

  @belongsTo ConventionalOneToOneParent parent;
  @belongsTo Future<ConventionalOneToOneParent> lazyParent;

  ModelExpectation get expectModel => expectedModel(() => [parent, lazyParent]);
}

class ConventionalOneToManyParent extends Model {
  static const table = 'parent';

  @hasMany List<ConventionalOneToManyChild> children;
  @hasMany Stream<ConventionalOneToManyChild> lazyChildren;
  @hasMany RepositoryQuery<ConventionalOneToManyChild> queryChildren;

  ModelsExpectation get expectModels =>
      expectedModels(() => [children, lazyChildren, queryChildren]);
}

class ConventionalOneToManyChild extends Model {
  static const table = 'child';

  @belongsTo ConventionalOneToManyParent parent;
  @belongsTo Future<ConventionalOneToManyParent> lazyParent;

  ModelExpectation get expectModel => expectedModel(() => [parent, lazyParent]);
}

class ConventionalManyToOneParent extends Model {
  static const table = 'parent';

  @hasOne ConventionalManyToOneChild child;
  @hasOne Future<ConventionalManyToOneChild> lazyChild;

  ModelExpectation get expectModel => expectedModel(() => [child, lazyChild]);
}

class ConventionalManyToOneChild extends Model {
  static const table = 'child';

  @belongsToMany List<ConventionalManyToOneParent> parents;
  @belongsToMany Stream<ConventionalManyToOneParent> lazyParents;
  @belongsToMany RepositoryQuery<ConventionalManyToOneParent> queryParents;

  ModelsExpectation get expectModels =>
      expectedModels(() => [parents, lazyParents, queryParents]);
}

class ConventionalManyToManyParent extends Model {
  static const table = 'parent';

  @hasMany List<ConventionalManyToManyChild> children;
  @hasMany Stream<ConventionalManyToManyChild> lazyChildren;
  @hasMany RepositoryQuery<ConventionalManyToManyChild> queryChildren;

  ModelsExpectation get expectModels =>
      expectedModels(() => [children, lazyChildren, queryChildren]);
}

class ConventionalManyToManyChild extends Model {
  static const table = 'child';

  @belongsToMany List<ConventionalManyToManyParent> parents;
  @belongsToMany Stream<ConventionalManyToManyParent> lazyParents;
  @belongsToMany RepositoryQuery<ConventionalManyToManyParent> queryParents;

  ModelsExpectation get expectModels =>
      expectedModels(() => [parents, lazyParents, queryParents]);
}

// Unconventional relationships

class UnconventionalOneToOneParent extends Model {
  static const table = 'parent';

  @hasOne UnconventionalOneToOneChild child;
  @hasOne Future<UnconventionalOneToOneChild> lazyChild;

  ModelExpectation get expectModel => expectedModel(() => [child, lazyChild]);
}

class UnconventionalOneToOneChild extends Model {
  static const table = 'child';

  @belongsTo UnconventionalOneToOneParent parent;
  @belongsTo Future<UnconventionalOneToOneParent> lazyParent;

  ModelExpectation get expectModel => expectedModel(() => [parent, lazyParent]);
}

class UnconventionalOneToManyParent extends Model {
  static const table = 'parent';

  @hasMany List<UnconventionalOneToManyChild> children;
  @hasMany Stream<UnconventionalOneToManyChild> lazyChildren;
  @hasMany RepositoryQuery<UnconventionalOneToManyChild> queryChildren;

  ModelsExpectation get expectModels =>
      expectedModels(() => [children, lazyChildren, queryChildren]);
}

class UnconventionalOneToManyChild extends Model {
  static const table = 'child';

  @belongsTo UnconventionalOneToManyParent parent;
  @belongsTo Future<UnconventionalOneToManyParent> lazyParent;

  ModelExpectation get expectModel => expectedModel(() => [parent, lazyParent]);
}

class UnconventionalManyToOneParent extends Model {
  static const table = 'parent';

  @hasOne UnconventionalManyToOneChild child;
  @hasOne Future<UnconventionalManyToOneChild> lazyChild;

  ModelExpectation get expectModel => expectedModel(() => [child, lazyChild]);
}

class UnconventionalManyToOneChild extends Model {
  static const table = 'child';

  @belongsToMany List<UnconventionalManyToOneParent> parents;
  @belongsToMany Stream<UnconventionalManyToOneParent> lazyParents;
  @belongsToMany RepositoryQuery<UnconventionalManyToOneParent> queryParents;

  ModelsExpectation get expectModels =>
      expectedModels(() => [parents, lazyParents, queryParents]);
}

class UnconventionalManyToManyParent extends Model {
  static const table = 'parent';

  @hasMany List<UnconventionalManyToManyChild> children;
  @hasMany Stream<UnconventionalManyToManyChild> lazyChildren;
  @hasMany RepositoryQuery<UnconventionalManyToManyChild> queryChildren;

  ModelsExpectation get expectModels =>
      expectedModels(() => [children, lazyChildren, queryChildren]);
}

class UnconventionalManyToManyChild extends Model {
  static const table = 'child';

  @belongsToMany List<UnconventionalManyToManyParent> parents;
  @belongsToMany Stream<UnconventionalManyToManyParent> lazyParents;
  @belongsToMany RepositoryQuery<UnconventionalManyToManyParent> queryParents;

  ModelsExpectation get expectModels =>
      expectedModels(() => [parents, lazyParents, queryParents]);
}

