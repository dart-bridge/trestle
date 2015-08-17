part of extended_model;

class Model<M> extends Object {
  final M _model;
  InstanceMirror _mirror;
  int _id;

  int get id => _id;

  Model(int this._id, M this._model) {
    _mirror = reflect(_model);
  }

  noSuchMethod(Invocation invocation) => _mirror.delegate(invocation);

  @override
  String toString() {
    return _model.toString();
  }

  @override
  bool operator ==(other) => identical(_model, other) || identical(this, other);
}
