part of trestle.orm;

abstract class MapsFieldsToObject<O> {
  String get table;

  Future<O> deserialize(
      Map<String, dynamic> fields,
      [Map<Symbol, List> assignments = const {}]);

  Map<String, dynamic> serialize(O object);

  bool isSaved(O object);

  Query find(Query query, O object);

  static String _camelToSnakeCase(String camelCase) {
    return camelCase
        .replaceAllMapped(new RegExp(r'[A-Z]'), (m) => '_${m[0].toLowerCase()}')
        .replaceFirst(new RegExp(r'^_'), '');
  }

  static String _pluralize(String singular) {
    return singular.endsWith('y')
        ? singular.replaceFirst(new RegExp(r'y$'), 'ies')
        : singular.endsWith('s')
        ? '${singular}es'
        : '${singular}s';
  }
}

abstract class MapsFieldsToObjectBase<M> implements MapsFieldsToObject<M> {
  String _table;

  String get table => _table;
  final ClassMirror _type;
  static final List _deserialized = [];

  MapsFieldsToObjectBase(TypeMirror type) : _type = type {
    _table = _getTableName(type);
  }

  String _overrideTableName(String table) => table;

  String _getTableName(TypeMirror type) {
    return _overrideTableName(
        MapsFieldsToObject._pluralize(
            MapsFieldsToObject._camelToSnakeCase(
        MirrorSystem.getName(type.simpleName))));
  }

  Future<M> deserialize(
      Map<String, dynamic> fields,
      [Map<Symbol, List> assignments = const {}]) async {
    final instance = _type.newInstance(const Symbol(''), []);
    final model = instance.reflectee;
    for (final field in fields.keys)
      if (_fields.containsKey(field))
        instance.setField(_fields[field], fields[field]);
    _deserialized.add(model);
    return model;
  }

  Map<String, Symbol> __fields;

  Map<String, Symbol> get _fields => __fields ??= _findFields();

  Map<String, Symbol> _findFields();

  Map<String, dynamic> serialize(M model) {
    final map = <String, dynamic>{};
    for (final field in _fields.keys)
      map[field] = reflect(model)
          .getField(_fields[field])
          .reflectee;
    return map;
  }

  bool isSaved(M model) => _deserialized.contains(model);
}
