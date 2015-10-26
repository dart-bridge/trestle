part of trestle.orm;

class MapsFieldsToDataStructure<M> extends MapsFieldsToObjectBase<M> {
  MapsFieldsToDataStructure(TypeMirror type) : super(type);

  Map<String, Symbol> _getFields() {
    final members = _type.instanceMembers.keys;
    final symbols = members.where((s) {
      final name = MirrorSystem.getName(s);
      return members.contains(new Symbol('$name='));
    });
    final fields = symbols.map(MirrorSystem.getName)
        .map(MapsFieldsToObject._camelToSnakeCase);
    return new Map<String, Symbol>.fromIterables(fields, symbols);
  }

  find(Query query, M model) {
    throw new UnsupportedError(
        '[$model] is not a Model. Only models can be updated.');
  }
}
