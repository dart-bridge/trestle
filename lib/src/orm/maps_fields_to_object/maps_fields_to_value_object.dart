part of trestle.orm;

class MapsFieldsToValueObject<O> extends MapsFieldsToObjectBase<O> {
  MapsFieldsToValueObject(TypeMirror type) : super(type);

  Map<String, Symbol> _findFields() {
    final MethodMirror constructor = _type.declarations[const Symbol('')] ??
        _type.declarations[_type.simpleName];
    final symbols = constructor.parameters.map((p) => p.simpleName);
    final fields = symbols
        .map(MirrorSystem.getName)
        .map(MapsFieldsToObject._camelToSnakeCase);
    return new Map<String, Symbol>.fromIterables(fields, symbols);
  }

  find(Query query, O model) {
    throw new UnsupportedError(
        '[$model] is not a Model. Only models can be updated.');
  }
}
