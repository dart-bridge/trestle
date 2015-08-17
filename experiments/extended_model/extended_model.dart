/// This experiment is for investigating how to have completely
/// decoupled models, by dynamically extend the data structure at
/// runtime to hold more information, like the id of the database
/// entity.
///
/// @author Emil Persson <emil.n.persson@gmail.com>
library extended_model;

import 'dart:mirrors';

part 'src/collection.dart';
part 'src/model.dart';

main() {
  // Create collection
  final collection = new Collection<User>();

  // C – create new user and save
  final user1 = new User()
    ..firstName = 'Emil'
    ..lastName = 'Persson'
    ..age = 20;
  collection.save(user1);
  print(user1);

  // R – read from collection
  final user2 = collection.find(1);
  print(user2);

  // U – update the model
  user2.firstName = 'Johan';
  collection.save(user2);
  print(user2);

  final user3 = collection.find(1);
  print(user3);
  print(user3 == user2);
  print((user3 as Model<User>).$fields());

  print(collection.all());
}

class User {
  String firstName;
  String lastName;
  int age;

  toString() {
    return 'My name is $firstName $lastName and I\'m $age years old!';
  }
}