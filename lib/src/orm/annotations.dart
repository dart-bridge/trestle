part of trestle.orm.model;

class Field {
  final String field;

  const Field([this.field]);
}

class RelationshipAnnotation {
  final String mine;
  final String theirs;
  final String table;

  const RelationshipAnnotation(this.mine, this.theirs, this.table);
}

class _ManyToManyRelationshipAnnotation extends RelationshipAnnotation {
  final bool pivot;

  const _ManyToManyRelationshipAnnotation(
      this.pivot, String mine, String theirs, String table)
      : super(mine, theirs, table);
}

class HasOne extends RelationshipAnnotation {
  const HasOne({String mine, String theirs, String table})
      : super(mine, theirs, table);
}

class BelongsTo extends RelationshipAnnotation {
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
