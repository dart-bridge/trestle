import 'package:trestle/gateway.dart';
import 'session.dart';
import 'package:trestle/trestle.dart';

//final Driver driver = new SqliteDriver(':memory:');
//final Driver driver = new MySqlDriver(database: 'test');
//final Driver driver = new PostgresqlDriver(database: 'test');
final Driver driver = new InMemoryDriver();

main() => session(driver, (Gateway gateway) async {
  await gateway.model('persons', (schema) {
    schema.string('first_name');
    schema.string('last_name');
    schema.int('address_id');
  });

  await gateway.model('addresses', (schema) {
    schema.string('street');
    schema.string('number');
  });

  final people = new Repository<Person>(gateway);
  final addresses = new Repository<Address>(gateway);

  final jane = new Person()
    ..firstName = 'Jane'
    ..lastName = 'Doe';

  final john = new Person()
    ..firstName = 'John'
    ..lastName = 'Doe';

  final elmSt = new Address()
    ..street = 'Elm St.'
    ..number = '13F';

  final sesameSt = new Address()
    ..street = 'Sesame St.'
    ..number = '1';

  jane.address = elmSt;
  elmSt.owner = jane;
  john.address = sesameSt;
  sesameSt.owner = john;

  await addresses.save(elmSt);
  await addresses.save(sesameSt);
  await people.save(jane);

  await people.save(john);

  print(await people.all().join('\n'));
  // Jane Doe lives on 13F Elm St.
  // John Doe lives on 1 Sesame St.

  print(await addresses.all().join('\n'));
  // 13F Elm St. is owned by Jane Doe
  // 1 Sesame St. is owned by John Doe

  await gateway.drop('persons');
  await gateway.drop('addresses');
});

class Person extends Model {
  @field String firstName;
  @field String lastName;

  @hasOne Address address;

  String toString() => '$firstName $lastName ' + (address == null
      ? 'is homeless'
      : 'lives on ${address.number} ${address.street}');
}

class Address extends Model {
  @field String street;
  @field String number;

  @belongsTo Person owner;

  String toString() => '$number $street ' + (owner == null
      ? 'is vacant'
      : 'is owned by ${owner.firstName} ${owner.lastName}');
}
