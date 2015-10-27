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

class HasOne extends RelationshipAnnotation {
  const HasOne({String mine, String theirs, String table})
      : super(mine, theirs, table);
}

class BelongsTo extends RelationshipAnnotation {
  const BelongsTo({String mine, String theirs, String table})
      : super(mine, theirs, table);
}

class HasMany extends RelationshipAnnotation {
  const HasMany({String mine, String theirs, String table})
      : super(mine, theirs, table);
}

class BelongsToMany extends RelationshipAnnotation {
  const BelongsToMany({String mine, String theirs, String table})
      : super(mine, theirs, table);
}

const field = const Field();
const hasOne = const HasOne();
const belongsTo = const BelongsTo();
const hasMany = const HasMany();
const belongsToMany = const BelongsToMany();
