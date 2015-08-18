/// This library contains the implementations of database
/// connector drivers that plug into the gateway API.
///
/// That means this library contains everything that's
/// specific to SQL, and all the different SQL engines.
///
/// The drivers then conforms to async return types, like
/// [Stream<Map<String, dynamic>>] for rows in a table.
library trestle.drivers;