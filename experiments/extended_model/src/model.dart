part of extended_model;

@proxy
class Model<M> extends Object {
  final M _model;
  final InstanceMirror _mirror;
  int id;

  Model(int this.id, M model)
      :
        _model = model,
        _mirror = reflect(model);

  Iterable<String> $fields() sync* {
    yield 'id';
    for (var member in _mirror.type.instanceMembers.values)
      if (member.isGetter
          && member.owner != reflectClass(Object)
          && _mirror.type.instanceMembers.keys.contains(
              new Symbol('${MirrorSystem.getName(member.simpleName)}=')))
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
