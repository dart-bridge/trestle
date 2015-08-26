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
    sqljocky.Results results = await (await _connection.prepare(query)).execute(variables);
    Iterable<String> fieldNames = results.fields.map((f) => f.name);
    yield* results.map((row) => new Map.fromIterables(fieldNames, row));
  }

  String wrapSystemIdentifier(String systemId) {
    return '`$systemId`';
  }
}