part of dynamic_queries;

class QueryBuilder {
  SelectQuery select({String from, Iterable<String> fields}) {
    return new SelectQuery(from, fields);
  }
}
