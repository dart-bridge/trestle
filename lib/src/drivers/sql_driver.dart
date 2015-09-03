part of trestle.drivers;

abstract class SqlDriver implements Driver {
  Stream<Map<String, dynamic>> execute(String statement, List variables);

  String wrapSystemIdentifier(String systemId);

  Future _aggregate(String aggregate,
                    String fieldSelector,
                    String alias,
                    Query query) {
    final List<String> queryParts = [];
    final List variables = [];

    queryParts.add('SELECT $aggregate($fieldSelector) AS $alias FROM ${wrapSystemIdentifier(query.table)}');
    queryParts.addAll(_parseQuery(query, variables));

    return execute('${queryParts.join(' ')};', variables).first.then((r) => r[alias]);
  }

  Future<int> count(Query query) {
    return _aggregate('COUNT', '*', 'count', query);
  }

  Future<double> average(Query query, String field) {
    return _aggregate('AVG', wrapSystemIdentifier(field), 'average', query);
  }

  Future<int> max(Query query, String field) {
    return _aggregate('MAX', wrapSystemIdentifier(field), 'max', query);
  }

  Future<int> min(Query query, String field) {
    return _aggregate('MIN', wrapSystemIdentifier(field), 'min', query);
  }

  Future<int> sum(Query query, String field) {
    return _aggregate('SUM', wrapSystemIdentifier(field), 'sum', query);
  }

  String _addQuery(List variables, Query query, Map<String, dynamic> row) {
    final header = 'INSERT INTO ${wrapSystemIdentifier(query.table)}';
    final fields = row.keys.map(wrapSystemIdentifier);
    final values = ('?' * row.length).split('');
    variables.addAll(row.values);
    return '$header (${fields.join(', ')}) VALUES (${values.join(', ')});';
  }

  Future add(Query query, Map<String, dynamic> row) {
    final variables = [];
    final singleQuery = _addQuery(variables, query, row);
    return execute(singleQuery, variables).toList();
  }

  Future addAll(Query query, Iterable<Map<String, dynamic>> rows) {
    final variables = [];
    final multiQuery = rows.map((r) => _addQuery(variables, query, r)).join(' ');
    return execute(multiQuery, variables).toList();
  }

  Future delete(Query query) {
    final List<String> queryParts = [];
    final List variables = [];

    queryParts.add('DELETE FROM ${wrapSystemIdentifier(query.table)}');

    queryParts.addAll(_parseQuery(query, variables));

    return execute('${queryParts.join(' ')};', variables).toList();
  }

  Stream<Map<String, dynamic>> get(Query query, Iterable<String> fields) {
    final List<String> queryParts = [];
    final List variables = [];

    queryParts.add('SELECT');

    queryParts.add(fields.isEmpty ? '*' : '${fields.map(wrapSystemIdentifier).join(', ')}');

    queryParts.add('FROM ${wrapSystemIdentifier(query.table)}');

    queryParts.addAll(_parseQuery(query, variables));

    return execute('${queryParts.join(' ')};', variables);
  }

  Iterable<String> _parseQuery(Query query, List variables) {
    return query.constraints.map((c) => _parseConstraint(query, c, variables));
  }

  String _parseConstraint(Query query, Constraint constraint, List variables) {
    return new _ConstraintParser(this, query, constraint, variables)();
  }

  Future update(Query query, Map<String, dynamic> fields) {
    final List<String> queryParts = [];
    final List variables = [];

    queryParts.add('UPDATE ${wrapSystemIdentifier(query.table)} SET');

    queryParts.add(fields.keys
        .map((f) => '${wrapSystemIdentifier(f)} = ?')
        .join(', '));

    variables.addAll(fields.values);

    queryParts.addAll(_parseQuery(query, variables));

    return execute('${queryParts.join(' ')};', variables).toList();
  }

  Future increment(Query query, String field, int amount) {
    return _inOrDecrement(query, field, amount, '+');
  }

  Future decrement(Query query, String field, int amount) {
    return _inOrDecrement(query, field, amount, '-');
  }

  Future _inOrDecrement(Query query, String field, int amount, String operator) {
    final List<String> queryParts = [];
    final List variables = [];

    queryParts.add('UPDATE ${wrapSystemIdentifier(query.table)} SET');

    queryParts.add(
        '${wrapSystemIdentifier(field)} '
        '= ${wrapSystemIdentifier(field)} $operator $amount');

    queryParts.addAll(_parseQuery(query, variables));

    return execute('${queryParts.join(' ')};', variables).toList();
  }
}

class _ConstraintParser {
  final Constraint _constraint;
  final Query _query;
  final SqlDriver _driver;
  final List _variables;

  _ConstraintParser(SqlDriver this._driver,
                    Query this._query,
                    Constraint this._constraint,
                    List this._variables);

  String call() {
    if (_constraint is WhereConstraint) return _whereConstraint();
    if (_constraint is LimitConstraint) return _limitConstraint();
    if (_constraint is OffsetConstraint) return _offsetConstraint();
    if (_constraint is DistinctConstraint) return _distinctConstraint();
    if (_constraint is JoinConstraint) return _joinConstraint();
    if (_constraint is GroupByConstraint) return _groupByConstraint();
    if (_constraint is SortByConstraint) return _sortByConstraint();
    return '';
  }

  String _sortByConstraint() {
    return 'SORT BY ${_driver.wrapSystemIdentifier((_constraint as SortByConstraint).field)} '
    '${(_constraint as SortByConstraint).direction == SortByConstraint.descending ? 'DESC' : 'ASC'}';
  }

  String _groupByConstraint() {
    return 'GROUP BY ${_driver.wrapSystemIdentifier((_constraint as GroupByConstraint).field)}';
  }

  String _joinConstraint() {
    return 'JOIN ${_driver.wrapSystemIdentifier((_constraint as JoinConstraint).foreign.table)} '
    'ON ${_parseJoinPredicate((_constraint as JoinConstraint).predicate)}';
  }

  String _parsePredicate(Function predicate, Iterable params, [String treat(String exp)]) {
    final predicateExpression = PredicateParser.parse(predicate);
    final expression = predicateExpression.expression(params);
    _variables.addAll(predicateExpression.variables);

    return (treat == null ? (s) => s : treat)(expression
    .replaceAllMapped(new RegExp(r'"(.*?)"'), ($) => "'${$[1]}'")
    .replaceAll('==', '=')
    .replaceAll('&&', 'AND')
    .replaceAll('||', 'OR'));
  }

  String _parseJoinPredicate(JoinPredicate predicate) {
    return _parsePredicate(predicate, [_query.table, (_constraint as JoinConstraint).foreign.table]);
  }

  String _distinctConstraint() {
    return 'DISTINCT';
  }

  String _limitConstraint() {
    return 'LIMIT ${(_constraint as LimitConstraint).count}';
  }

  String _offsetConstraint() {
    return 'OFFSET ${(_constraint as OffsetConstraint).count}';
  }

  String _whereConstraint() {
    return 'WHERE ${_parseWherePredicate((_constraint as WhereConstraint).predicate)}';
  }

  String _parseWherePredicate(WherePredicate predicate) {
    return _parsePredicate(predicate, [_query.table], (String s) => s
    .replaceAllMapped(new RegExp('${_query.table}'r'\.(\w+)'), ($) {
      return _driver.wrapSystemIdentifier($[1]);
    }));
  }
}