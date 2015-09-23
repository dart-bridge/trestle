import 'package:trestle/gateway.dart';
import 'session.dart';

final SqliteDriver driver = new SqliteDriver(':memory:');

main() => session(driver, (Gateway gateway) async {
  print(await gateway.create('users', (Schema schema) {
    schema.id();
    schema.string('first_name').nullable(false);
    schema.string('last_name').nullable(false);
    schema.string('nick_name').nullable(true);
    schema.int('age');
    schema.int('address_id')
        .references('addresses')
        .onDelete('set null');
  }));

  print(await gateway.alter('users', (Schema schema) {
    schema.delete('nick_name');
  }));

  print(await gateway.create('addresses', (Schema schema) {
    schema.id();
    schema.string('street').nullable(false);
    schema.int('age');
  }));

  print(await driver.execute('pragma table_info("users");', []).toList());
});