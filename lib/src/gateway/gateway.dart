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
import 'dart:collection';

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
  final Driver driver;

  Gateway(Driver this.driver);

  Future connect() => driver.connect();

  Future disconnect() => driver.disconnect();

  Query table(String name) =>
      new Query(driver, name);
}

