import 'package:trestle/gateway.dart';
import 'session.dart';

final driver = new InMemoryDriver();

main() => session(driver, (Gateway gateway) async {
  gateway.table('users').addAll([
    {'first_name': 'Jane', 'last_name': 'Doe', 'age': 36},
    {'first_name': 'John', 'last_name': 'Doe', 'age': 35},
  ]);

  await gateway.table('users')
      .count(); // 2
  await gateway.table('users')
      .average('age'); // 35.5

  await gateway.table('users')
      .get(['first_name']).toList(); // [{first_name: Jane}, {first_name: John}]

  await gateway.table('users')
      .where((user) => user.first_name == 'Jane')
      .increment('age'); // Jane's age is now 37

  await gateway.table('users')
      .sortBy('age', 'asc')
      .get(['age']).toList(); // [{age: 35}, {age: 37}]

  await gateway.table('users')
      .delete(); // "users" is now truncated
});