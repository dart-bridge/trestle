part of trestle.orm;

class ParentChildRelationship<Parent extends Model, Child extends Model> {
  final Gateway _gateway;
  final ClassMirror _parentMirror;
  final ClassMirror _childMirror;
  final ModelEntity<Parent> _parentEntity;
  final ModelEntity<Child> _childEntity;

  ParentChildRelationship(Gateway gateway, {Type parent, Type child})
      : _gateway = gateway,
        _parentMirror = reflectType(parent ?? Parent),
        _childMirror = reflectType(child ?? Child),
        _parentEntity = new ModelEntity(gateway, reflectType(parent ?? Parent)),
        _childEntity = new ModelEntity(gateway, reflectType(child ?? Child));

  DeclarationMirror _parentDeclaration() {
    final targetType = _childMirror;
    final targetOwner = _parentMirror;
    return _findRelationshipDeclaration(targetType, targetOwner);
  }

  DeclarationMirror _childDeclaration() {
    final targetType = _parentMirror;
    final targetOwner = _childMirror;
    return _findRelationshipDeclaration(targetType, targetOwner);
  }

  RelationshipAnnotation _childAnnotation(DeclarationMirror declaration) {
    return _getAnyRelationshipAnnotation(declaration,
        [BelongsTo, BelongsToMany]);
  }

  RelationshipAnnotation _parentAnnotation(DeclarationMirror declaration) {
    return _getAnyRelationshipAnnotation(declaration,
        [HasOne, HasMany]);
  }

  RelationshipAnnotation _getAnyRelationshipAnnotation(
      DeclarationMirror mirror,
      List<Type> annotations) {
    return mirror.metadata.firstWhere((i) =>
        _assignableToAny(i.type, annotations)).reflectee;
  }

  DeclarationMirror _findRelationshipDeclaration(
      ClassMirror targetType,
      ClassMirror targetOwner) {
    return targetOwner.instanceMembers.values
        .where((m) => m.isGetter)
        .where((m) =>
        _assignableToAnyRelationshipType(m.returnType, targetType))
        .map((m) => (m.owner as ClassMirror).declarations[m.simpleName])
        .first;
  }

  bool _assignableToAnyRelationshipType(TypeMirror returnType,
      ClassMirror targetType) {
    if (returnType.isAssignableTo(targetType))
      return true;
    if (returnType.isAssignableTo(reflectType(Future)) ||
        returnType.isAssignableTo(reflectType(Stream)) ||
        returnType.isAssignableTo(reflectType(List)) ||
        returnType.isAssignableTo(reflectType(RepositoryQuery)))
      return returnType.typeArguments.first.isAssignableTo(targetType);
    return false;
  }

  bool _assignableToAny(TypeMirror type, List<Type> types) {
    for (final expectedType in types)
      if (type.isAssignableTo(reflectType(expectedType)))
        return true;
    return false;
  }

  Future<Child> hasOne(Parent parent, Map parentRow, HasOne annotation) {
    final childDeclaration = _childDeclaration();
    final childAnnotation = _childAnnotation(childDeclaration);
    final parentSymbolOnParent = childDeclaration.simpleName;
    if (childAnnotation is BelongsTo) {
      return new _OneToOneRelationship<Parent, Child>(_gateway,
          annotation, childAnnotation).childOf(parentSymbolOnParent, parent, parentRow, _childEntity);
    } else {
      return new _ManyToOneRelationship<Parent, Child>(_gateway,
          annotation, childAnnotation).childOf(parent, _childEntity);
    }
  }

  Future<Parent> belongsTo(Child child, Map childRow, BelongsTo annotation) {
    final parentDeclaration = _parentDeclaration();
    final parentAnnotation = _parentAnnotation(parentDeclaration);
    final childSymbolOnParent = parentDeclaration.simpleName;
    if (parentAnnotation is HasOne) {
      return new _OneToOneRelationship<Parent, Child>(_gateway,
          parentAnnotation, annotation).parentOf(childSymbolOnParent,
          child, childRow, _parentEntity, _childEntity);
    } else {
      return new _OneToManyRelationship<Parent, Child>(_gateway,
          parentAnnotation, annotation).parentOf(child, _parentEntity);
    }
  }

