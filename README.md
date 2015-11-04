# Trestle

_Database gateway and ORM for Dart_

[![Build Status](https://travis-ci.org/dart-bridge/trestle.svg)](https://travis-ci.org/dart-bridge/trestle)

---

* [Abstract](#abstract)
* [Getting started](#getting-started)
* [Gateway](#gateway)
    * [Creating a table](#creating-a-table)
    * [Altering a table](#altering-a-table)
    * [Deleting a table](#deleting-a-table)
    * [Accessing a table](#accessing-a-table)
* [Migrations](#migrations)
* [ORM](#orm)
    * [Extending the repository](#extending-the-repository)

---

## Abstract

Trestle is the database package used in [Bridge](https://github.com/dart-bridge). It was created with extensibility and
clean API in mind. Providing a unified interface to work with different databases across multiple setups for maximum
reusability and agility.

The package is divided into two parts – the _Gateway_ and the _ORM_. The Gateway is the common abstraction that the
different database drivers implement, and the ORM uses the Gateway to talk to the database.

The Gateway has both a _Schema Builder_ and a _Query Builder_, accessible from the common _Gateway_ class.

One of the more controversial features of Trestle are the so called _Predicate Expressions_. They are callback-style
lambda functions that are translated into SQL constraints. So we can say `where((user) => user.age > 20)`, which
then gets parsed into something like `WHERE "age" > 20`. An it works with pretty complex functions! As soon as you
create a predicate that's too complex, the runtime will tell you in time, so that you can straighten things out.

Just know that Trestle __doesn't__ get all rows and then run the constraint, even though that's what it looks like.

---

## Getting started

To get started, choose what database implementation you want to use (you can easily change your mind later). In this
example, we use the `InMemoryDriver`. It doesn't need schema and it doesn't need any configuration.

```dart
import 'package:trestle/gateway.dart';

main() async {
  // The database implementation
  Driver driver = new InMemoryDriver();

  // The gateway takes the driver as a constructor argument
  Gateway gateway = new Gateway(driver);

  // Next, connect!
  await gateway.connect();

  // ... Do some work

  // Disconnect when you're done
  await gateway.disconnect();
}
```

Later, if we want, we can just swap out the driver and call it a day.

```dart
// Driver driver = new InMemoryDriver();
// Driver driver = new SqliteDriver('storage/production.db');
// Driver driver = new MySqlDriver(username: 'myuser', password: '123', database: 'mydatabase');
Driver driver = new PostgresqlDriver(username: 'myuser', password: '123', database: 'mydatabase');
```

---

## Gateway

Think of the gateway as the actual _database_ in SQL. It contains the tables, which can be accessed and modified using
a few simple methods.


### Creating a table

To create a new table we use the `create` method on the `Gateway` class. This method takes two parameters: the name of
the table to be created, and a callback containing the _Schema Builder_. It looks like this:

```dart
await gateway.create('users', (Schema schema) {
  schema.id(); // shortcut for an auto incrementing integer primary key
  schema.string('email').unique().nullable(false);
  schema.string('username').unique().nullable(false);
  schema.string('password', 60);
  schema.timestamps(); // adds created_at and updated_at timestamps (used by the ORM)
});
```

This method returns a `Future` (much like everything else in Trestle), and should probably be `await`-ed.


### Altering a table

Altering a table is almost identical to creating one, except we use the `alter` method instead:

```dart
await gateway.alter('users', (Schema schema) {
  schema.drop('username');
  schema.string('first_name');
  schema.string('last_name');
});
```


### Deleting a table

Deleting (or dropping) a table could not be simpler:

```dart
await gateway.drop('users');
```


### Accessing a table

When we're satisfied with the columns of our table, we can start a query by calling the `table` method. This starts up
the _Query Builder_, providing a fluent API to construct queries. The builder is stateless, so we can save intermediate
queries in variables and fork them later:

```dart
// Full query
Stream allUsersOfDrinkingAge = gateway.table('users')
  .where((user) => user.age > 18).get(); // At least in Sweden...

// Intermediate query
Query uniqueAddresses = gateway.table('addresses').distinct();

// Continued query
Stream allUniqueAddressesInSweden = uniqueAddresses
  .where((address) => address.country == 'SWE').get();

// A function extending an intermediate query
Query allUniqueAddressesIn(String country) {
  return uniqueAddresses
    .where((address) => address.country == country);
}

// An aggregate query
int count = await allUniqueAddressesIn('USA').count();
```

There's a bunch of stuff you can do. Experiment with the query builder and report any bugs! :bug:

---

## Migrations

You can think of migrations as version control for your database. It's an automated way to ensure that everyone on your
team is using the same table schema. Each migration extends the `Migration` abstract class, enforcing the implementation
of a `run` method, as well as a `rollback` method.

The `run` method makes a change to the database schema (using the [familiar syntax](#creating-a-table)). The `rollback`
method reverses that change. For example, creating a table in `run`, and dropping it in `rollback`.

By storing a `Set<Type>` (where the types are subtypes of `Migration`), we can ensure that each migration is run in
order. And if we need to change something, we can roll back and re-migrate.

```dart
class CreateUsersTable extends Migration {
  Future run(Gateway gateway) {
    gateway.create('users', (Schema schema) {
      schema.id();
      schema.string('email');
      // ...
    });
  }

  Future rollback(Gateway gateway) {
    gateway.drop('users');
  }
}

final migrations = [
  CreateUsersTable,
  // more migrations
  CreateAddressesTable,
  DropUsernameColumnInUsersTable,
].toSet();

// Somewhere in a command line utility or something
gateway.migrate(migrations);

// Somewhere else – remember to import the same migrations set
gateway.rollback(migrations);
```

---

## ORM

Trestle's primary feature is to provide an ORM for the [Bridge Framework](https://github.com/dart-bridge). One of the
key features of Bridge is the WebSocket transport system _Tether_. So it was important that Trestle would be able to
map rows to plain Dart objects, that could be shared with the client.

So instead of embracing the full Active Record style, we had to move the database interaction from the data structures
to a `Repository` class. However, using a plain object without any intrusive annotations is kind of brittle. So we can
optionally extend a `Model` class and use annotations if we don't care that we're coupling ourselves to Trestle.
It works like this:

```dart
// Create a data structure
class Parent {
  int id;
  String email;
  String firstName;
  String lastName;
  String password;
  int age;
}

// Or a value object
class Parent {
  // Override the table name with a constant "table" on
  // any of these types of models
  static const String table = 'my_own_table_name';

  final int id;
  final String email;
  final String firstName;
  final String lastName;
  final String password;
  final int age;
  
  const Parent(this.id, this.email, this.firstName, 
             this.lastName, this.password, this.age);
}

// Or create a full model
class Parent extends Model {
  @field String email;
  @field String firstName;
  @field String lastName;
  @field String password;
  @field int age;
  
  // Relationships are very expressive. Here, all Child models
  // whose table rows has a key "user_id" matching this model's
  // "id" field, are eager loaded to this List.
  @hasMany List<Child> children;
  
  // You can also lazy load the children by setting the property
  // type to Stream<Child>, or (if you want to perform queries on
  // the children) to RepositoryQuery<Child>.
}

class Child extends Model {
  // Single relationships can be annotated as either `Child` (eager)
  // or `Future<Child>` (lazy).
  @belongsTo Parent user;
  @belongsTo Future<Parent> user;
}

// Instantiate the repository with a gateway as an argument and the model as a type argument.
final users = new Repository<Parent>(gateway);

// You're done! The repository works like `gateway.table('users')` would,
// but it returns `Parent` objects instead of maps.
Parent parent = await users.find(1);

// The relationships are mapped automatically.
Child child = parent.children.first;

print(child.parent == parent); // true
print(parent.child == child); // true
```


### Extending the repository

We can use this class to implement some query scopes or filters:

```dart
class UsersRepository extends Repository<User> {
  RepositoryQuery<User> get ofDrinkingAge => where((user) => user.age > 20);
}

// And use it like so:
users.ofDrinkingAge.count();
```

---

## In Bridge

As (soon to be) mentioned in the Bridge docs, Trestle is automatically set up for you, so we can use dependency
injection to get immediate access to a repository:

```dart
// An example in the context of the HTTP router – not a part of Trestle
router.get('/users/count', (Repository<User> users) async {
  return 'There are ${await users.count()} users registered';
});
```

