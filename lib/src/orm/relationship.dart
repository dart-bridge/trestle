part of trestle.orm;

class Relationship<Parent extends Model, Child extends Model> {
  final Gateway _gateway;
  final ClassMirror _parentMirror;
  final ClassMirror _childMirror;
  final ModelEntity<Parent> _parentEntity;
  final ModelEntity<Child> _childEntity;

  Relationship(Gateway gateway, {Type parent, Type child})
      : _gateway = gateway,
        _parentMirror = reflectType(parent ?? Parent),
        _childMirror = reflectType(child ?? Child),
        _parentEntity = new ModelEntity(gateway, reflectType(parent ?? Parent)),
        _childEntity = new ModelEntity(gateway, reflectType(child ?? Child));

  RelationshipAnnotation _parentAnnotation() {
    final targetType = _childMirror;
    final targetOwner = _parentMirror;
    final targetAnnotations = [HasOne, HasMany];
    return _relationshipAnnotation(targetType, targetOwner, targetAnnotations);
  }

  RelationshipAnnotation _childAnnotation() {
    final targetType = _parentMirror;
    final targetOwner = _childMirror;
    final targetAnnotations = [BelongsTo, BelongsToMany];
    return _relationshipAnnotation(targetType, targetOwner, targetAnnotations);
  }

  RelationshipAnnotation _relationshipAnnotation(ClassMirror targetType,
      ClassMirror targetOwner,
      List<Type> targetAnnotations) {
    return targetOwner.instanceMembers.values
        .where((m) => m.isGetter)
        .where((m) =>
        _assignableToAnyRelationshipType(m.returnType, targetType))
        .map((m) => (m.owner as ClassMirror).declarations[m.simpleName])
        .map((m) => m.metadata.firstWhere((i) =>
        _assignableToAny(i.type, targetAnnotations)))
        .first.reflectee;
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

  Future<Child> hasOne(Map<String, dynamic> parent, HasOne annotation) {
    final childAnnotation = _childAnnotation();
    if (childAnnotation is BelongsTo) {
      return new _OneToOneRelationship<Parent, Child>(_gateway,
          annotation, childAnnotation).childOf(parent, _childEntity);
    } else {
      return new _ManyToOneRelationship<Parent, Child>(_gateway,
          annotation, childAnnotation).childOf(parent, _childEntity);
    }
  }

  Future<Parent> belongsTo(Map<String, dynamic> child, BelongsTo annotation) {
    final parentAnnotation = _parentAnnotation();
    if (parentAnnotation is HasOne) {
      return new _OneToOneRelationship<Parent, Child>(_gateway,
          parentAnnotation, annotation).parentOf(
          child, _parentEntity, _childEntity);
    } else {
      return new _OneToManyRelationship<Parent, Child>(_gateway,
          parentAnnotation, annotation).parentOf(child, _parentEntity);
    }
  }

  RepositoryQuery<Child> hasMany(Map<String, dynamic> parent,
      HasMany annotation) {
    final childAnnotation = _childAnnotation();
    if (childAnnotation == BelongsTo) {
      return new _OneToManyRelationship<Parent, Child>(_gateway,
          annotation, childAnnotation).childrenOf(parent, _childEntity);
    } else {
      return new _ManyToManyRelationship<Parent, Child>(_gateway,
          annotation, childAnnotation).childrenOf(parent, _childEntity);
    }
  }

  RepositoryQuery<Parent> belongsToMany(Map<String, dynamic> child,
      BelongsToMany annotation) {
    final parentAnnotation = _parentAnnotation();
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

  Future<Parent> parentOf(Map<String, dynamic> child,
      ModelEntity<Parent> entity, ModelEntity<Child> childEntity) async {
    final parentId = _childAnnotation.mine
        ?? _parentAnnotation.theirs
        ?? childEntity.foreignKey;
    final childId = _childAnnotation.theirs
        ?? _parentAnnotation.mine
        ?? 'id';
    final Map row = await _gateway.table(entity.table)
        .where((parent) => parent[parentId] == child[childId])
        .first().catchError((_) => null);
    if (row == null) return null;
    row[parentId] = null;
    return entity.deserialize(row);
  }

  Future<Child> childOf(Map<String, dynamic> parent,
      ModelEntity<Child> entity) async {
    final childId = _parentAnnotation.mine
        ?? _childAnnotation.theirs
        ?? 'id';
    final parentId = _parentAnnotation.theirs
        ?? _childAnnotation.mine
        ?? entity.foreignKey;
    final Map row = await _gateway.table(entity.table)
        .where((child) => child[childId] == parent[parentId])
        .first().catchError((_) => null);
    if (row == null) return null;
    parent[parentId] = null;
    return entity.deserialize(row);
  }
}

class _OneToManyRelationship<Parent extends Model, Child extends Model> {
  final Gateway _gateway;
  final HasMany _parentAnnotation;
  final BelongsTo _childAnnotation;

  _OneToManyRelationship(this._gateway, this._parentAnnotation,
      this._childAnnotation);

  Future<Parent> parentOf(Map<String, dynamic> child,
      ModelEntity<Parent> entity) {
    throw 'ONE TO MANY';
  }

  RepositoryQuery<Child> childrenOf(Map<String, dynamic> parent,
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

  RepositoryQuery<Parent> parentsOf(Map<String, dynamic> child,
      ModelEntity<Parent> entity) {
    throw 'MANY TO ONE';
  }

  Future<Child> childOf(Map<String, dynamic> parent,
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

  RepositoryQuery<Parent> parentsOf(Map<String, dynamic> child,
      ModelEntity<Parent> entity) {
    throw 'MANY TO MANY';
  }

  RepositoryQuery<Child> childrenOf(Map<String, dynamic> parent,
      ModelEntity<Child> entity) {
    throw 'MANY TO MANY';
  }
}
