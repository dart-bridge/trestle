part of trestle.model;

class Field {
  final String columnName;

  const Field([String this.columnName = null]);
}

const field = const Field();

abstract class Model {
  @field int id;
  @Field('created_at') DateTime createdAt;
  @Field('updated_at') DateTime updatedAt;

  Model() :
        createdAt = new DateTime.now(),
        updatedAt = new DateTime.now();
}
