import 'package:trestle/gateway.dart';
import 'session.dart';
import 'dart:async';

final driver = new SqliteDriver(':memory:');

final migrations = [
  CreateUsersTableMigration,
  RemoveNickNameColumnFromUsersTableMigration,
  CreateAddressesTableMigration,
].toSet();

main() => session(driver, (Gateway gateway) async {
  gateway.migrate(migrations);
  gateway.rollback(migrations);
});

class CreateUsersTableMigration extends Migration {
  Future run(Gateway gateway) async {
    gateway.create('users', (Schema schema) {
      schema.id();
      schema.string('first_name').nullable(false);
      schema.string('last_name').nullable(false);
      schema.string('nick_name').nullable(true);
      schema.int('age');
      schema.int('address_id')
          .references('addresses')
          .onDelete('set null');
    });
  }

  Future rollback(Gateway gateway) async {
    gateway.drop('users');
  }
}

class RemoveNickNameColumnFromUsersTableMigration extends Migration {
  Future run(Gateway gateway) async {
    gateway.alter('users', (Schema schema) {
      schema.delete('nick_name');
    });
  }

  Future rollback(Gateway gateway) async {
    gateway.alter('users', (Schema schema) {
      schema.string('nick_name').nullable(true);
    });
  }
}

class CreateAddressesTableMigration extends Migration {
  Future run(Gateway gateway) async {
    gateway.create('addresses', (Schema schema) {
      schema.id();
      schema.string('street').nullable(false);
      schema.int('age');
    });
  }

  Future rollback(Gateway gateway) async {
    gateway.drop('addresses');
  }
}