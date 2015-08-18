/// This abstract library contains the logic associated
/// with the query builder, providing a type safe interface
/// that doesn't depend on an implementation.
///
/// That means this library doesn't contain anything associated
/// with SQL. It only provides a fluent query builder and
/// creates database agnostic query objects.
library trestle.gateway;