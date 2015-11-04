part of trestle.orm;

class Repository<M> {
  final Gateway _gateway;
  final MapsFieldsToObject<M> _mapper;

  Repository(Gateway gateway)
      : _gateway = gateway,
        _mapper = _makeEntity(gateway, M);

  Repository.of(this._mapper, this._gateway);

  get table => _mapper.table;

  static MapsFieldsToObject _makeEntity(Gateway gateway, Type type) {
    final mirror = reflectType(type);
    if (mirror.isAssignableTo(reflectType(Model)))
      return new MapsFieldsToModel(gateway, mirror);
    final MethodMirror constructor =
        (mirror as ClassMirror).declarations[const Symbol('')] ??
        (mirror as ClassMirror).declarations[mirror.simpleName];
    if (constructor.parameters.isNotEmpty)
      return new MapsFieldsToValueObject(mirror);
    return new MapsFieldsToDataStructure(mirror);
  }

  Query get _query => _gateway.table(_mapper.table);

  RepositoryQuery<M> get _repoQuery => new RepositoryQuery<M>(_query, _mapper);

  Future save(M model) async {
    if (_mapper.isSaved(model))
      return _mapper.find(_query, model).update(_mapper.serialize(model));
    final id = await _query.add(_mapper.serialize(model));
    if (model is Model) {
      (model as Model).id = id;
    }
    MapsFieldsToObjectBase._deserialized.add(model);
  }

  Future saveAll(Iterable<M> models) => Future.wait(models.map(save));

  Future delete(M model) async {
    if (_mapper.isSaved(model))
      return _mapper.find(_query, model).delete();
  }

  Future clear() => _query.delete();

  Future<M> find(int id) => _query.find(id).first().then(_mapper.deserialize);

  Future<M> first() => _query.first().then(_mapper.deserialize);

  Stream<M> all() => _query.get().asyncMap(_mapper.deserialize);

  Future decrement(String field, [int amount = 1]) =>
      _query.decrement(field, amount);

  Future increment(String field, [int amount = 1]) =>
      _query.increment(field, amount);

  Future<int> count() => _query.count();

  Future<double> average(String field) => _query.average(field);

  Future<int> sum(String field) => _query.sum(field);

  Future<int> max(String field) => _query.max(field);

  Future<int> min(String field) => _query.min(field);

  RepositoryQuery<M> limit(int count) => _repoQuery.limit(count);

  RepositoryQuery<M> offset(int count) => _repoQuery.offset(count);

  RepositoryQuery<M> sortBy(String field, [String direction = 'asc']) =>
      _repoQuery.sortBy(field, direction);

  RepositoryQuery<M> where(bool predicate(M model)) =>
      _repoQuery.where(predicate);
}
