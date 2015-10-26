part of trestle.orm;

class _ManyToManyRelationship<Parent extends Model, Child extends Model>
    extends _RelationshipDeclaration<Parent, Child> {
  _ManyToManyRelationship(_RelationshipDeclarationData data) : super(data);

  RepositoryQuery<Parent> parent(Map fields) {
    throw 'MANY TO MANY';
  }

  RepositoryQuery<Child> child(Map fields) {
    throw 'MANY TO MANY';
  }
}
