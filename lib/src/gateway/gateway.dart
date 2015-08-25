/// This abstract library contains the logic associated
/// with the query builder, providing a type safe interface
/// that doesn't depend on an implementation.
///
/// That means this library doesn't contain anything associated
/// with SQL. It only provides a fluent query builder and
/// creates database agnostic query objects.
library trestle.gateway;

import 'dart:async';
import 'dart:mirrors';

import 'constraints/constraints.dart';

part 'driver.dart';
part 'query.dart';
part 'constraints.dart';
part 'aggregates.dart';
part 'create_actions.dart';
part 'read_actions.dart';
part 'update_actions.dart';
part 'delete_actions.dart';
part 'predicate_parser.dart';

class Gateway {
  final Driver _driver;

  Gateway(Driver this._driver);

  Future connect() => _driver.connect();

  Future disconnect() => _driver.disconnect();

  Query table(String name) => new Query(_driver, name);
}