  RepositoryQuery<Child> hasMany(Parent parent,
      HasMany annotation) {
    final childDeclaration = _childDeclaration();
    final childAnnotation = _childAnnotation(childDeclaration);
    final parentSymbolOnParent = childDeclaration.simpleName;
    if (childAnnotation == BelongsTo) {
      return new _OneToManyRelationship<Parent, Child>(_gateway,
          annotation, childAnnotation).childrenOf(parent, _childEntity);
    } else {
      return new _ManyToManyRelationship<Parent, Child>(_gateway,
          annotation, childAnnotation).childrenOf(parent, _childEntity);
    }
  }

  RepositoryQuery<Parent> belongsToMany(Child child,
      BelongsToMany annotation) {
    final parentDeclaration = _parentDeclaration();
    final parentAnnotation = _parentAnnotation(parentDeclaration);
    final childSymbolOnParent = parentDeclaration.simpleName;
    if (parentAnnotation is HasOne) {
      return new _ManyToOneRelationship<Parent, Child>(_gateway,
          parentAnnotation, annotation).parentsOf(child, _parentEntity);
    } else {
      return new _ManyToManyRelationship<Parent, Child>(_gateway,
          parentAnnotation, annotation).parentsOf(child, _parentEntity);
    }
  }
}

class _OneToOneRelationship<Parent extends Model, Child extends Model> {
  final Gateway _gateway;
  final HasOne _parentAnnotation;
  final BelongsTo _childAnnotation;

  _OneToOneRelationship(this._gateway, this._parentAnnotation,
      this._childAnnotation);

  Future<Parent> parentOf(
      Symbol childSymbolOnParent,
      Child child,
      Map childRow,
      ModelEntity<Parent> entity,
      ModelEntity<Child> childEntity) async {
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
    return entity.deserializeRelationships(model, row);
  }

  Future<Child> childOf(Symbol parentSymbolOnChild, Parent parent, Map parentRow,
      ModelEntity<Child> entity) async {
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
    return entity.deserializeRelationships(model, row);
  }
}

class _OneToManyRelationship<Parent extends Model, Child extends Model> {
  final Gateway _gateway;
  final HasMany _parentAnnotation;
  final BelongsTo _childAnnotation;

  _OneToManyRelationship(this._gateway, this._parentAnnotation,
      this._childAnnotation);

  Future<Parent> parentOf(Child child,
      ModelEntity<Parent> entity) {
    throw 'ONE TO MANY';
  }

  RepositoryQuery<Child> childrenOf(Parent parent,
      ModelEntity<Child> entity) {
    throw 'ONE TO MANY';
  }
}

class _ManyToOneRelationship<Parent extends Model, Child extends Model> {
  final Gateway _gateway;
  final HasOne _parentAnnotation;
  final BelongsToMany _childAnnotation;

  _ManyToOneRelationship(this._gateway, this._parentAnnotation,
      this._childAnnotation);

  RepositoryQuery<Parent> parentsOf(Child child,
      ModelEntity<Parent> entity) {
    throw 'MANY TO ONE';
  }

  Future<Child> childOf(Parent parent,
      ModelEntity<Child> entity) {
    throw 'MANY TO ONE';
  }
}

class _ManyToManyRelationship<Parent extends Model, Child extends Model> {
  final Gateway _gateway;
  final HasMany _parentAnnotation;
  final BelongsToMany _childAnnotation;

  _ManyToManyRelationship(this._gateway, this._parentAnnotation,
      this._childAnnotation);

  RepositoryQuery<Parent> parentsOf(Child child,
      ModelEntity<Parent> entity) {
    throw 'MANY TO MANY';
  }

  RepositoryQuery<Child> childrenOf(Parent parent,
      ModelEntity<Child> entity) {
    throw 'MANY TO MANY';
  }
}
