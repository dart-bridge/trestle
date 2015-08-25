part of trestle.drivers;

class SqliteDriver extends SqlDriver with SqlStandards {
  Future connect() {
    return null;
  }

  Future disconnect() {
    return null;
  }

  Stream execute(String query, List variables) {
    return null;
  }
}