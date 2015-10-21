part of trestle.orm.model;

class Field {
  final String field;

  const Field([this.field]);
}

class _RelationshipAnnotation {
  final String mine;
  final String theirs;
  final String table;

  const _RelationshipAnnotation(this.mine, this.theirs, this.table);
}

class _ManyToManyRelationshipAnnotation extends _RelationshipAnnotation {
  final bool pivot;

  _ManyToManyRelationshipAnnotation(
      this.pivot, String mine, String theirs, String table)
      : super(mine, theirs, table);
}

class HasOne extends _RelationshipAnnotation {
  const HasOne({String mine, String theirs, String table})
      : super(mine, theirs, table);
}

class BelongsTo extends _RelationshipAnnotation {
  const BelongsTo({String mine, String theirs, String table})
      : super(mine, theirs, table);
}

class HasMany extends _ManyToManyRelationshipAnnotation {
  const HasMany({String mine, String theirs, String table, bool pivot})
      : super(pivot, mine, theirs, table);
}

class BelongsToMany extends _ManyToManyRelationshipAnnotation {
  const BelongsToMany({String mine, String theirs, String table, bool pivot})
      : super(pivot, mine, theirs, table);
}

const field = const Field();
const hasOne = const HasOne();
const belongsTo = const BelongsTo();
const hasMany = const HasMany();
const belongsToMany = const BelongsToMany();
