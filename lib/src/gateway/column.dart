part of trestle.gateway;

enum ColumnType {
  character,
  varchar,
  binary,
  boolean,
  varbinary,
  integer,
  smallint,
  bigint,
  decimal,
  numeric,
  float,
  real,
  double,
  date,
  time,
  timestamp,
  interval,
  array,
  multiset,
  xml,
}

class Column {
  final String name;
  final ColumnType type;
  final int length;

  Column(String this.name, ColumnType this.type, int this.length);

  Column nullable(bool canBeNull) {
    throw new UnsupportedError('To be implemented');
  }

  ForeignKey references(String foreignTable, {String column: 'id'}) {
    throw new UnsupportedError('To be implemented');
  }

  Column incrementingPrimaryKey() {
    throw new UnsupportedError('To be implemented');
  }
}
