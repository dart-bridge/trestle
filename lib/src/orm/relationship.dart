part of trestle.orm;

class Relationship<Parent extends Model, Child extends Model> {
  final ClassMirror _parentMirror;
  final ClassMirror _childMirror;

  Relationship({Type parent, Type child})
      : _parentMirror = reflectType(parent ?? Parent),
        _childMirror = reflectType(child ?? Child);

  RelationshipAnnotation _parentAnnotation() {}

  RelationshipAnnotation _childAnnotation() {}

  Future<Child> hasOne(Parent parent, HasOne annotation) {
    final childAnnotation = _childAnnotation();
    if (childAnnotation is BelongsTo) {
      return new _OneToOneRelationship<Parent, Child>(
          annotation, childAnnotation).childOf(parent);
    } else {
      return new _ManyToOneRelationship<Parent, Child>(
          annotation, childAnnotation).childOf(parent);
    }
  }

  Future<Parent> belongsTo(Child child, BelongsTo annotation) {
    final parentAnnotation = _parentAnnotation();
    if (parentAnnotation is HasOne) {
      return new _OneToOneRelationship<Parent, Child>(
          parentAnnotation, annotation).parentOf(child);
    } else {
      return new _OneToManyRelationship<Parent, Child>(
          parentAnnotation, annotation).parentOf(child);
    }
  }

  RepositoryQuery<Child> hasMany(Parent parent, HasMany annotation) {
    final childAnnotation = _childAnnotation();
    if (childAnnotation == BelongsTo) {
      return new _OneToManyRelationship<Parent, Child>(
          annotation, childAnnotation).childrenOf(parent);
    } else {
      return new _ManyToManyRelationship<Parent, Child>(
          annotation, childAnnotation).childrenOf(parent);
    }
  }

  RepositoryQuery<Parent> belongsToMany(Child child, BelongsToMany annotation) {
    final parentAnnotation = _parentAnnotation();
    if (parentAnnotation is HasOne) {
      return new _ManyToOneRelationship<Parent, Child>(
          parentAnnotation, annotation).parentsOf(child);
    } else {
      return new _ManyToManyRelationship<Parent, Child>(
          parentAnnotation, annotation).parentsOf(child);
    }
  }
}

class _OneToOneRelationship<Parent, Child> {
  final HasOne _parentAnnotation;
  final BelongsTo _childAnnotation;

  _OneToOneRelationship(this._parentAnnotation, this._childAnnotation);

  Future<Parent> parentOf(Child child) {
    throw 'ONE TO ONE';
  }

  Future<Child> childOf(Parent parent) {
    throw 'ONE TO ONE';
  }
}

class _OneToManyRelationship<Parent, Child> {
  final HasMany _parentAnnotation;
  final BelongsTo _childAnnotation;

  _OneToManyRelationship(this._parentAnnotation, this._childAnnotation);

  Future<Parent> parentOf(Child child) {
    throw 'ONE TO MANY';
  }

  RepositoryQuery<Child> childrenOf(Parent parent) {
    throw 'ONE TO MANY';
  }
}

class _ManyToOneRelationship<Parent, Child> {
  final HasOne _parentAnnotation;
  final BelongsToMany _childAnnotation;

  _ManyToOneRelationship(this._parentAnnotation, this._childAnnotation);

  RepositoryQuery<Parent> parentsOf(Child child) {
    throw 'MANY TO ONE';
  }

  Future<Child> childOf(Parent parent) {
    throw 'MANY TO ONE';
  }
}

class _ManyToManyRelationship<Parent, Child> {
  final HasMany _parentAnnotation;
  final BelongsToMany _childAnnotation;

  _ManyToManyRelationship(this._parentAnnotation, this._childAnnotation);

  RepositoryQuery<Parent> parentsOf(Child child) {
    throw 'MANY TO MANY';
  }

  RepositoryQuery<Child> childrenOf(Parent parent) {
    throw 'MANY TO MANY';
  }
}
