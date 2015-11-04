part of trestle.orm;

class MapsFieldsToModel<M extends Model> extends MapsFieldsToObjectBase<M> {
  final Gateway _gateway;

  MapsFieldsToModel(Gateway this._gateway, TypeMirror type) : super(type);

  String get foreignKey => MapsFieldsToObject._camelToSnakeCase(
      MirrorSystem.getName(_type.simpleName)) + '_id';

  Map<String, Symbol> _findFields() {
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
    return new Map<String, Symbol>.fromIterables(fields, symbols);
  }

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
  Future<M> deserialize(Map<String, dynamic> fields,
      [Map<Symbol, List> assignments = const {}]) {
    return super.deserialize(fields)
        .then((m) => _attachAssignments(m, assignments))
        .then((m) => _attachRelationships(m, fields));
  }

  @override
  Map<String, dynamic> serialize(M model,
      [bool skipRelationships = false]) {
    if (model == null) return null;
    final serialized = super.serialize(model);
    if (skipRelationships)
      return serialized;
    return _detachRelationships(model, serialized);
  }


  Map<String, dynamic> _detachRelationships(M model, Map row) {
    final result = new Map.from(row);
    for (final relationship in _relationships)
      relationship.detach(row, model, ((k, v) => result[k] = v));
    return result;
  }

  _attachAssignments(M model, Map<Symbol, List> assignments) {
    final mirror = reflect(model);
    for (final symbol in assignments.keys) {
      final returnType = mirror.type.instanceMembers[symbol].returnType;
      final value = _castModels(assignments[symbol], returnType);
      mirror.setField(symbol, value);
    }
    return model;
  }

  Object _castModels(List<Model> models, TypeMirror type) {
    if (type.isAssignableTo(reflectType(Future)))
      return new LazyFuture(() => models.first);
    if (type.isAssignableTo(reflectType(List)))
      return new List.from(models);
    if (type.isAssignableTo(reflectType(Stream)))
      return new Stream.fromIterable(models);
    if (type.isAssignableTo(reflectType(RepositoryQuery)))
      return null;
    return models.first;
  }

  Future<M> _attachRelationships(M model, Map<String, dynamic> fields) async {
    final mirror = reflect(model);
    for (final relationship in _relationships) {
      if (mirror
          .getField(relationship._name)
          .reflectee == null)
        await relationship.attach(model, fields, mirror.setField);
    }
    return model;
  }

  Iterable<_RelationshipDeclaration> __relationships;

  Iterable<_RelationshipDeclaration> get _relationships =>
      __relationships ??= _getRelationships();

  Iterable<_RelationshipDeclaration> _getRelationships() {
    return _relationshipFields().map((VariableMirror mirror) {
      final myMapper = new MapsFieldsToModel(_gateway, _type);
      final theirMapper = new MapsFieldsToModel(_gateway,
          mirror.type.isAssignableTo(reflectType(Model))
              ? mirror.type
              : mirror.type.typeArguments.first);
      final myAnnotation = _myAnnotation(mirror);
      final theirAnnotations = _theirAnnotations(mirror);
      final theirNames = _theirNames(mirror);
      final isParent = myAnnotation is HasOne || myAnnotation is HasMany;
      final childMapper = isParent ? theirMapper : myMapper;
      final parentMapper = isParent ? myMapper : theirMapper;
      final data = new _RelationshipDeclarationData(
          foreignAnnotations: theirAnnotations,
          foreignNames: theirNames,
          annotation: myAnnotation,
          assignType: mirror.type,
          name: mirror.simpleName,
          gateway: _gateway,
          parentMapper: parentMapper,
          childMapper: childMapper
      );
      if (theirAnnotations.length > 0) {
        if (myAnnotation is HasOne && theirAnnotations.first is BelongsTo)
          return new _OneToOneRelationship(data);
        if (myAnnotation is HasMany && theirAnnotations.first is BelongsTo)
          return new _OneToManyRelationship(data);
        if (myAnnotation is HasOne && theirAnnotations.first is BelongsToMany)
          return new _ManyToOneRelationship(data);
        if (myAnnotation is HasMany && theirAnnotations.first is BelongsToMany)
          return new _ManyToManyRelationship(data);
        if (myAnnotation is BelongsTo && theirAnnotations.first is HasOne)
          return new _OneToOneRelationship(data);
        if (myAnnotation is BelongsTo && theirAnnotations.first is HasMany)
          return new _OneToManyRelationship(data);
        if (myAnnotation is BelongsToMany && theirAnnotations.first is HasOne)
          return new _ManyToOneRelationship(data);
        if (myAnnotation is BelongsToMany && theirAnnotations.first is HasMany)
          return new _ManyToManyRelationship(data);
      }
      if (myAnnotation is HasOne)
        return new _OneToOneRelationship(data);
      if (myAnnotation is HasMany)
        return new _ManyToOneRelationship(data);
      if (myAnnotation is BelongsTo)
        return new _OneToOneRelationship(data);
      if (myAnnotation is BelongsToMany)
        return new _OneToManyRelationship(data);
      throw new ArgumentError('Invalid relationship declaration: '
          '[$myAnnotation] and [$theirAnnotations]');
    });
  }

  RelationshipAnnotation _myAnnotation(VariableMirror mirror) {
    return (mirror.owner as ClassMirror)
        .declarations[mirror.simpleName]
        .metadata
        .firstWhere(_isRelationshipMetadata, orElse: () => null)
        .reflectee;
  }

  bool _isRelationshipMetadata(InstanceMirror mirror) {
    return mirror.reflectee is RelationshipAnnotation;
  }

  Iterable<DeclarationMirror> _theirDeclarations(VariableMirror mirror) {
    final ClassMirror classMirror = mirror.type
        .isAssignableTo(reflectType(Model))
        ? mirror.type
        : mirror.type.typeArguments.first;
    return classMirror.instanceMembers.values
        .where((i) => _isValidRelationshipAssign(i.returnType, _type))
        .where((i) => i.owner is ClassMirror &&
        (i.owner as ClassMirror).declarations.containsKey(i.simpleName) &&
        (i.owner as ClassMirror).declarations[i.simpleName].metadata.any(
            _isRelationshipMetadata))
        .map((i) => (i.owner as ClassMirror).declarations[i.simpleName]);
  }

  Iterable<RelationshipAnnotation> _theirAnnotations(VariableMirror mirror) {
    final declarations = _theirDeclarations(mirror);
    return declarations.map((declaration) => declaration.metadata
        .firstWhere(_isRelationshipMetadata)
        .reflectee);
  }

  Iterable<Symbol> _theirNames(VariableMirror mirror) {
    final declarations = _theirDeclarations(mirror);
    return declarations.map((declaration) => declaration.simpleName);
  }

  bool _isValidRelationshipAssign(TypeMirror local,
      TypeMirror foreign) {
    return local.reflectedType != dynamic &&
        local.isAssignableTo(foreign) ||
        (local.typeArguments.length == 1 &&
            local.typeArguments.first.isAssignableTo(foreign));
  }

  Iterable<VariableMirror> _relationshipFields() {
    return _getGetterSetters(_isRelationshipMetadata)
        .map((s) => (_type.instanceMembers[s].owner as ClassMirror)
        .declarations[s]);
  }

  String pivot(MapsFieldsToModel other) {
    return '${table}_${other.table}';
  }
}

