part of dynamic_queries;

class WhereDirective implements Directive {
  final Function _expression;

  WhereDirective(Function this._expression);

  String toString() {
    final ClosureMirror mirror = reflect(_expression);
    return mirror.function.source;
  }
}
