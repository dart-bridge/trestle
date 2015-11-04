part of trestle.orm;

class _OneToOneRelationship<Parent extends Model, Child extends Model>
    extends _RelationshipDeclaration<Parent, Child> {
  _OneToOneRelationship(_RelationshipDeclarationData data) : super(data);

  RepositoryQuery<Parent> parent(Map child) {
    return _parentQuery((q) => q
        .where((parent) => parent[_myKeyOnThem] == child[_myKeyOnMe]));
  }

  RepositoryQuery<Child> child(Map parent) {
    return _childQuery((q) => q
        .where((child) => child[_theirKeyOnThem] == parent[_theirKeyOnMe]));
  }

  void setOnParent(Map child, void set(String field, Object value)) {
    set(_theirKeyOnMe, child[_theirKeyOnThem]);
  }

  void setOnChild(Map parent, void set(String field, Object value)) {}
}