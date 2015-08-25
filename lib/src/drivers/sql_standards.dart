part of trestle.drivers;

abstract class SqlStandards {
  String wrapSystemIdentifier(String systemId) {
    return '"$systemId"';
  }
}