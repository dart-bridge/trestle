part of trestle.orm;

class RepositoryQuery<M> {
  final Query _query;
  final MapsFieldsToModel<M> _entity;

  RepositoryQuery(this._query, this._entity);

  Future<M> first() => _query.first().then(_entity.deserialize);

  Stream<M> get() => _query.get().map(_entity.deserialize);

  Future delete() => _query.delete();

  Future decrement(String field, [int amount = 1]) =>
      _query.decrement(field, amount);

  Future increment(String field, [int amount = 1]) =>
      _query.increment(field, amount);

  Future<int> count() => _query.count();

  Future<double> average(String field) => _query.average(field);

  Future<int> sum(String field) => _query.sum(field);

  Future<int> max(String field) => _query.max(field);

  Future<int> min(String field) => _query.min(field);

  RepositoryQuery limit(int count) =>
      new RepositoryQuery(_query.limit(count), _entity);

  RepositoryQuery offset(int count) =>
      new RepositoryQuery(_query.offset(count), _entity);

  RepositoryQuery sortBy(String field, [String direction = 'asc']) =>
      new RepositoryQuery(_query.sortBy(field, direction), _entity);

  RepositoryQuery where(bool predicate(row)) =>
      new RepositoryQuery(_query.where(predicate), _entity);
}
