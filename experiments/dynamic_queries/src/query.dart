part of dynamic_queries;

abstract class Query {
  final String _table;
  final Queue<Directive> _directives = new Queue<Directive>();

  Query(String this._table);

  List<Directive> get directives => _directives.toList();

  String get table => _table;

  Query where(Function expression) {
    _directives.add(new WhereDirective(expression));
    return this;
  }

  Query limit(int count) {
    _directives.add(new LimitDirective(count));
    return this;
  }

  Query distinct() {
    _directives.add(const DistinctDirective());
    return this;
  }
}
