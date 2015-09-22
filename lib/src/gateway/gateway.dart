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
import 'dart:core';
import 'dart:core' as core show int;

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
part 'schema.dart';
part 'column.dart';
part 'foreign_key.dart';
part 'migration.dart';

class Gateway {
  final Driver driver;

  Gateway(Driver this.driver);

  Future connect() => driver.connect();

  Future disconnect() => driver.disconnect();

  Query table(String name) =>
      new Query(driver, name);

  Future create(String name, Future blueprint(Schema schema)) {
    throw new UnsupportedError('To be implemented');
  }

  Future alter(String name, Future blueprint(Schema schema)) {
    throw new UnsupportedError('To be implemented');
  }

  Future drop(String name) {
    throw new UnsupportedError('To be implemented');
  }

  Future migrate(Map<String, Type> migrations) {
    throw new UnsupportedError('To be implemented');
  }

  Future rollback() {
    throw new UnsupportedError('To be implemented');
  }
}

