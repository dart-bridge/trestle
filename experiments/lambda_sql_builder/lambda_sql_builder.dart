import 'dart:mirrors';

class Person {
  String name;
  int age;
}

class House {
  String color;
  int numberOfBedrooms;
}

class From<T> {

  From(bool fun(T t)) {
    _where += T.toString() + ' ' + _convertToSQL(_funSource(fun));

    print(_where);
  }

  String _select = 'SELECT ';
  String _where = 'FROM ';
  String _orderBy = 'ORDER BY ';
  String _groupBy = 'GROUP BY ';
  String _tblAlias;

  String get query => '$_select $_where $_orderBy';

  String _funSource(Function fun) => (reflect(fun) as ClosureMirror).function.source;

  String _extractExpression(Function fun) => _funSource(fun).replaceAll(new RegExp(r'\(\w+\)\s+=> '), '');

  String _convertToSQL(String expression) =>
  expression
    .replaceAllMapped(new RegExp(r'\((\w+)\)'), (m) {
      _tblAlias = m[1];
      return '${m[1]}';
    }).replaceAll('=>', 'WHERE')
    .replaceAll('&&', 'AND')
    .replaceAll('||', 'OR')
    .replaceAll('==', '=');

  or(bool fun(T t)) {
    _where += ' OR (' + _extractExpression(fun) + ') ';
    return this;
  }

  and(bool fun(T t)) {
    _where += ' AND (' + _extractExpression(fun) + ') ';
    return this;
  }

  orderBy(fun(T t)) {
    _orderBy += _extractExpression(fun);
    return this;
  }

  orderByDescending(fun(T t)) {
    orderBy(fun);
    _orderBy += ' DESC ';
    return this;
  }

  orderByAscending(fun(T t)) {
    orderBy(fun);
    _orderBy += ' ASC ';
    return this;
  }

  groupBy(fun(T t)) {
    _groupBy += _extractExpression(fun);
    return this;
  }

  Iterable<T> selectAll(fun(T t)) {

    return null;
  }

  T selectOne([void fun(T t)]) {
    if(fun == null) {
      var vms = new Map<Symbol, VariableMirror>();
      reflectClass(T).declarations.forEach((symName, dm) {
        if(dm is VariableMirror) {
          vms[symName] = dm;
        }
      });

      _select += vms.keys.map((symName) => '$_tblAlias.' + MirrorSystem.getName(symName)).join(', ');

      print(query);
    } else {
      print(fun);
    }

    return null;
  }
}

void main() {
  Person p1 = new Person()..name = 'my name';

  var p = new From<Person>((p) => p.name == 'luis' && p.age > 21)
  .orderByAscending((p) => p.age).selectOne();

  print(p == null ? null : p.age);

}
