part of trestle.orm;

abstract class MapsFieldsToModel<M> {
  String get table;

  Future<M> deserialize(Map<String, dynamic> fields);

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

abstract class BaseEntity<M> implements MapsFieldsToModel<M> {
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

  Future<M> deserialize(Map<String, dynamic> fields) async {
    final instance = _type.newInstance(const Symbol(''), []);
    final model = instance.reflectee;
    for (final field in fields.keys)
      if (_fields.containsKey(field))
        instance.setField(_fields[field], fields[field]);
    _deserialized.add(model);
    return model;
  }

  Map<String, Symbol> __fields;

  Map<String, Symbol> get _fields => __fields ??= _getFields();

  Map<String, Symbol> _getFields();

  Map<String, dynamic> serialize(M model) {
    final map = <String, dynamic>{};
    for (final field in _fields.keys)
      map[field] = reflect(model)
          .getField(_fields[field])
          .reflectee;
    return map;
  }

  bool isSaved(M model) => _deserialized.contains(model);
}

class ModelEntity<M extends Model> extends BaseEntity<M> {
  final Gateway _gateway;

  ModelEntity(Gateway this._gateway, TypeMirror type) : super(type);

  String get foreignKey =>
      _camelToSnakeCase(MirrorSystem.getName(_type.simpleName)) + '_id';

  ParentChildRelationship<dynamic, M> relationshipWithParent(Type type) =>
      new ParentChildRelationship<dynamic, M>(
          _gateway, parent: type, child: _type.reflectedType);

  ParentChildRelationship<M, dynamic> relationshipWithChild(Type type) =>
      new ParentChildRelationship<M, dynamic>(
          _gateway, child: type, parent: _type.reflectedType);

  Iterable<Symbol> _getGetterSetters(bool containsMetadata(InstanceMirror i)) {
    final members = _type.instanceMembers.keys;
    return members.where((s) {
      final name = MirrorSystem.getName(s);
      return members.contains(new Symbol('$name=')) &&
          (_type as dynamic).instanceMembers[s].owner.declarations[s]
              ?.metadata
              ?.any(containsMetadata);
    });
  }

  Map<String, Symbol> _getFields() {
    final symbols = _getGetterSetters(_isFieldAnnotation);
    final Iterable<MethodMirror> mirrors = symbols.map((f) =>
    (_type as dynamic).instanceMembers[f].owner.declarations[f]);
    final fields = mirrors
        .map((m) => [m.metadata
        .firstWhere(_isFieldAnnotation)
        .reflectee, m.simpleName
    ])
        .map((fieldAndSymbol) => fieldAndSymbol[0].field
        ?? _camelToSnakeCase(MirrorSystem.getName(fieldAndSymbol[1])));
    return new Map<String, Symbol>.fromIterables(fields, symbols)
      ..addAll(new Map.fromIterables(_relationshipFieldNames(),
          _relationshipFieldSymbols()));
  }

  Iterable<String> _relationshipFieldNames() {
    return _relationshipFieldSymbols().map(MirrorSystem.getName);
  }

