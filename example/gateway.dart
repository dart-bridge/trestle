library example.gateway;

import 'package:trestle/src/gateway/gateway.dart';
import 'package:trestle/src/drivers/drivers.dart';
import 'driver.dart';

part 'query.dart';
part 'schema.dart';

main() async {
  final loggingGateway = new Gateway(new LoggingDriver());
  print('CREATE:');
  await create(loggingGateway);
  print('\n');
  print('READ:');
  await read(loggingGateway);
  print('\n');
  print('UPDATE:');
  await update(loggingGateway);
  print('\n');
  print('DELETE:');
  await delete(loggingGateway);

  var gateway = new Gateway(new InMemoryDriver());

  await gateway.table('users').addAll([
    {'id': 1, 'first_name': 'John', 'last_name': 'Doe', 'age': 37, 'address_id': 1},
    {'id': 2, 'first_name': 'Jane', 'last_name': 'Doe', 'age': 35, 'address_id': 1},
    {'id': 3, 'first_name': 'David', 'last_name': 'Smith', 'age': 28, 'address_id': 2},
    {'id': 4, 'first_name': 'Jenny', 'last_name': 'Jackson', 'age': 24, 'address_id': 3},
  ]);

  await gateway.table('addresses').addAll([
    {'id': 1, 'street': 'First st.', 'number': 15, 'apartment_no': 172},
    {'id': 2, 'street': 'Second st.', 'number': 2, 'apartment_no': null},
    {'id': 3, 'street': 'Second st.', 'number': 5, 'apartment_no': null},
  ]);

  print('All users:');
  print(await gateway.table('users')
  .get().toList());

  print('All addresses:');
  print(await gateway.table('addresses')
  .get().toList());

  print('All first names of users named Doe:');
  print(await gateway.table('users')
  .where((user) => user.lastName == 'Doe')
  .get(['first_name']).toList());

  print('The sum of the ages of all users not called Doe:');
  print(await gateway.table('users')
  .where((user) => user.lastName != 'Doe')
  .sum('age'));

  print('First names and street addresses for all users:');
  print(await gateway.table('users')
  .join('addresses', (user, address) => user.addressId == address.id)
  .get(['first_name', 'street', 'number', 'apartment_no']).toList());
}

