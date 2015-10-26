part of trestle.orm;

class _RelationshipDeclarationData<Parent extends Model, Child extends Model> {
  final RelationshipAnnotation foreignAnnotation;
  final Symbol foreignName;
  final RelationshipAnnotation annotation;
  final TypeMirror assignType;
  final Symbol name;
  final Gateway gateway;
  final MapsFieldsToModel<Parent> parentMapper;
  final MapsFieldsToModel<Child> childMapper;

  _RelationshipDeclarationData({this.foreignAnnotation,
  this.annotation,
  this.assignType,
  this.name,
  this.foreignName,
  this.gateway,
  this.parentMapper,
  this.childMapper});
}

abstract class _RelationshipDeclaration
<Parent extends Model, Child extends Model> {
  final RelationshipAnnotation _foreignAnnotation;
  final RelationshipAnnotation _annotation;
  final TypeMirror _assignType;
  final Symbol _foreignName;
  final Symbol _name;
  final Gateway _gateway;
  final MapsFieldsToModel<Parent> _parentMapper;
  final MapsFieldsToModel<Child> _childMapper;

  _RelationshipDeclaration(_RelationshipDeclarationData data)
      : _foreignAnnotation = data.foreignAnnotation,
        _foreignName = data.foreignName,
        _annotation = data.annotation,
        _assignType = data.assignType,
        _name = data.name,
        _gateway = data.gateway,
        _parentMapper = data.parentMapper,
        _childMapper = data.childMapper;

  RepositoryQuery _query(MapsFieldsToModel mapper,
      Query query(Query query)) {
    return new RepositoryQuery(query(_gateway.table(mapper.table)), mapper);
  }

  RepositoryQuery<Parent> _parentQuery(Query query(Query query)) =>
    _query(_parentMapper, query);

  RepositoryQuery<Child> _childQuery(Query query(Query query)) =>
    _query(_childMapper, query);

  Future resolve(
      Model model,
      Map fields,
      void set(Symbol name, Object value)) async {
    final future = _wrapInType(
        _foreignName == null
        ? _makeQuery(fields)
        : _makeQuery(fields)._assign(_foreignName, model));
    final value = future is LazyFuture ? future : await future;
    set(_name, value);
  }

  bool get isParent => _annotation is HasMany || _annotation is HasOne;

  RepositoryQuery _makeQuery(Map fields) {
    return isParent
        ? child(fields)
        : parent(fields);
  }

  Future _wrapInType(RepositoryQuery query) {
    if (_assignType.isAssignableTo(reflectType(RepositoryQuery)))
      return new Future.value(query);

    if (_assignType.isAssignableTo(reflectType(List)))
      return query.get().toList();

    if (_assignType.isAssignableTo(reflectType(Stream)))
      return new Future.value(query.get());

    if (_assignType.isAssignableTo(reflectType(Future)))
      return new LazyFuture(() => query.first().catchError((_) => null));

    return query.first().catchError((_) => null);
  }

  String get _myKeyOnThem => _myKey ?? isParent
      ? _parentMapper.foreignKey
      : _childMapper.foreignKey;

  String get _theirKeyOnMe => _theirKey ?? isParent
      ? _childMapper.foreignKey
      : _parentMapper.foreignKey;

  String get _myKeyOnMe => _myKey ?? 'id';

  String get _theirKeyOnThem => _theirKey ?? 'id';

  String get _myKey => _annotation.mine ?? _foreignAnnotation?.theirs;

  String get _theirKey => _annotation.theirs ?? _foreignAnnotation?.mine;

  RepositoryQuery<Parent> parent(Map child);

  RepositoryQuery<Child> child(Map parent);
}
