part of dynamic_queries;

class SqlStandards {
  String wrapSystemIdentifier(String systemIdentifier) {
    if (systemIdentifier == '*') return systemIdentifier;
    return '"$systemIdentifier"';
  }
}
