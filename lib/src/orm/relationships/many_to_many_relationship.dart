part of trestle.orm;

class _ManyToManyRelationship<Parent extends Model, Child extends Model> {
  final Gateway _gateway;
  final HasMany _parentAnnotation;
  final BelongsToMany _childAnnotation;

  _ManyToManyRelationship(this._gateway, this._parentAnnotation,
      this._childAnnotation);

  RepositoryQuery<Parent> parentsOf(Child child,
      MapsFieldsToModel<Parent> entity) {
    throw 'MANY TO MANY';
  }

  RepositoryQuery<Child> childrenOf(Parent parent,
      MapsFieldsToModel<Child> entity) {
    throw 'MANY TO MANY';
  }
}
