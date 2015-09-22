part of trestle.drivers;

class SqliteDriver extends SqlDriver with SqlStandards {
  final sqlite.Sqlite3Connection _connection;
  final String _file;

  SqliteDriver(String file) :
        _file = file,
        _connection = new sqlite.Sqlite3Connection(file);

  Future connect() {
    return _connection.open();
  }

  Future disconnect() {
    return _connection.close();
  }

  Stream<Map<String, dynamic>> execute(String query, List variables) async* {
    final statement = new sqlite.Sqlite3Statement(_connection, query);
    final stream = await statement.executeQuery(variables);
    yield* stream.map(_transformRows).map(deserialize);
  }

  Map<String, dynamic> _transformRows(sqlite.SqlDataRow row) {
    return new Map.fromIterables(row.names, row.names.map((n) => row[n]));
  }

  String toString() => 'SqliteDriver(sqlite:'
      '${_file == ':memory:' ? 'memory' : '/' + new File(_file).absolute.path})';
}