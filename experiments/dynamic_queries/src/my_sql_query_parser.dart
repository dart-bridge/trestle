part of dynamic_queries;

class MySqlQueryParser extends SqlQueryParser {
  String wrapSystemIdentifier(String systemIdentifier) {
    if (systemIdentifier == '*') return systemIdentifier;
    return '`$systemIdentifier`';
  }
}
