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
    for(final key in expected.keys)
      expect(content[key], equals(expected[key]));
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
    expectModels(eager, models);
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
  static const table = 'parents';

  @hasOne ConventionalOneToOneChild child;
  @hasOne Future<ConventionalOneToOneChild> lazyChild;

  ModelExpectation get expectChild => expectedModel(() => [child, lazyChild]);
}

class ConventionalOneToOneChild extends Model {
  static const table = 'children';

  @belongsTo ConventionalOneToOneParent parent;
  @belongsTo Future<ConventionalOneToOneParent> lazyParent;

  ModelExpectation get expectParent => expectedModel(() => [parent, lazyParent]);
}

class ConventionalOneToManyParent extends Model {
  static const table = 'parents';

  @hasMany List<ConventionalOneToManyChild> children;
  @hasMany Stream<ConventionalOneToManyChild> lazyChildren;
  @hasMany RepositoryQuery<ConventionalOneToManyChild> queryChildren;

  ModelsExpectation get expectChildren =>
      expectedModels(() => [children, lazyChildren, queryChildren]);
}

class ConventionalOneToManyChild extends Model {
  static const table = 'children';

  @belongsTo ConventionalOneToManyParent parent;
  @belongsTo Future<ConventionalOneToManyParent> lazyParent;

  ModelExpectation get expectParent => expectedModel(() => [parent, lazyParent]);
}

class ConventionalManyToOneParent extends Model {
  static const table = 'parents';

  @hasOne ConventionalManyToOneChild child;
  @hasOne Future<ConventionalManyToOneChild> lazyChild;

  ModelExpectation get expectChild => expectedModel(() => [child, lazyChild]);
}

class ConventionalManyToOneChild extends Model {
  static const table = 'children';

  @belongsToMany List<ConventionalManyToOneParent> parents;
  @belongsToMany Stream<ConventionalManyToOneParent> lazyParents;
  @belongsToMany RepositoryQuery<ConventionalManyToOneParent> queryParents;

  ModelsExpectation get expectParents =>
      expectedModels(() => [parents, lazyParents, queryParents]);
}

class ConventionalManyToManyParent extends Model {
  static const table = 'parents';

  @hasMany List<ConventionalManyToManyChild> children;
  @hasMany Stream<ConventionalManyToManyChild> lazyChildren;
  @hasMany RepositoryQuery<ConventionalManyToManyChild> queryChildren;

  ModelsExpectation get expectChildren =>
      expectedModels(() => [children, lazyChildren, queryChildren]);
}

class ConventionalManyToManyChild extends Model {
  static const table = 'children';

  @belongsToMany List<ConventionalManyToManyParent> parents;
  @belongsToMany Stream<ConventionalManyToManyParent> lazyParents;
  @belongsToMany RepositoryQuery<ConventionalManyToManyParent> queryParents;

  ModelsExpectation get expectParents =>
      expectedModels(() => [parents, lazyParents, queryParents]);
}

// Unconventional relationships

class UnconventionalOneToOneParent extends Model {
  static const table = 'parents_x';

  @override @Field('id_x') int id;

  @HasOne(mine: 'child_id_x', theirs: 'id_x')
  UnconventionalOneToOneChild child;
  @HasOne(mine: 'child_id_x', theirs: 'id_x')
  Future<UnconventionalOneToOneChild> lazyChild;

  ModelExpectation get expectChild => expectedModel(() => [child, lazyChild]);
}

class UnconventionalOneToOneChild extends Model {
  static const table = 'children_x';

  @override @Field('id_x') int id;

  @BelongsTo(mine: 'id_x', theirs: 'child_id_x')
  UnconventionalOneToOneParent parent;
  @BelongsTo(mine: 'id_x', theirs: 'child_id_x')
  Future<UnconventionalOneToOneParent> lazyParent;

  ModelExpectation get expectParent => expectedModel(() => [parent, lazyParent]);
}

