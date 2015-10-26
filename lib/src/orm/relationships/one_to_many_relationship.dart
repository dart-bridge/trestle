part of trestle.orm;

class _OneToManyRelationship<Parent extends Model, Child extends Model> {
  final Gateway _gateway;
  final HasMany _parentAnnotation;
  final BelongsTo _childAnnotation;

  _OneToManyRelationship(this._gateway, this._parentAnnotation,
      this._childAnnotation);

  Future<Parent> parentOf(Child child,
      MapsFieldsToModel<Parent> entity) {
    throw 'ONE TO MANY';
  }

  RepositoryQuery<Child> childrenOf(Parent parent,
      MapsFieldsToModel<Child> entity) {
    throw 'ONE TO MANY';
  }
}