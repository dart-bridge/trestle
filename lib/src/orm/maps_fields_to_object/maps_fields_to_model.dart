part of trestle.orm;

class MapsFieldsToModel<M extends Model> extends MapsFieldsToObjectBase<M> {
  final Gateway _gateway;

  MapsFieldsToModel(Gateway this._gateway, TypeMirror type) : super(type);

  String get foreignKey => MapsFieldsToObject._camelToSnakeCase(
      MirrorSystem.getName(_type.simpleName)) + '_id';

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
        ?? MapsFieldsToObject._camelToSnakeCase(
            MirrorSystem.getName(fieldAndSymbol[1])));
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
  String _overrideTableName(String table) {
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
    final values = await _relationshipFieldValues(keys, self, row).toList();
    new Map.fromIterables(keys, values).forEach(mirror.setField);
    return self;
  }

  Stream _relationshipFieldValues(Iterable<Symbol> symbols, M self,
      Map row) async* {
    final futures = _relationshipDeclarations
        .where((m) => symbols.contains(m.simpleName))
        .map((m) => _getRelationshipProperty(self, row, m));
    for (final future in futures) {
      if (future is LazyFuture)
        yield future;
      else yield await future;
    }
  }

  Iterable<Symbol> _relationshipFieldSymbols() {
    return _relationshipDeclarations.map((m) => m.simpleName);
  }

  Future _getRelationshipProperty(M self, Map row,
      VariableMirror property) {
    final returnType = property.type;

    // Model
    if (returnType.isAssignableTo(reflectType(Model)))
      return _assignSingleRelationship(self, row, property);

    // Future<M>
    if (returnType.isAssignableTo(reflectType(Future)))
      return _assignSingleLazyRelationship(self, row, property);

    // List<M>
    if (returnType.isAssignableTo(reflectType(List)))
      return _assignMultiRelationship(self, row, property);

    // Stream<M>
    if (returnType.isAssignableTo(reflectType(Stream)))
      return _assignMultiLazyRelationship(self, row, property);

    // RepositoryQuery<M>
    if (returnType.isAssignableTo(reflectType(RepositoryQuery)))
      return _assignQueryRelationship(self, row, property);

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

  LazyFuture<Model> _assignSingleLazyRelationship(M self, Map row,
      VariableMirror property) {
    return new LazyFuture(() {
      return _assignSingleRelationship(self, row, property);
    });
  }

  Future<List<Model>> _assignMultiRelationship(M self, Map row,
      VariableMirror property) {
    return _assignQueryRelationship(self, row, property)
        .then((q) => q.get().toList());
  }

  Future<Stream<Model>> _assignMultiLazyRelationship(M self, Map row,
      VariableMirror property) {
    return _assignQueryRelationship(self, row, property).then((q) => q.get());
  }

  Future<RepositoryQuery<Model>> _assignQueryRelationship(M self, Map row,
      VariableMirror property) {
    final annotation = _relationshipAnnotation(property);
    final relatedType = _relatedType(property.type);
    final isParent = annotation is HasOne || annotation is HasMany;
    final relationship = isParent
        ? new ParentChildRelationship(
        _gateway, parent: _type.reflectedType, child: relatedType)
        : new ParentChildRelationship(
        _gateway, child: _type.reflectedType, parent: relatedType);
    if (annotation is HasMany)
      return relationship.hasMany(self, annotation);
    if (annotation is BelongsToMany)
      return relationship.belongsToMany(self, annotation);
    throw new ArgumentError(
        'Only a [BelongsToMany] or [HasMany] annotation can assign '
            'a field of type ${property.type.reflectedType}');
  }

  RelationshipAnnotation _relationshipAnnotation(VariableMirror property) {
    return property.metadata
        .firstWhere(_isRelationshipAnnotation)
        .reflectee;
  }
}

