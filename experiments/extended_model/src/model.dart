part of extended_model;

class Model<M> extends Object {
  final M _model;
  InstanceMirror _mirror;
  int _id;

  int get id => _id;

  Model(int this._id, M this._model) {
    _mirror = reflect(_model);
  }

  Iterable<String> $fields() sync* {
    yield 'id';
    for (var member in _mirror.type.instanceMembers.values)
      if (member.isGetter
      && member.owner != reflectClass(Object)
      && _mirror.type.instanceMembers.keys.contains(new Symbol('${MirrorSystem.getName(member.simpleName)}=')))
        yield MirrorSystem.getName(member.simpleName);
  }

  noSuchMethod(Invocation invocation) => _mirror.delegate(invocation);

  @override
  String toString() {
    return _model.toString();
  }

  @override
  bool operator ==(other) => identical(_model, other) || identical(this, other);
}
