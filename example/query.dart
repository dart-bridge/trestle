part of example.gateway;

/// This is how insert statements are constructed. To conform
/// more to the native syntax of Dart, we say `add` instead of insert,
/// however there are aliases `insert` and `insertAll` as well.
create(Gateway gateway) async {
  await gateway.table('addresses').addAll([
    {'street': 'First st.'},
    {'street': 'Second st.'}
  ]);

  await gateway.table('users').add({
    'first_name': 'John',
    'last_name': 'Doe',
    'age': 35,
    'address_id': 1
  });
}

/// Select statements are simply a stream of maps returned when
/// calling the `get` method. To get the first matching row only,
/// call `first`, equivalent of `limit(1).get`. Both `get` and
/// `first` can optionally send through the columns to fetch.
read(Gateway gateway) async {
  // Query: "get the first address"
//  await gateway.table('addresses').first();
  // Result: {id: 1x, street: First st.}

  // Query: "get the first ten users older than 20, and include their street address"
  await gateway.table('users')
  .limit(10)
  .where((user) => user.age > 20)
  .distinct()
  .join('addresses', (user, address) => user.addressId == address.id)
  .get(['first_name', 'street']);
  // Result: [{first_name: John, street: First st.}]
}

/// Update statements are simply equal to insert statements, but
/// using constraints and the `update` method to change the affected rows.
update(Gateway gateway) async {
  await gateway.table('users').find(1)
  //                           ^^^^^^^
  // this is equal to `.where((user) => user.id == 1)`
  .update({'first_name': 'Jane'});

  await gateway.table('users').find(1).increment('age');
  await gateway.table('users').find(1).decrement('age', 5);
}

// Delete by simply using `delete` on the constraints
delete(Gateway gateway) async {
  await gateway.table('users')
  .where((user) => user.firstName == 'John')
  .delete();
}

// Get statistics on the table using these aggregate methods
aggregates(Gateway gateway) async {
  await gateway.table('users').count();
  await gateway.table('users').max('age');
  await gateway.table('users').min('age');
  await gateway.table('users').average('age');
  await gateway.table('users').sum('age');
}

// Example queries using all constraints
constraints(Gateway gateway) {
  gateway.table('users')
  .where((user) => user.age > 10)
  .sortBy('last_name', 'asc')
  .limit(10)
  .offset(10)
  .distinct();

  gateway.table('users')
  .groupBy('last_name')
  .sum('age');
  // Given users Jane Doe, 35; John Doe, 37, Lebron James, 40;
  // Result: {Doe: 72, James: 40}
}