  bool _isFieldAnnotation(InstanceMirror meta) {
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

  @override
  Map<String, dynamic> serialize(M model) {
    return super.serialize(model);
  }

  @override
  Future<M> deserialize(Map<String, dynamic> fields,
      {bool attachRelationships: true}) {
    final model = super.deserialize(fields);
    if (attachRelationships)
      return model.then((m) => deserializeRelationships(m, fields));
    return model;
  }

  Map<String, dynamic> serializeRelationships(Map<String, dynamic> fields) {
//    final relationships = _getRelationships();
//    print(relationships);
    return fields;
  }

  List<VariableMirror> _getRelationshipDeclarations() {
    return _getGetterSetters(_isRelationshipAnnotation)
        .map((s) =>
    (_type.instanceMembers[s].owner as ClassMirror).declarations[s])
        .toList();
  }

  List<VariableMirror> __relationshipDeclarations;

  List<VariableMirror> get _relationshipDeclarations =>
      __relationshipDeclarations ??= _getRelationshipDeclarations();

  bool _isRelationshipAnnotation(InstanceMirror meta) {
    return meta.reflectee is RelationshipAnnotation;
  }

  Future<M> deserializeRelationships(M self, Map row) async {
    final mirror = reflect(self);
    final keys = _relationshipFieldSymbols()
        .where((s) => mirror
        .getField(s)
        .reflectee == null);
    final values = await _relationshipFieldValues(keys, self, row);
    new Map.fromIterables(keys, values).forEach(mirror.setField);
    return self;
  }

  Future<Iterable> _relationshipFieldValues(Iterable<Symbol> symbols, M self,
      Map row) async {
    return Future.wait(_relationshipDeclarations
        .where((m) => symbols.contains(m.simpleName))
        .map((m) => _getRelationshipProperty(self, row, m)));
  }

  Iterable<Symbol> _relationshipFieldSymbols() {
    return _relationshipDeclarations.map((m) => m.simpleName);
  }

  Future _getRelationshipProperty(M self, Map row,
      VariableMirror property) async {
    final returnType = property.type;

    // Model
    if (returnType.isAssignableTo(reflectType(Model)))
      return _assignSingleRelationship(self, row, property);

    // Future<M>
    if (returnType.isAssignableTo(reflectType(Future)))
      return _assignSingleLazyRelationship(self, property);

    // List<M>
    if (returnType.isAssignableTo(reflectType(List)))
      return _assignMultiRelationship(self, property);

    // Stream<M>
    if (returnType.isAssignableTo(reflectType(Stream)))
      return _assignMultiLazyRelationship(self, property);

    // RepositoryQuery<M>
    if (returnType.isAssignableTo(reflectType(RepositoryQuery)))
      return _assignQueryRelationship(self, property);

    throw new ArgumentError('$returnType is not a valid relationship type');
  }

  Future<Model> _assignSingleRelationship(M self, Map row,
      VariableMirror property) {
    final annotation = _relationshipAnnotation(property);
    final relatedType = _relatedType(property.type);
    final isParent = annotation is HasOne || annotation is HasMany;
    final relationship = isParent
        ? new ParentChildRelationship(
        _gateway, parent: _type.reflectedType, child: relatedType)
        : new ParentChildRelationship(
        _gateway, child: _type.reflectedType, parent: relatedType);
    if (annotation is HasOne)
      return relationship.hasOne(self, row, annotation);
    if (annotation is BelongsTo)
      return relationship.belongsTo(self, row, annotation);
    throw new ArgumentError(
        'Only a [BelongsTo] or [HasOne] annotation can assign '
            'a field of type ${property.type.reflectedType}');
  }

  Type _relatedType(TypeMirror returnType) {
    if (returnType.isAssignableTo(reflectType(Model)))
      return returnType.reflectedType;
    return returnType.typeArguments.first.reflectedType;
  }

  Future<_LazyFuture<Model>> _assignSingleLazyRelationship(M self,
      VariableMirror property) {
  }

  Future<List<Model>> _assignMultiRelationship(M self,
      VariableMirror property) {
  }

  Future<Stream<Model>> _assignMultiLazyRelationship(M self,
      VariableMirror property) {
  }

  Future<RepositoryQuery<Model>> _assignQueryRelationship(M self,
      VariableMirror property) {
  }

  RelationshipAnnotation _relationshipAnnotation(VariableMirror property) {
    return property.metadata
        .firstWhere(_isRelationshipAnnotation)
        .reflectee;
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
        '[$model] is not a Model. Only models can be updated.');
  }
}

class _LazyFuture<T> implements Future<T> {
  final Function _futureFunction;

  _LazyFuture(this._futureFunction);

  Future get _future => _futureFunction();

  @override
  Future then(onValue(T value), { Function onError }) {
    return _future.then(onValue, onError: onError);
  }

  @override
  Future catchError(Function onError,
      {bool test(Object error)}) {
    return _future.catchError(onError, test: test);
  }

  @override
  Future<T> whenComplete(action()) {
    return _future.whenComplete(action);
  }

  @override
  Stream<T> asStream() {
    return _future.asStream();
  }

  @override
  Future timeout(Duration timeLimit, {onTimeout()}) {
    return _future.timeout(timeLimit, onTimeout: onTimeout);
  }
}