class UnconventionalOneToManyParent extends Model {
  static const table = 'parents_x';

  @override @Field('id_x') int id;

  @HasMany(mine: 'id_x', theirs: 'parent_id_x')
  List<UnconventionalOneToManyChild> children;
  @HasMany(mine: 'id_x', theirs: 'parent_id_x')
  Stream<UnconventionalOneToManyChild> lazyChildren;
  @HasMany(mine: 'id_x', theirs: 'parent_id_x')
  RepositoryQuery<UnconventionalOneToManyChild> queryChildren;

  ModelsExpectation get expectChildren =>
      expectedModels(() => [children, lazyChildren, queryChildren]);
}

class UnconventionalOneToManyChild extends Model {
  static const table = 'children_x';

  @override @Field('id_x') int id;

  @BelongsTo(mine: 'parent_id_x', theirs: 'id_x')
  UnconventionalOneToManyParent parent;
  @BelongsTo(mine: 'parent_id_x', theirs: 'id_x')
  Future<UnconventionalOneToManyParent> lazyParent;

  ModelExpectation get expectParent => expectedModel(() => [parent, lazyParent]);
}

class UnconventionalManyToOneParent extends Model {
  static const table = 'parents_x';

  @override @Field('id_x') int id;

  @HasOne(mine: 'child_id_x', theirs: 'id_x')
  UnconventionalManyToOneChild child;
  @HasOne(mine: 'child_id_x', theirs: 'id_x')
  Future<UnconventionalManyToOneChild> lazyChild;

  ModelExpectation get expectChild => expectedModel(() => [child, lazyChild]);
}

class UnconventionalManyToOneChild extends Model {
  static const table = 'children_x';

  @override @Field('id_x') int id;

  @BelongsToMany(mine: 'id_x', theirs: 'child_id_x')
  List<UnconventionalManyToOneParent> parents;
  @BelongsToMany(mine: 'id_x', theirs: 'child_id_x')
  Stream<UnconventionalManyToOneParent> lazyParents;
  @BelongsToMany(mine: 'id_x', theirs: 'child_id_x')
  RepositoryQuery<UnconventionalManyToOneParent> queryParents;

  ModelsExpectation get expectParents =>
      expectedModels(() => [parents, lazyParents, queryParents]);
}

class UnconventionalManyToManyParent extends Model {
  static const table = 'parents_x_mtm';

  @override @Field('id_x') int id;

  @HasMany(mine: 'id_x',
      theirs: 'parent_id_x',
      table: 'parents_children_x')
  List<UnconventionalManyToManyChild> children;
  @HasMany(mine: 'id_x',
      theirs: 'parent_id_x',
      table: 'parents_children_x')
  Stream<UnconventionalManyToManyChild> lazyChildren;
  @HasMany(mine: 'id_x',
      theirs: 'parent_id_x',
      table: 'parents_children_x')
  RepositoryQuery<UnconventionalManyToManyChild> queryChildren;

  ModelsExpectation get expectChildren =>
      expectedModels(() => [children, lazyChildren, queryChildren]);
}

class UnconventionalManyToManyChild extends Model {
  static const table = 'children_x_mtm';

  @override @Field('id_x') int id;

  @BelongsToMany(mine: 'id_x',
      theirs: 'child_id_x',
      table: 'parents_children_x')
  List<UnconventionalManyToManyParent> parents;
  @BelongsToMany(mine: 'id_x',
      theirs: 'child_id_x',
      table: 'parents_children_x')
  Stream<UnconventionalManyToManyParent> lazyParents;
  @BelongsToMany(mine: 'id_x',
      theirs: 'child_id_x',
      table: 'parents_children_x')
  RepositoryQuery<UnconventionalManyToManyParent> queryParents;

  ModelsExpectation get expectParents =>
      expectedModels(() => [parents, lazyParents, queryParents]);
}

