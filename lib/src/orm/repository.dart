part of trestle.orm;

class Repository<M> {
  Gateway _gateway;
  String _table;
  final ClassMirror _classMirror;

  Repository._of(Type type)
      : _classMirror = reflectType(type);

  Repository()
      : _classMirror = reflectType(M);

  RepositoryQuery<M> _query() {
    final q = new Query(_gateway.driver, table);
    if (M == dynamic) return new RepositoryQuery._of(
        _classMirror.reflectedType, q);
    return new RepositoryQuery._copy(_classMirror, q);
  }

  void connect(Gateway gateway) {
    _gateway = gateway;
  }

  String get table {
    return _table ?? (_table = _inferTableName());
  }

  String _inferTableName() {
    return (MirrorSystem.getName(_classMirror.simpleName)
        .replaceAllMapped(
        new RegExp('[A-Z]'), (m) => '_' + m[0].toLowerCase())
        .replaceFirst(new RegExp('^_'), '') + 's')
        .replaceFirst(new RegExp(r'ss$'), 'ses');
  }

  Future<M> find(int id) {
    return _query()._find(id).first();
  }

  Future add(M model) {
    return _query()._add(model);
  }

  Future addAll(Iterable<M> models) {
    return _query()._addAll(models);
  }

  Future<M> first() {
    return _query().first();
  }

  Stream<M> all() {
    return _query().get();
  }

  RepositoryQuery<M> where(bool predicate(M model)) {
    return _query().where(predicate);
  }

  Future<int> count() {
    return _query().count();
  }

  Future update(M model) {
    return _query().update(model);
  }

  Future delete(M model) async {
    try {
      final id = (model as dynamic).id;
      return _query()._find(id).delete();
    } on NoSuchMethodError {
      throw new ArgumentError.value(
          model, 'model', 'Model must have a getter [id] to be updated.');
    }
  }

  Relationship<M> relationship(M model) {
    return new Relationship<M>(this, _gateway, model);
  }

  Future<double> average(String field) {
    return _query().average(field);
  }

  RepositoryQuery<M> sortBy(String field, [String direction]) {
    return _query().sortBy(field, direction);
  }

  Future clear() {
    return _query().delete();
  }
}

class Relationship<M> {
  final Repository<M> _repo;
  final Gateway _gateway;
  final M owner;

  Relationship(Repository<M> this._repo, Gateway this._gateway, M this.owner);

  Repository _repository(Type of, String table) {
    return new Repository._of(of)
      .._table ??= table
      ..connect(_gateway);
  }

  String _foreignId(Object reference) {
    if (reference is Type)
      return reference.toString()
          .replaceAll(new RegExp(r'(?=[A-Z])'), '_')
          .toLowerCase()
          .replaceFirst(new RegExp('^_'), '') + '_id';
    return reference.toString().replaceFirst(new RegExp(r'e?s$'), '') + '_id';
  }

  RepositoryQuery hasMany(Type type, {String field, String table}) {
    final id = (owner as dynamic).id;
    final foreignIdField = field ?? _foreignId(_repo.table);

    return _repository(type, table)
        .where((foreign) => foreign[foreignIdField] == id);
  }

  Future belongsTo(Type type, {String field, String table}) {
    final idField = new Symbol(field ?? _foreignId(type));
    final id = reflect(owner)
        .getField(idField)
        .reflectee;

    return _repository(type, table)
        .where((foreign) => foreign.id == id)
        .first();
  }
}

class RepositoryQuery<M> {
  final Query _query;
  Iterable<Symbol> _fields;
  final ClassMirror _classMirror;
  final TypeMirror _modelTypeMirror = reflectType(Model);
  Map<Symbol, Field> __annotations;

  RepositoryQuery._copy(ClassMirror classMirror, Query query)
      : _query = query,
        _classMirror = classMirror;

  RepositoryQuery._of(Type type, Query query)
      : _query = query,
        _classMirror = reflectType(type);

  RepositoryQuery(Query query)
      : _query = query,
        _classMirror = reflectType(M);

  Map<Symbol, Field> get _annotations => __annotations ??= _getAnnotations();

  Map<Symbol, Field> _getAnnotations() {
    final annotationDecs = _getAllDeclarations(_classMirror)
        .where((d) => d.metadata
        .any(_isFieldAnnotation));
    return new Map.fromIterables(
        annotationDecs.map((d) => d.simpleName),
        annotationDecs.map((d) => d.metadata.firstWhere(_isFieldAnnotation).reflectee));
  }

