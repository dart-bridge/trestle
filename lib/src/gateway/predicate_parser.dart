part of trestle.gateway;

class PredicateExpression {
  final List<String> _arguments;
  final String _expression;
  final List _variables;

  int get argumentsCount => _arguments.length;

  const PredicateExpression(List this._variables, List<String> this._arguments, String this._expression);

  Iterable get variables => _variables;

  String expression(List<String> arguments) {
    var e = _expression;
    for (var i = 0;i < argumentsCount;i++)
      e = e.replaceAll('${_arguments[i]}.', '${arguments[i]}.');
    return e;
  }
}

class PredicateParser {
  final ClosureMirror _mirror;
  final Function _predicate;
  Iterable<String> _arguments;
  String _expression;
  final List _variables = [];

  PredicateParser(Function predicate) :
  _predicate = predicate,
  _mirror = reflect(predicate);

  static PredicateExpression parse(Function predicate) {
    try {
      return new PredicateParser(predicate)._parse();
    } on PredicateParserException {
      rethrow;
    } catch (e) {
      throw const PredicateParserException('The predicate is not valid!');
    }
  }

  PredicateExpression _parse() {
    final match = new RegExp(r'\((.+?)\)\s*=>\s*(.*)').firstMatch(_source);
    _arguments = match[1].split(new RegExp(r'\s*,\s*'));
    _expression = match[2];
    _resolveVariables();
    return new PredicateExpression(_variables, _arguments, _expression);
  }

  void _resolveVariables() {
    final rows = _arguments.map((row) => new _PredicateRowMock(row)).toList();
    _mirror.apply(rows);
    for (_PredicateRowMock row in rows) {
      for (var field in row.fields.values) {
        for (var operation in field.operations) {
          print('${row.name}.${field.name} ${operation[0]} ${operation[1]}');
          final regExp = '${row.name}.${field.name}'r'\s*'
          '${operation[0]}'r'.*?(?=[&|=<>]|$)';
          final value = operation[1];
          if (value is _PredicateFieldMock)
            continue;
          final replaceWith = '${row.name}.${field.name} ${operation[0]} ${_formatInjectedValue(value)} ';
          _expression = _expression.replaceFirst(new RegExp(regExp), replaceWith).trim();
        }
      }
    }
  }

  String _formatInjectedValue(Object value) {
    if (value is String) {
      _variables.add(value);
      return '?';
    }
    if (value is DateTime)
      return 'date(${value.toIso8601String()})';
    return '$value';
  }

  String get _source {
    return _mirror.function.source;
  }
}

class _PredicateRowMock {
  final String name;
  final Map<Symbol, _PredicateFieldMock> fields = {};

  _PredicateRowMock(String this.name);

  noSuchMethod(Invocation invocation) {
    if (invocation.isGetter) {
      if (!fields.containsKey(invocation.memberName))
        fields[invocation.memberName] = (new _PredicateFieldMock(MirrorSystem.getName(invocation.memberName)));
      return fields[invocation.memberName];
    }
    return super.noSuchMethod(invocation);
  }

  toString() => '$name: [${fields.values.join(', ')}]';
}

class _PredicateFieldMock {
  final String name;
  final List<List> operations = [];

  _PredicateFieldMock(String this.name);

  operator ==(v) => _registerComparison('==', v);

  operator >=(v) => _registerComparison('>=', v);

  operator <=(v) => _registerComparison('<=', v);

  operator >(v) => _registerComparison('>', v);

  operator <(v) => _registerComparison('<', v);

  _registerComparison(String operator, value) {
    operations.add([operator, value]);
    return false;
  }

  toString() => '$name: [${operations.join(', ')}]';
}

class PredicateParserException implements Exception {
  final String message;

  const PredicateParserException(String this.message);

  toString() => 'PredicateParserException: $message';
}
