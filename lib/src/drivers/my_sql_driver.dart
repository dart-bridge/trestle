part of trestle.drivers;

class MySqlDriver extends SqlDriver {
  final sqljocky.ConnectionPool _connection;

  MySqlDriver(sqljocky.ConnectionPool this._connection);

  Future connect() async {
  }

  Future disconnect() async {
    _connection.closeConnectionsNow();
  }

  Stream<Map<String, dynamic>> execute(String query, List variables) async* {
    sqljocky.Results results = await _connection.query(query);

    yield* results.map(_rowToMap);
  }

  Map<String, dynamic> _rowToMap(sqljocky.Row row) {
    return new _JockyRowMap(row);
  }

  String wrapSystemIdentifier(String systemId) {
    return '`$systemId`';
  }
}

class _JockyRowMap extends UnmodifiableMapBase<String, dynamic> implements Map<String, dynamic> {
  final InstanceMirror _mirror;
  final sqljocky.Row _row;

  _JockyRowMap(sqljocky.Row row) :
  _row = row,
  _mirror = reflect(row);

  operator [](String key) {
    return _mirror.getField(new Symbol(key)).reflectee;
  }

  Iterable<String> get keys => new Map.fromIterable(_row).keys;
}