part of dynamic_queries;

class SelectQuery extends Query {
  final Iterable<String> fields;

  SelectQuery(String table, [Iterable<String> fields])
  : this.fields = (fields != null) ? fields : ['*'],
  super(table);
}
