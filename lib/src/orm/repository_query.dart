part of trestle.orm;

class RepositoryQuery<M> {
  final Query _query;
  final MapsFieldsToObject<M> _mapper;
  final Map<Symbol, Object> _assignments;

  RepositoryQuery(this._query, this._mapper, [this._assignments = const {}]);

  Future<M> first() => get().first;

  Stream<M> get() => _query.get()
      .map(_mapper.deserialize)
      .map(_applyAssignments);

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

  RepositoryQuery<M> limit(int count) =>
      new RepositoryQuery(_query.limit(count), _mapper);

  RepositoryQuery<M> offset(int count) =>
      new RepositoryQuery(_query.offset(count), _mapper);

  RepositoryQuery<M> sortBy(String field, [String direction = 'asc']) =>
      new RepositoryQuery(_query.sortBy(field, direction), _mapper);

  RepositoryQuery<M> where(bool predicate(row)) =>
      new RepositoryQuery(_query.where(predicate), _mapper);

  RepositoryQuery<M> _assign(Symbol name, Object value) =>
      new RepositoryQuery(_query, _mapper,
          new Map.unmodifiable(new Map.from(_assignments)
            ..addAll({name: value})));

  M _applyAssignments(M model) {
    final mirror = reflect(model);
    _assignments.forEach(mirror.setField);
    return model;
  }
}
