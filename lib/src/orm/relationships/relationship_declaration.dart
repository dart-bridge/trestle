part of trestle.orm;

class _RelationshipDeclarationData<Parent extends Model, Child extends Model> {
  final Iterable<RelationshipAnnotation> foreignAnnotations;
  final Iterable<Symbol> foreignNames;
  final RelationshipAnnotation annotation;
  final TypeMirror assignType;
  final Symbol name;
  final Gateway gateway;
  final MapsFieldsToModel<Parent> parentMapper;
  final MapsFieldsToModel<Child> childMapper;

  _RelationshipDeclarationData({this.foreignAnnotations,
  this.annotation,
  this.assignType,
  this.name,
  this.foreignNames,
  this.gateway,
  this.parentMapper,
  this.childMapper});
}

abstract class _RelationshipDeclaration
<Parent extends Model, Child extends Model> {
  final Iterable<RelationshipAnnotation> _foreignAnnotations;
  final Iterable<Symbol> _foreignNames;
  final RelationshipAnnotation _annotation;
  final TypeMirror _assignType;
  final Symbol _name;
  final Gateway _gateway;
  final MapsFieldsToModel<Parent> _parentMapper;
  final MapsFieldsToModel<Child> _childMapper;

  _RelationshipDeclaration(_RelationshipDeclarationData data)
      : _foreignAnnotations = data.foreignAnnotations,
        _foreignNames = data.foreignNames ?? const [],
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
    final future = _wrapInType(_assignForeign(_makeQuery(fields), model));
    final value = future is LazyFuture ? future : await future;
    set(_name, value);
  }

  RepositoryQuery _assignForeign(RepositoryQuery query, Model value) {
    var _query = query;
    for (final name in _foreignNames)
      _query = _query._assign(name, value);
    return _query;
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

  String get _myKeyOnThem => _onThem ?? _myForeign;

  String get _theirKeyOnMe => _onMe ?? _theirForeign;

  String get _myForeign => (isParent
      ? _parentMapper.foreignKey : _childMapper.foreignKey);

  String get _theirForeign => (isParent
      ? _childMapper.foreignKey : _parentMapper.foreignKey);

  String get _myKeyOnMe => _onMe ?? 'id';

  String get _theirKeyOnThem => _onThem ?? 'id';

  String get _onMe => _annotation.mine ??
      (_foreignAnnotations.length > 0 ?
      _foreignAnnotations.first?.theirs : null);

  String get _onThem => _annotation.theirs ??
      (_foreignAnnotations.length > 0 ?
      _foreignAnnotations.first?.mine : null);

  String get _pivotTable => _annotation.table ??
      (_foreignAnnotations.length > 0 ?
      _foreignAnnotations.first?.table : null) ??
      _parentMapper.pivot(_childMapper);

  String get _theirKeyOnPivot => (_foreignAnnotations.length > 0 ?
  _foreignAnnotations.first?.theirs : null) ?? _theirForeign;

  String get _myKeyOnPivot => _annotation.theirs ?? _myForeign;

  String get _theirPivotKeyOnThem => (_foreignAnnotations.length > 0 ?
  _foreignAnnotations.first?.mine : null) ?? 'id';

  RepositoryQuery<Parent> parent(Map child);

  RepositoryQuery<Child> child(Map parent);
}
