import 'package:trestle/gateway.dart';
import 'package:trestle/trestle.dart';
import 'dart:async';

main() async {
  final drivers = [
    new MySqlDriver(database: 'test'),
    new PostgresqlDriver(database: 'test', username: 'emilpersson'),
    new SqliteDriver(':memory:'),
    new SqliteDriver('/tmp/test.db'),
    new InMemoryDriver(),
  ];

  await Future.wait(drivers.map(runDriver));
}

runDriver(Driver driver) async {
  final gateway = new Gateway(driver);
  await gateway.connect();

  try {
    if (driver is SqlDriver) await tearDown(driver);
  } catch (e) {}
  if (driver is SqlDriver) await setUp(driver);
  await run(driver, gateway);
  if (driver is SqlDriver) await tearDown(driver);

  await gateway.disconnect();
}

setUp(SqlDriver driver) async {
  final directives = driver is SqliteDriver
      ? 'integer primary key autoincrement'
      : driver is PostgresqlDriver
      ? 'serial primary key'
      : 'integer primary key auto_increment';

  await driver.execute('create table users '
      '(id $directives, age int, first_name varchar(255), last_name varchar(255));',
      []).toList();
}

tearDown(SqlDriver driver) async {
  await driver.execute('drop table users', []).toList();
}

run(Driver driver, Gateway gateway) async {
  final users = new Repository<User>();
  users.connect(gateway);

  await users.addAll([
    new User.fill('Derek', 'Richards', 41),
    new User.fill('Wendell', 'Boone', 67),
    new User.fill('Ruben', 'Brewer', 22),
    new User.fill('Lorraine', 'Armstrong', 40),
    new User.fill('Esther', 'Crawford', 14),
    new User.fill('Maxine', 'Hicks', 25),
    new User.fill('Wilma', 'Park', 54),
    new User.fill('Geraldine', 'Henry', 45),
    new User.fill('Janie', 'Bryan', 61),
    new User.fill('Sophia', 'Becker', 30),
    new User.fill('Daniel', 'Bell', 52),
    new User.fill('Angelina', 'White', 45),
    new User.fill('James', 'Olson', 26),
    new User.fill('Nadine', 'Carpenter', 57),
    new User.fill('Terry', 'Wolfe', 45),
    new User.fill('Leland', 'Wilson', 34),
    new User.fill('Darrel', 'Coleman', 37),
    new User.fill('Traci', 'Boyd', 62),
    new User.fill('Krystal', 'Alexander', 10),
    new User.fill('Lindsey', 'Hawkins', 3),
    new User.fill('Enrique', 'Hall', 50),
    new User.fill('Victor', 'Mcgee', 39),
    new User.fill('Rex', 'Nash', 32),
    new User.fill('Johnnie', 'Carter', 23),
    new User.fill('Pat', 'Bowers', 63),
    new User.fill('Pearl', 'Manning', 34),
    new User.fill('Thelma', 'Cannon', 10),
    new User.fill('Don', 'Foster', 4),
    new User.fill('Milton', 'Norris', 46),
    new User.fill('Sheldon', 'Copeland', 19),
    new User.fill('Pablo', 'Simmons', 10),
    new User.fill('Kari', 'Howell', 27),
    new User.fill('Gilbert', 'Freeman', 45),
    new User.fill('Frank', 'Moody', 60),
    new User.fill('Harriet', 'Simpson', 23),
    new User.fill('Kate', 'Nguyen', 71),
    new User.fill('Cassandra', 'Nunez', 16),
    new User.fill('Darrell', 'Mills', 69),
    new User.fill('Jeannie', 'Pierce', 18),
    new User.fill('Carol', 'Dennis', 59),
    new User.fill('Bessie', 'Keller', 7),
    new User.fill('Mark', 'Wheeler', 20),
    new User.fill('Heidi', 'Moore', 5),
    new User.fill('Carolyn', 'Logan', 21),
    new User.fill('Margarita', 'Sherman', 2),
    new User.fill('Anne', 'Bowman', 32),
    new User.fill('Kim', 'Lee', 47),
    new User.fill('Kent', 'Blair', 17),
    new User.fill('Andre', 'Owens', 38),
    new User.fill('Jeannette', 'Hoffman', 10),
  ]);

  await for (final user in users.where((u) => u.age > 70).get())
    print(user);
}

class User {
  int id;
  String first_name;
  String last_name;
  int age;

  User();

  User.fill(String this.first_name, String this.last_name, int this.age);

  String toString() => 'User($id, $first_name $last_name, age $age)';
}