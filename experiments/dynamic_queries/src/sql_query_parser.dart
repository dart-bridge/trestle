part of dynamic_queries;

abstract class SqlQueryParser implements QueryParser {
  String parse(Query query) {
    String queryPrefix;

    if (query is SelectQuery) queryPrefix =
    'SELECT ${query.fields.map(wrapSystemIdentifier).join(', ')} FROM ${wrapSystemIdentifier(query.table)}';
//    else if (/*UPDATE*/ true) queryType =
//    'UPDATE ${query.table}';
    else throw 'INVALID QUERY';

    return '$queryPrefix\n${_directives(query).join('\n')}';
  }

  Iterable<String> _directives(Query query) sync* {
    for (var directive in query.directives)
      yield _parseDirective(directive);
  }

  String _parseDirective(Directive directive) {
    if (directive is WhereDirective) return _parseWhere(directive);
    if (directive is LimitDirective) return _parseLimit(directive);
    if (directive is DistinctDirective) return _parseDistinct(directive);
    throw 'INVALID DIRECTIVE';
  }

  String _parseWhere(WhereDirective directive) {
    var expression = directive.toString();
    expression = expression.replaceFirstMapped(new RegExp(r'\((.*?)\)(.*)'), ($) {
      return $[2]
      .replaceFirst('=>', '')
      .trim()
      .replaceAllMapped(new RegExp('${$[1]}'r'\.(\w+)'), (m) {
        return wrapSystemIdentifier(m[1].replaceAllMapped(new RegExp('[A-Z]'), (c) => '_${c[0].toLowerCase()}'));
      })
      .replaceAll('&&', 'AND')
      .replaceAll('==', '=')
      .replaceAll('||', 'OR');
    });
    return 'WHERE $expression';
  }

  String _parseLimit(LimitDirective directive) {
    return 'LIMIT ${directive._count}';
  }

  String _parseDistinct(DistinctDirective directive) {
    return 'DISTINCT';
  }

  String wrapSystemIdentifier(String systemIdentifier);
}
