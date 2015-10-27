part of trestle.orm;

class _ManyToManyRelationship<Parent extends Model, Child extends Model>
    extends _RelationshipDeclaration<Parent, Child> {
  _ManyToManyRelationship(_RelationshipDeclarationData data) : super(data);

  RepositoryQuery<Parent> parent(Map child) {
    return _pivot(child, _parentMapper);
  }

  RepositoryQuery<Child> child(Map parent) {
    return _pivot(parent, _childMapper);
  }

  RepositoryQuery _pivot(Map self, MapsFieldsToModel mapper) {
    final query = _gateway.table(_pivotTable)
        .join(mapper.table,
        (pivot, other) => pivot[_theirKeyOnPivot] == other[_theirPivotKeyOnThem])
        .where((pivot) => pivot[_myKeyOnPivot] == self[_myKeyOnMe]);
    return new RepositoryQuery(query, mapper);
  }
}
