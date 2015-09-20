import 'package:trestle/trestle.dart';
import 'package:trestle/gateway.dart';
import 'session.dart';

final driver = new InMemoryDriver();

main() => session(driver, (Gateway gateway) async {
  final repo = new Repository<User>()
    ..connect(gateway);

  repo.addAll([
    new User.create('Jane', 'Doe', 36),
    new User.create('John', 'Doe', 35),
  ]);

  await repo.count(); // 2
  // TODO: await repo.average('age'); // 35.5

  await repo.all().toList(); // [Jane, John]

  await repo.where((user) => user.first_name == 'Jane')
      .increment('age'); // Jane's age is now 37

  // TODO: await repo.sortBy('age', 'desc')
  //    .get().toList(); // [John, Jane]

  // TODO: await repo.clear(); // "users" is now truncated
});

class User {
  String first_name;
  String last_name;
  int age;

  User();

  User.create(String this.first_name, String this.last_name, int this.age);

  String toString() => first_name;
}