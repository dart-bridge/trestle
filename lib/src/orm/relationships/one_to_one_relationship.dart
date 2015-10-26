part of trestle.orm;


class _OneToOneRelationship<Parent extends Model, Child extends Model> {
  final Gateway _gateway;
  final HasOne _parentAnnotation;
  final BelongsTo _childAnnotation;

  _OneToOneRelationship(
      this._gateway,
      this._parentAnnotation,
      this._childAnnotation);

  Future<Parent> parentOf(
      Symbol childSymbolOnParent,
      Child child,
      Map childRow,
      MapsFieldsToModel<Parent> entity,
      MapsFieldsToModel<Child> childEntity) async {
    final parentId = _childAnnotation.mine
        ?? _parentAnnotation.theirs
        ?? childEntity.foreignKey;
    final childId = _childAnnotation.theirs
        ?? _parentAnnotation.mine
        ?? 'id';
    final Map row = await _gateway.table(entity.table)
        .where((parent) => parent[parentId] == childRow[childId])
        .first().catchError((_) => null);
    if (row == null) return null;
    final model = await entity.deserialize(row, attachRelationships: false);
    reflect(model).setField(childSymbolOnParent, child);
    return model;
//    return entity.deserializeRelationships(model, row);
  }

  Future<Child> childOf(Symbol parentSymbolOnChild, Parent parent, Map parentRow,
      MapsFieldsToModel<Child> entity) async {
    final childId = _parentAnnotation.mine
        ?? _childAnnotation.theirs
        ?? 'id';
    final parentId = _parentAnnotation.theirs
        ?? _childAnnotation.mine
        ?? entity.foreignKey;
    final Map row = await _gateway.table(entity.table)
        .where((child) => child[childId] == parentRow[parentId])
        .first().catchError((_) => null);
    if (row == null) return null;
    final model = await entity.deserialize(row, attachRelationships: false);
    reflect(model).setField(parentSymbolOnChild, parent);
    return model;
//    return entity.deserializeRelationships(model, row);
  }
}