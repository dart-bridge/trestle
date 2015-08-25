import 'dart:async';
import 'dart:mirrors';

import 'package:trestle/src/gateway/constraints/constraints.dart';
import 'package:trestle/src/gateway/gateway.dart';

class LoggingDriver implements Driver {
  String _predicateSource(Function predicate) {
    return (reflect(predicate) as ClosureMirror)
    .function.source.replaceFirst(new RegExp(r'\(.*?\) =>'), '').trim();
  }

  String _formatConstraint(Constraint constraint) {
    if (constraint is DistinctConstraint) return 'without any duplicates';
    if (constraint is GroupByConstraint) return 'grouping by ${constraint.field}';
    if (constraint is JoinConstraint) return 'including fields from ${_formatQuery(constraint.foreign)} where ${_predicateSource(constraint.predicate)}';
    if (constraint is LimitConstraint) return 'stopping after ${constraint.count} rows';
    if (constraint is OffsetConstraint) return 'starting after ${constraint.count} rows';
    if (constraint is SortByConstraint) return 'sorting by ${constraint.field} in ${constraint.direction == SortByConstraint.descending ? 'descending' : 'ascending'} order';
    if (constraint is WhereConstraint) return 'but only on rows where ${_predicateSource(constraint.predicate)}';
    return '';
  }

  String _formatConstraints(List<Constraint> constraints) {
    return constraints.map(_formatConstraint).join(', ');
  }

  String _formatQuery(Query query) {
    if (query.constraints.isEmpty) return 'table ${query.table}';
    return 'table ${query.table}, ${_formatConstraints(query.constraints)}';
  }

  Future add(Query query, Map<String, dynamic> row) async {
    print('Adding $row to ${_formatQuery(query)}');
  }

  Future addAll(Query query, Iterable<Map<String, dynamic>> rows) {
    return Future.wait(rows.map((row) => add(query, row)));
  }

  Future<double> average(Query query, String field) async {
    print('Getting the average ${field} from ${_formatQuery(query)}');
    return 0.0;
  }

  Future<int> count(Query query) async {
    print('Counting the rows in ${_formatQuery(query)}');
    return 0;
  }

  Future decrement(Query query, String field, int amount) async {
    print('Decreasing each ${field} by $amount, in ${_formatQuery(query)}');
  }

  Future delete(Query query) async {
    print('Deleting every row on ${_formatQuery(query)}');
  }

  Stream<Map<String, dynamic>> get(Query query, Iterable<String> fields) {
    print('Getting all rows from ${_formatQuery(query)}');
    return new Stream.fromIterable([{}]);
  }

  Future increment(Query query, String field, int amount) async {
    print('Increasing each ${field} by $amount, in ${_formatQuery(query)}');
  }

  Future<int> max(Query query, String field) async {
    print('Getting the maximum ${field} from ${_formatQuery(query)}');
    return 0;
  }

  Future<int> min(Query query, String field) async {
    print('Getting the minimum ${field} from ${_formatQuery(query)}');
    return 0;
  }

  Future<int> sum(Query query, String field) async {
    print('Getting the sum of every ${field} from ${_formatQuery(query)}');
    return 0;
  }

  Future update(Query query, Map<String, dynamic> fields) async {
    print('Updating the rows in ${_formatQuery(query)}, updating the fields '
    '${fields.keys} with the values ${fields.values}');
  }

  Future connect() async {
  }

  Future disconnect() async {
  }
}
