part of trestle.drivers;

class PostgresqlDriver extends SqlDriver with SqlStandards {
  postgresql.Connection _connection;
  final String _uri;

  PostgresqlDriver({String host: 'localhost',
                   String username: 'root',
                   String password: 'password',
                   int port: 5432,
                   String database: 'database',
                   bool ssl: false})
      : _uri = 'postgres://$username:$password@$host:$port/$database${ssl
      ? '?sslmode=require'
      : ''}';

  Future connect() async {
    _connection = await postgresql.connect(_uri);
  }

  Future disconnect() async {
    _connection.close();
  }

  Stream<Map<String, dynamic>> execute(String query, List variables) {
    return _connection
        .query(_questionMarksToSequence(query), variables.asMap())
        .map(_rowToMap);
  }

  String _questionMarksToSequence(String query) {
    var i = 0;
    return query.replaceAllMapped('?', (_) => '@${i++}');
  }

  Map<String, dynamic> _rowToMap(postgresql.Row row) {
    return row.toMap();
  }

  String toString() => 'PostgresqlDriver($_uri)';
}