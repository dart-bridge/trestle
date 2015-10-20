part of trestle.orm;

class Repository<M> {
  Gateway __gateway;
  final Entity<M> _entity;

  Repository() : _entity = _makeEntity(M);

  Repository.of(this._entity);

  get table => _entity.table;

  static Entity _makeEntity(Type type) {
    final mirror = reflectType(type);
    if (mirror.isAssignableTo(reflectType(Model)))
      return new ModelEntity(mirror);
    return new DataStructureEntity(mirror);
  }

  void connect(Gateway gateway) {
    __gateway = gateway;
  }

  Gateway get _gateway {
    if (__gateway == null)
      throw new StateError(
          'Repository is not connected. '
              'Connect a gateway before executing queries!');
    return __gateway;
  }

  Query get _query => _gateway.table(_entity.table);

  RepositoryQuery<M> get _repoQuery => new RepositoryQuery<M>(_query, _entity);

  Future save(M model) {
    if (_entity.isSaved(model))
      return _entity.find(_query, model).update(_entity.serialize(model));
    return _query.add(_entity.serialize(model));
  }

  Future saveAll(Iterable<M> models) => Future.wait(models.map(save));

  Future delete(M model) async {
    if (_entity.isSaved(model))
      return _entity.find(_query, model).delete();
  }

  Future clear() => _query.delete();

  Future<M> first() => _query.first().then(_entity.deserialize);

  Stream<M> all() => _query.get().map(_entity.deserialize);

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
