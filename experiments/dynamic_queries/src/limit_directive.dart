part of dynamic_queries;

class LimitDirective implements Directive {
  final int _count;

  LimitDirective(int this._count);

  String toString() => 'take $_count';
}
