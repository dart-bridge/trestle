part of trestle.orm;

class ParentChildRelationship<Parent extends Model, Child extends Model> {
  final Gateway _gateway;
  final ClassMirror _parentMirror;
  final ClassMirror _childMirror;
  final MapsFieldsToModel<Parent> _parentMapper;
  final MapsFieldsToModel<Child> _childMapper;

  ParentChildRelationship(Gateway gateway, {Type parent, Type child})
      : _gateway = gateway,
        _parentMirror = reflectType(parent ?? Parent),
        _childMirror = reflectType(child ?? Child),
        _parentMapper = new MapsFieldsToModel<Parent>(
            gateway, reflectType(parent ?? Parent)),
        _childMapper = new MapsFieldsToModel<Child>(
            gateway, reflectType(child ?? Child));

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
          annotation, childAnnotation).childOf(parentSymbolOnParent, parent, parentRow, _childMapper);
    } else {
      return new _ManyToOneRelationship<Parent, Child>(_gateway,
          annotation, childAnnotation).childOf(parent, _childMapper);
    }
  }

  Future<Parent> belongsTo(Child child, Map childRow, BelongsTo annotation) {
    final parentDeclaration = _parentDeclaration();
    final parentAnnotation = _parentAnnotation(parentDeclaration);
    final childSymbolOnParent = parentDeclaration.simpleName;
    if (parentAnnotation is HasOne) {
      return new _OneToOneRelationship<Parent, Child>(_gateway,
          parentAnnotation, annotation).parentOf(childSymbolOnParent,
          child, childRow, _parentMapper, _childMapper);
    } else {
      return new _OneToManyRelationship<Parent, Child>(_gateway,
          parentAnnotation, annotation).parentOf(child, _parentMapper);
    }
  }

  RepositoryQuery<Child> hasMany(Parent parent,
      HasMany annotation) {
    final childDeclaration = _childDeclaration();
    final childAnnotation = _childAnnotation(childDeclaration);
//    final parentSymbolOnParent = childDeclaration.simpleName;
    if (childAnnotation is BelongsTo) {
      return new _OneToManyRelationship<Parent, Child>(_gateway,
          annotation, childAnnotation).childrenOf(parent, _childMapper);
    } else {
      return new _ManyToManyRelationship<Parent, Child>(_gateway,
          annotation, childAnnotation).childrenOf(parent, _childMapper);
    }
  }

  RepositoryQuery<Parent> belongsToMany(Child child,
      BelongsToMany annotation) {
    final parentDeclaration = _parentDeclaration();
    final parentAnnotation = _parentAnnotation(parentDeclaration);
//    final childSymbolOnParent = parentDeclaration.simpleName;
    if (parentAnnotation is HasOne) {
      return new _ManyToOneRelationship<Parent, Child>(_gateway,
          parentAnnotation, annotation).parentsOf(child, _parentMapper);
    } else {
      return new _ManyToManyRelationship<Parent, Child>(_gateway,
          parentAnnotation, annotation).parentsOf(child, _parentMapper);
    }
  }
}
