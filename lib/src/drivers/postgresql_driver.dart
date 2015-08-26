part of trestle.drivers;

class PostgresqlDriver extends SqlDriver with SqlStandards {
  postgresql.Connection _connection;
  final String _uri;

  PostgresqlDriver({String username: 'root',
                   String password:'password',
                   String host: 'localhost',
                   int port: 5432,
                   String database: 'database',
                   bool ssl: false}) :
  _uri = 'postgres://$username:$password@$host:$port/$database${ssl ? '?sslmode=require' : ''}';

  Future connect() async {
    _connection = await postgresql.connect(_uri);
  }

  Future disconnect() async {
    _connection.close();
  }

  Stream<Map<String, dynamic>> execute(String query, List variables) {
    return _connection.query(query, variables).map(_rowToMap);
  }

  Map<String, dynamic> _rowToMap(postgresql.Row row) {
    return row.toMap();
  }
}