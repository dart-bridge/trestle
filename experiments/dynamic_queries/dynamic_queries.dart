/// This experiment explores the possibility to use Dart expression
/// for query clauses in the public API, by dynamically evaluate the
/// source string of lambda functions.
///
/// @author Emil Persson <emil.n.persson@gmail.com>
library dynamic_queries;

import 'package:test/test.dart';
import 'dart:collection';
import 'dart:mirrors';

part 'src/query_builder.dart';
part 'src/query.dart';
part 'src/select_query.dart';
part 'src/directive.dart';
part 'src/where_directive.dart';
part 'src/limit_directive.dart';
part 'src/distinct_directive.dart';
part 'src/query_parser.dart';
part 'src/sql_query_parser.dart';
part 'src/my_sql_query_parser.dart';
part 'src/postgre_sql_query_parser.dart';
part 'src/sqlite_query_parser.dart';
part 'src/sql_standards.dart';

QueryBuilder builder = new QueryBuilder();

main() {
  test('example query', () {
    var selection = builder

    .select(from: 'users')
    .where((user) => user.firstName == 'Emil' && (user.age > 20 || user.isAdmin))
    .distinct()
    .limit(3);

    var parser = new PostgreSqlQueryParser();

    print(parser.parse(builder
    .select(from: 'users', fields: ['first_name', 'age'])
    .where((user) => user.firstName == 'Emil' && (user.age > 20 || user.isAdmin))
    .limit(50)));

    expect(parser.parse(selection),
    equals(
        'SELECT * FROM "users"\n'
        'WHERE "first_name" = \'Emil\' AND ("age" > 20 OR "is_admin")\n'
        'DISTINCT\n'
        'LIMIT 3'
    ));
  });
}