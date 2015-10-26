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
  Future<M> deserialize(Map<String, dynamic> fields) async {
    return super.deserialize(fields)
        .then((m) => _attachRelationships(m, fields));
  }

  Future<M> _attachRelationships(M model, Map<String, dynamic> fields) async {
    final mirror = reflect(model);
    for (final relationship in _relationships)
      await relationship.resolve(model, fields, mirror.setField);
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
      final theirAnnotation = _theirAnnotation(mirror);
      final theirName = _theirName(mirror);
      final isParent = myAnnotation is HasOne ||
          myAnnotation is HasMany;
      final childMapper = isParent ? theirMapper : myMapper;
      final parentMapper = isParent ? myMapper : theirMapper;
      final data = new _RelationshipDeclarationData(
          foreignAnnotation: theirAnnotation,
          foreignName: theirName,
          annotation: myAnnotation,
          assignType: mirror.type,
          name: mirror.simpleName,
          gateway: _gateway,
          parentMapper: parentMapper,
          childMapper: childMapper
      );
      if (myAnnotation is HasOne && theirAnnotation is BelongsTo)
        return new _OneToOneRelationship(data);
      if (myAnnotation is HasMany && theirAnnotation is BelongsTo)
        return new _OneToManyRelationship(data);
      if (myAnnotation is HasOne && theirAnnotation is BelongsToMany)
        return new _ManyToOneRelationship(data);
      if (myAnnotation is HasMany && theirAnnotation is BelongsToMany)
        return new _ManyToManyRelationship(data);
      if (myAnnotation is HasOne)
        return new _OneToOneRelationship(data);
      if (myAnnotation is HasMany)
        return new _ManyToOneRelationship(data);
      if (myAnnotation is BelongsTo)
        return new _OneToOneRelationship(data);
      if (myAnnotation is BelongsToMany)
        return new _OneToManyRelationship(data);
      throw new ArgumentError('Invalid relationship declaration: '
          '[$myAnnotation] and [$theirAnnotation]');
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

  DeclarationMirror _theirDeclaration(VariableMirror mirror) {
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
        .map((i) => (i.owner as ClassMirror).declarations[i.simpleName]).first;
  }

  RelationshipAnnotation _theirAnnotation(VariableMirror mirror) {
    final declaration = _theirDeclaration(mirror);
    return declaration.metadata.firstWhere(_isRelationshipMetadata).reflectee;
  }

  Symbol _theirName(VariableMirror mirror) {
    final declaration = _theirDeclaration(mirror);
    return declaration.simpleName;
  }

  bool _isValidRelationshipAssign(TypeMirror local,
      TypeMirror foreign) {
    return !local.isAssignableTo(reflectType(dynamic)) &&
      local.isAssignableTo(foreign) ||
        (local.typeArguments.length == 1 &&
            local.typeArguments.first.isAssignableTo(foreign));
  }

  Iterable<VariableMirror> _relationshipFields() {
    return _getGetterSetters(_isRelationshipMetadata)
        .map((s) => (_type.instanceMembers[s].owner as ClassMirror)
        .declarations[s]);
  }
}

