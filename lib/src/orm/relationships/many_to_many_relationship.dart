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
    final query = _gateway.table(_parentMapper.pivot(_childMapper))
        .join(mapper.table,
        (pivot, other) => other[_theirKeyOnThem] == pivot[_theirKeyOnMe])
        .where((other) => other[_myKeyOnThem] == self[_myKeyOnMe]);
    return new RepositoryQuery(query, mapper);
  }
}