  bool _isFieldAnnotation(InstanceMirror annotation) {
    return annotation.reflectee is Field;
  }

  List<DeclarationMirror> _getAllDeclarations(ClassMirror classMirror) {
    if (classMirror == null) return [];
    return []..addAll(_getAllDeclarations(classMirror.superclass))
        ..addAll(classMirror.declarations.values);
  }

  Iterable<Symbol> get fields {
    return _fields ?? (_fields = _listFields());
  }

  Iterable<Symbol> _listFields() {
    return _classMirror.instanceMembers.values
        .where(_shouldPersist)
        .map((MethodMirror m) => m.simpleName);
  }

  bool _shouldPersist(MethodMirror m) {
    final isMutableProperty = m.isGetter
        && !m.isPrivate
        && _classMirror.instanceMembers.containsKey(
            new Symbol(MirrorSystem.getName(m.simpleName) + '='));

    if (!isMutableProperty) return false;

    if (_classMirror.isAssignableTo(_modelTypeMirror))
      return _isAnnotatedAsField(m.simpleName);

    return true;
  }

  bool _isAnnotatedAsField(Symbol name) {
    return _annotations.containsKey(name);
  }

  M _modelFromMap(Map<String, dynamic> map) {
    final instance = _classMirror.newInstance(const Symbol(''), []);
    for (final field in map.keys) {
      try {
        instance.setField(_symbolizeField(field), map[field]);
      } catch (e) {}
    }
    return instance.reflectee;
  }

  Symbol _symbolizeField(String field) {
    return _annotations.keys.firstWhere(
        (s) => _annotations[s].columnName == field,
            orElse: () => new Symbol(field));
  }

  Map<String, dynamic> _mapFromModel(M model) {
    final mirror = reflect(model);
    final map = new Map.fromIterables(
        fields.map(_stringifySymbol),
        fields.map((f) => mirror
            .getField(f)
            .reflectee)
    );
    return map;
  }

  String _stringifySymbol(Symbol name) {
    if (_annotations.containsKey(name))
      return _annotations[name].columnName ?? MirrorSystem.getName(name);
    return MirrorSystem.getName(name);
  }

  Future _add(M model) {
    return _query.add(_mapFromModel(model));
  }

  Future _addAll(Iterable<M> models) {
    return _query.addAll(models.map(_mapFromModel));
  }

  Future<double> average(String field) {
    return _query.average(field);
  }

  Future<int> count() {
    return _query.count();
  }

  Future decrement(String field, [int amount = 1]) {
    return _query.decrement(field, amount);
  }

  Future delete() {
    return _query.delete();
  }

  RepositoryQuery<M> distinct() {
    return new RepositoryQuery._copy(_classMirror, _query.distinct());
  }

  RepositoryQuery<M> _find(int id) {
    return new RepositoryQuery._copy(_classMirror, _query.find(id));
  }

  Future<M> first() {
    return _query.first().then(_modelFromMap);
  }

  Stream<M> get() {
    return _query.get().map(_modelFromMap);
  }

  RepositoryQuery<M> groupBy(String field) {
    return new RepositoryQuery._copy(_classMirror, _query.groupBy(field));
  }

  Future increment(String field, [int amount = 1]) {
    return _query.increment(field, amount);
  }

  RepositoryQuery<M> limit(int count) {
    return new RepositoryQuery._copy(_classMirror, _query.limit(count));
  }

  Future<int> max(String field) {
    return _query.max(field);
  }

  Future<int> min(String field) {
    return _query.max(field);
  }

  RepositoryQuery<M> offset(int count) {
    return new RepositoryQuery._copy(_classMirror, _query.offset(count));
  }

  RepositoryQuery<M> sortBy(String field, [String direction = 'ascending']) {
    return new RepositoryQuery._copy(_classMirror, _query.sortBy(field, direction));
  }

  Future<int> sum(String field) {
    return _query.sum(field);
  }

  Future update(M model) async {
    try {
      final id = (model as dynamic).id;
      return await _query.find(id).update(_mapFromModel(model));
    } on NoSuchMethodError {
      throw new ArgumentError.value(
          model, 'model', 'Model must have a getter [id] to be updated.');
    }
  }

  RepositoryQuery<M> where(bool predicate(M row)) {
    return new RepositoryQuery._copy(_classMirror, _query.where(predicate));
  }
}