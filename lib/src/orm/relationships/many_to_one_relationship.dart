part of trestle.orm;

class _ManyToOneRelationship<Parent extends Model, Child extends Model> {
  final Gateway _gateway;
  final HasOne _parentAnnotation;
  final BelongsToMany _childAnnotation;

  _ManyToOneRelationship(this._gateway, this._parentAnnotation,
      this._childAnnotation);

  RepositoryQuery<Parent> parentsOf(Child child,
      MapsFieldsToModel<Parent> entity) {
    throw 'MANY TO ONE';
  }

  Future<Child> childOf(Parent parent,
      MapsFieldsToModel<Child> entity) {
    throw 'MANY TO ONE';
  }
}
