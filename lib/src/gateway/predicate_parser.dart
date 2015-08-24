part of trestle.gateway;

class PredicateExpression {
  final Iterable<String> _arguments;
  final String _expression;

  int get argumentsCount => _arguments.length;

  const PredicateExpression(Iterable<String> this._arguments, String this._expression);

  String expression(Iterable<String> arguments) {
    var e = _expression;
    for (var i = 0;i < argumentsCount;i++)
      e = e.replaceAll(_arguments[i], arguments[i]);
    return e;
  }
}

class PredicateParser {
  final ClosureMirror _mirror;
  final Function _predicate;
  Iterable<String> _arguments;
  String _expression;

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
    final values = _getVariableValues();
    _replaceVariablesWithValues(values);
    return new PredicateExpression(_arguments, _expression);
  }

  Iterable _getVariableValues() {
    return [1];
  }

  void _replaceVariablesWithValues(List values) {
    var traversableExpression = _expression;
    var position = 0;
    final tokens = <String, RegExp>{
      'whitespace': new RegExp(r'^\s+'),
      'string': new RegExp(r'''^(['"])(?!\1)*.\1'''),
      'knownArgument': new RegExp('^(?:${_arguments.join('|')})[.a-zA-Z]*'),
      'punctuation': new RegExp('^[=<>|&()]'),
      'number': new RegExp(r'^\d[\d.]*'),
      'variable': new RegExp(r'^[a-z]\w*'),
    };
    while (traversableExpression.length > 0) {
      final positionBeforeLoop = position;
      for (var token in tokens.keys) {
        if (tokens[token].hasMatch(traversableExpression)) {
          var length = tokens[token].firstMatch(traversableExpression).end;
          traversableExpression = traversableExpression.substring(length);
          if (token == 'variable') {
            final Object val = values.removeLast();
            _expression = _expression.substring(0, position) + val.toString() + traversableExpression;
            length += '$val'.length;
          }
          position += length;
          break;
        }
      }
      if (position == positionBeforeLoop)
        throw new PredicateParserException('Invalid predicate syntax at "${traversableExpression.substring(0, min(10, traversableExpression.length))}..."');
    }
  }

  String get _source {
    return _mirror.function.source;
  }
}

class PredicateParserException implements Exception {
  final String message;

  const PredicateParserException(String this.message);

  toString() => 'PredicateParserException: $message';
}
