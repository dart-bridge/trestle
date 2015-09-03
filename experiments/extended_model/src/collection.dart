part of extended_model;

class Collection<M> {
  final List<Model<M>> _collection = [];

  M find(int id) {
    dynamic model =  _collection.firstWhere((m) => m.id == id);
    return model;
  }

  void save(M model) {
    if (model is Model<M>) _update((model as Model<M>));
    if (model is M) _insert(model);
  }

  void _update(Model<M> model) {
    _collection.removeWhere((m) => m.id == model.id);
    _collection.add(model);
  }

  void _insert(M model) {
    _collection.add(new Model<M>(_collection.length + 1, model));
  }

  Iterable<M> all() => (_collection as Iterable<M>);

  void delete(Model<M> model) {
    if (model is! Model) return;
    _collection.remove(model);
  }
}
