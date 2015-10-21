import 'package:test/test.dart';
import 'dart:async';
import 'package:trestle/trestle.dart';

typedef void TableExpectation(String table);

typedef void ContentExpectation(Map<String, dynamic> content);

typedef Future ModelExpectation(Model model);

typedef Future ModelsExpectation(List<Model> models);

TableExpectation expectedTable(String table) {
  return (String expected) {
    expect(table, equals(expected));
  };
}

ContentExpectation expectedContent(Map<String, dynamic> content) {
  return (Map<String, dynamic> expected) {
    expect(content, equals(expected));
  };
}

ModelExpectation expectedModel(List model()) {
  return (Model expected) async {
    final both = model();
    Model eager = both[0];
    Model lazy = await both[1];
    expect(eager.id, equals(lazy.id));
    expect(eager.id, equals(expected.id));
  };
}

void expectModels(List<Model> models, List<Model> expected) {
  if (models.length != expected.length)
    fail('Model lists are of different length');
  for (var i = 0; i < models.length; i++)
    expect(models[i].id, equals(expected[i].id));
}

ModelsExpectation expectedModels(List models()) {
  return (List<Model> expected) async {
    final all = models();
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

  TableExpectation get expectTable => expectedTable('overriden');
}

// Relationships

class ConventionalOneToOneParent extends Model {
  static const table = 'parent';

  @hasOne ConventionalOneToOneChild child;
  @hasOne Future<ConventionalOneToOneChild> lazyChild;
}

class ConventionalOneToOneChild extends Model {
  static const table = 'child';

  @belongsTo ConventionalOneToOneParent parent;
  @belongsTo Future<ConventionalOneToOneParent> lazyParent;
}

class ConventionalOneToManyParent extends Model {
  static const table = 'parent';

  @hasMany List<ConventionalOneToManyChild> children;
  @hasMany Stream<ConventionalOneToManyChild> lazyChildren;
  @hasMany RepositoryQuery<ConventionalOneToManyChild> queryChildren;
}

class ConventionalOneToManyChild extends Model {
  static const table = 'child';

  @belongsTo ConventionalOneToManyParent parent;
  @belongsTo Future<ConventionalOneToManyParent> lazyParent;
}

class ConventionalManyToOneParent extends Model {
  static const table = 'parent';

  @hasOne ConventionalManyToOneChild child;
  @hasOne Future<ConventionalManyToOneChild> lazyChild;
}

class ConventionalManyToOneChild extends Model {
  static const table = 'child';

  @belongsToMany List<ConventionalManyToOneParent> parents;
  @belongsToMany Stream<ConventionalManyToOneParent> lazyParents;
  @belongsToMany RepositoryQuery<ConventionalManyToOneParent> queryParents;
}

class ConventionalManyToManyParent extends Model {
  static const table = 'parent';

  @hasMany List<ConventionalManyToManyChild> children;
  @hasMany Stream<ConventionalManyToManyChild> lazyChildren;
  @hasMany RepositoryQuery<ConventionalManyToManyChild> queryChildren;
}

class ConventionalManyToManyChild extends Model {
  static const table = 'child';

  @belongsToMany List<ConventionalManyToManyParent> parents;
  @belongsToMany Stream<ConventionalManyToManyParent> lazyParents;
  @belongsToMany RepositoryQuery<ConventionalManyToManyParent> queryParents;
}

