part of trestle.drivers;

class SqliteDriver extends SqlDriver with SqlStandards {
  sqlite.Database _db;
  final String _file;

  SqliteDriver(this._file);

  SqliteDriver.inMemory() : _file = ':memory:';

  String insertedIdQuery(String table) => 'SELECT last_insert_rowid() AS "id";';

  String get autoIncrementKeyword => 'AUTOINCREMENT';

  Stream<Map<String, dynamic>> execute(String query, List variables) {
    return _db.query(query, params: variables).map(_transform);
  }

  Map<String, dynamic> _transform(sqlite.Row row) {
    return row.toMap();
  }

  Future connect() async {
    _db ??= new sqlite.Database(_file);
  }

  Future disconnect() async {
    _db.close();
  }
}
