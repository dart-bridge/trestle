part of trestle.drivers;

class MySqlDriver extends SqlDriver {
  final sqljocky.ConnectionPool _connection;
  final _username;
  final _password;
  final _host;
  final _port;
  final _database;

  MySqlDriver({String host: 'localhost',
  String username: 'root',
  String password: null,
  int port: 3306,
  String database,
  bool ssl: false,
  int max: 5,
  int maxPacketSize: 16 * 1024 * 1024})
      : _username = username,
        _password = password,
        _host = host,
        _port = port,
        _database = database,
        _connection = new sqljocky.ConnectionPool(
            host: host,
            port: port,
            user: username,
            password: password,
            db: database,
            max: max,
            maxPacketSize: maxPacketSize,
            useSSL: ssl);

  Future connect() async {
    await _connection.getConnection();
  }

  Future disconnect() async {
    _connection.closeConnectionsNow();
  }

  Stream<Map<String, dynamic>> execute(String query, List variables) async* {
    final sqljocky.Query preparedQuery = await _connection.prepare(query);
    final sqljocky.Results results = await preparedQuery.execute(variables);
    Iterable<String> fieldNames = results.fields.map((f) => f.name);
    yield* results.map((row) => new Map.fromIterables(fieldNames, row)).map(deserialize);
  }

  String wrapSystemIdentifier(String systemId) {
    return '`$systemId`';
  }

  String toString() =>
      'MySqlDriver(mysql://$_username${_password == null
          ? ''
          : ':$_password'}@$_host:$_port/$_database)';
}