part of trestle.drivers;

class MySqlDriver extends SqlDriver {
  final sqljocky.ConnectionPool _connection;

  MySqlDriver({String host: 'localhost',
  int port: 3306,
  String user,
  String password,
  String db,
  int max: 5,
  int maxPacketSize: 16 * 1024 * 1024,
  bool useSSL: false})
      : _connection = new sqljocky.ConnectionPool(
      host: host,
      port: port,
      user: user,
      password: password,
      db: db,
      max: max,
      maxPacketSize: maxPacketSize,
      useSSL: useSSL);

  Future connect() async {
  }

  Future disconnect() async {
    _connection.closeConnectionsNow();
  }

  Stream<Map<String, dynamic>> execute(String query, List variables) async* {
    sqljocky.Results results = await (await _connection.prepare(query)).execute(
        variables);
    Iterable<String> fieldNames = results.fields.map((f) => f.name);
    yield* results.map((row) => new Map.fromIterables(fieldNames, row));
  }

  String wrapSystemIdentifier(String systemId) {
    return '`$systemId`';
  }
}