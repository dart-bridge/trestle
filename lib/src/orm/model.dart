library trestle.orm.model;

part 'annotations.dart';

abstract class Model {
  @field int id;
  @field DateTime createdAt = new DateTime.now();
  @field DateTime updatedAt = new DateTime.now();

  operator ==(Model other) =>
      other.runtimeType == runtimeType &&
          other.id == id;
}
