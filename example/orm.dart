import 'package:trestle/trestle.dart';
import 'package:trestle/gateway.dart';
import 'session.dart';

final driver = new SqliteDriver(':memory:');

main() => session(driver, (Gateway gateway) async {
  final repo = new Repository<User>()
    ..connect(gateway);

  repo.addAll([
    new User.create('Jane', 'Doe', 36),
    new User.create('John', 'Doe', 35),
  ]);

  await repo.count(); // 2
  await repo.average('age'); // 35.5

  await repo.all().toList(); // [Jane, John]

  await repo.where((user) => user.firstName == 'Jane')
      .increment('age'); // Jane's age is now 37

  await repo.sortBy('age', 'desc')
      .get().toList(); // [John, Jane]

  await repo.clear(); // "users" is now truncated
});

class User extends Model {
  @Field('first_name') String firstName;
  @Field('last_name') String lastName;
  @field int age;

  User();

  User.create(String this.firstName, String this.lastName, int this.age);

  String toString() => firstName;
}