part of trestle.orm;

class Field {
  final String field;

  const Field([this.field]);
}

const field = const Field();

abstract class Model {
  @field int id;
  @field DateTime createdAt = new DateTime.now();
  @field DateTime updatedAt = new DateTime.now();

  operator ==(Model other) =>
      other.runtimeType == runtimeType &&
          other.id == id;
}
