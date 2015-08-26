part of trestle.drivers;

abstract class SqlDriver implements Driver {
  Stream<Map<String, dynamic>> execute(String statement, List variables);

  String wrapSystemIdentifier(String systemId);

  Future<int> count(Query query) {
    return null;
  }

  Future<double> average(Query query, String field) {
    return null;
  }

  Future<int> max(Query query, String field) {
    return null;
  }

  Future<int> min(Query query, String field) {
    return null;
  }

  Future<int> sum(Query query, String field) {
    return null;
  }

  Future add(Query query, Map<String, dynamic> row) {
    return null;
  }

  Future addAll(Query query, Iterable<Map<String, dynamic>> rows) {
    return null;
  }

  Future delete(Query query) {
    return null;
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
    return null;
  }

  Future increment(Query query, String field, int amount) {
    return null;
  }

  Future decrement(Query query, String field, int amount) {
    return null;
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
    return '';
  }

  String _joinConstraint() {
    return 'JOIN "${(_constraint as JoinConstraint).foreign.table}" '
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