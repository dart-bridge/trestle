part of trestle.orm;

class _OneToManyRelationship<Parent extends Model, Child extends Model>
    extends _RelationshipDeclaration<Parent, Child> {
  _OneToManyRelationship(_RelationshipDeclarationData data) : super(data);

  RepositoryQuery<Parent> parent(Map child) {
    return _parentQuery((q) => q
        .where((parent) => parent[_theirKeyOnThem] == child[_theirKeyOnMe]));
  }

  RepositoryQuery<Child> child(Map parent) {
    return _childQuery((q) => q
        .where((child) => child[_myKeyOnThem] == parent[_myKeyOnMe]));
  }
}