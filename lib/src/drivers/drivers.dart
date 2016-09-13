/// This library contains the implementations of database
/// connector drivers that plug into the gateway API.
///
/// That means this library contains everything that's
/// specific to SQL, and all the different SQL engines.
///
/// The drivers then conforms to async return types, like
/// [Stream<Map<String, dynamic>>] for rows in a table.
library trestle.drivers;

import 'dart:async';
import 'dart:convert';
import 'dart:mirrors';

import 'package:trestle/src/gateway/constraints/constraints.dart';
import 'package:trestle/src/gateway/gateway.dart';
import 'package:sqljocky/sqljocky.dart' as sqljocky;
import 'package:postgresql/postgresql.dart' as postgresql;
import 'package:sqlite/sqlite.dart' as sqlite;

part 'in_memory_driver.dart';
part 'sql_driver.dart';
part 'sql_standards.dart';
part 'my_sql_driver.dart';
part 'postgresql_driver.dart';
part 'sqlite_driver.dart';
