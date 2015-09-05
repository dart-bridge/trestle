/// This library uses mirrors to map the asynchronous
/// return values, that the gateway returns from the drivers,
/// over to active record like classes.
///
/// This library should only be concerned with the data
/// mapping, and should depend on the gateway library
/// for retrieving the data to work with.
library trestle.orm;

import 'dart:async';
import 'dart:mirrors';

import '../gateway/gateway.dart';

part 'repository.dart';
part 'model.dart';
