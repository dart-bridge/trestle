part of trestle.orm;

abstract class Entity<M> {
  String get table;

  M deserialize(Map<String, dynamic> fields);

  Map<String, dynamic> serialize(M model);

  bool isSaved(M model);

  Query find(Query query, M model);
}

String _camelToSnakeCase(String camelCase) {
  return camelCase
      .replaceAllMapped(new RegExp(r'[A-Z]'), (m) => '_${m[0].toLowerCase()}')
      .replaceFirst(new RegExp(r'^_'), '');
}

String _pluralize(String singular) {
  return singular.endsWith('y')
      ? singular.replaceFirst(new RegExp(r'y$'), 'ies')
      : singular.endsWith('s')
      ? '${singular}es'
      : '${singular}s';
}

abstract class BaseEntity<M> implements Entity<M> {
  String _table;

  String get table => _table;
  final ClassMirror _type;
  final List<M> _deserialized = [];

  BaseEntity(TypeMirror type)
      : _type = type {
    _table = _getTableName(type);
  }

  String _forceTableName(String table) => table;

  String _getTableName(TypeMirror type) {
    return _forceTableName(_pluralize(_camelToSnakeCase(
        MirrorSystem.getName(type.simpleName))));
  }

  M deserialize(Map<String, dynamic> fields) {
    final fieldsWithRelationships = _deserializeRelationships(fields);
    final instance = _type.newInstance(const Symbol(''), []);
    for (final field in fieldsWithRelationships.keys)
      if (_fields.containsKey(field))
        instance.setField(_fields[field], fieldsWithRelationships[field]);
    final model = instance.reflectee;
    _deserialized.add(model);
    return model;
  }

  Map<String, Symbol> __fields;

  Map<String, Symbol> get _fields => __fields ??= _getFields();

  Map<String, Symbol> _getFields();

  Map<String, dynamic> _serializeRelationships(Map<String, dynamic> fields) {
    return fields;
  }

  Map<String, dynamic> _deserializeRelationships(Map<String, dynamic> fields) {
    return fields;
  }

  Map<String, dynamic> serialize(M model) {
    final map = <String, dynamic>{};
    for (final field in _fields.keys)
      map[field] = reflect(model)
          .getField(_fields[field])
          .reflectee;
    return _serializeRelationships(map);
  }

  bool isSaved(M model) => _deserialized.contains(model);
}

class ModelEntity<M extends Model> extends BaseEntity<M> {
  ModelEntity(TypeMirror type) : super(type);

  Relationship<dynamic, M> relationshipWithParent(Type type) =>
      new Relationship<dynamic, M>(parent: type, child: _type.reflectedType);

  Relationship<M, dynamic> relationshipWithChild(Type type) =>
      new Relationship<M, dynamic>(child: type, parent: _type.reflectedType);

  Map<String, Symbol> _getFields() {
    final members = _type.instanceMembers.keys;
    final symbols = members.where((s) {
      final name = MirrorSystem.getName(s);
      return members.contains(new Symbol('$name=')) &&
          (_type as dynamic).instanceMembers[s].owner.declarations[s]
              ?.metadata
              ?.any(_isFieldMetadata);
    });
    final Iterable<MethodMirror> mirrors = symbols.map((f) =>
    (_type as dynamic).instanceMembers[f].owner.declarations[f]);
    final fields = mirrors
        .map((m) => [m.metadata
        .firstWhere(_isFieldMetadata)
        .reflectee, m.simpleName
    ])
        .map((fieldAndSymbol) => fieldAndSymbol[0].field
        ?? _camelToSnakeCase(MirrorSystem.getName(fieldAndSymbol[1])));
    return new Map<String, Symbol>.fromIterables(fields, symbols);
  }

  bool _isFieldMetadata(InstanceMirror meta) {
    return meta.reflectee is Field;
  }

  find(Query query, M model) => query.where((other) => other.id == model.id);

  @override
  String _forceTableName(String table) {
    if (_type.declarations.containsKey(#table))
      return _type
          .getField(#table)
          .reflectee;
    return table;
  }
}

class DataStructureEntity<M> extends BaseEntity<M> {
  DataStructureEntity(TypeMirror type) : super(type);

  Map<String, Symbol> _getFields() {
    final members = _type.instanceMembers.keys;
    final symbols = members.where((s) {
      final name = MirrorSystem.getName(s);
      return members.contains(new Symbol('$name='));
    });
    final fields = symbols.map(MirrorSystem.getName).map(_camelToSnakeCase);
    return new Map<String, Symbol>.fromIterables(fields, symbols);
  }

  find(Query query, M model) {
    throw new UnsupportedError(
        '[$M] is not a Model. Only models can be updated.');
  }
}
