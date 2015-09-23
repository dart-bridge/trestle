import 'package:test/test.dart';
import 'package:trestle/gateway.dart';
import 'dart:async';
import '../drivers/sql_driver_test.dart';

main() {
  MockSqlDriver driver;
  Gateway gateway;

  setUp(() {
    driver = new MockSqlDriver();
    gateway = new Gateway(driver);
    FirstMigration.wasRun = false;
    FirstMigration.wasRolledBack = false;
  });

  expectQuery(String query, [List variables = const []]) {
    expect(driver.queries, contains(query));
    if (variables.isNotEmpty)
      expect(driver.variableSets.any((e) => equals(variables).matches(e, {})),
          isTrue, reason: '$variables was not passed');
  }

  test('run a single migration', () async {
    await gateway.migrate([
      FirstMigration
    ].toSet());

    expect(FirstMigration.wasRun, isTrue);
    expect(FirstMigration.wasRolledBack, isFalse);

    expectQuery(
        'INSERT INTO "__migrations" ("name") VALUES (?);',
        ['FirstMigration']);
  });

  test('throw when another migration set is applied over', () async {
    driver.willReturn = [{'name': 'FirstMigration'}];

    expect(gateway.migrate([
      SecondMigration
    ].toSet()), throwsA(new isInstanceOf<MigrationException>()));
  });

  test('multiple migrations', () async {
    driver.willReturn = [
      {'name': 'FirstMigration'},
      {'name': 'SecondMigration'}
    ];

    await gateway.migrate([
      FirstMigration,
      SecondMigration,
      ThirdMigration,
      FourthMigration
    ].toSet());

    expect(FirstMigration.wasRun, isFalse);
    expect(SecondMigration.wasRun, isFalse);
    expect(ThirdMigration.wasRun, isTrue);
    expect(FourthMigration.wasRun, isTrue);

    expectQuery(
        'INSERT INTO "__migrations" ("name") VALUES (?);',
        ['ThirdMigration']);
    expectQuery(
        'INSERT INTO "__migrations" ("name") VALUES (?);',
        ['FourthMigration']);
  });

  test('rollback', () async {
    driver.willReturn = [
      {'name': 'FirstMigration'},
      {'name': 'SecondMigration'},
      {'name': 'ThirdMigration'},
    ];

    await gateway.rollback([
      FirstMigration,
      SecondMigration,
      ThirdMigration,
      FourthMigration
    ].toSet());

    expect(FirstMigration.wasRolledBack, isTrue);
    expect(SecondMigration.wasRolledBack, isTrue);
    expect(ThirdMigration.wasRolledBack, isTrue);
    expect(FourthMigration.wasRolledBack, isFalse);
  });
}


class FirstMigration extends Migration {
  static bool wasRun = false;
  static bool wasRolledBack = false;

  Future run(Gateway gateway) async {
    wasRun = true;
  }

  Future rollback(Gateway gateway) async {
    wasRolledBack = true;
  }
}

class SecondMigration extends Migration {
  static bool wasRun = false;
  static bool wasRolledBack = false;

  Future run(Gateway gateway) async {
    wasRun = true;
  }

  Future rollback(Gateway gateway) async {
    wasRolledBack = true;
  }
}

class ThirdMigration extends Migration {
  static bool wasRun = false;
  static bool wasRolledBack = false;

  Future run(Gateway gateway) async {
    wasRun = true;
  }

  Future rollback(Gateway gateway) async {
    wasRolledBack = true;
  }
}

class FourthMigration extends Migration {
  static bool wasRun = false;
  static bool wasRolledBack = false;

  Future run(Gateway gateway) async {
    wasRun = true;
  }

  Future rollback(Gateway gateway) async {
    wasRolledBack = true;
  }
}