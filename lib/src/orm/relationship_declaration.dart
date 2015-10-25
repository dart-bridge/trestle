part of trestle.orm;

class RelationshipDeclaration<Parent extends Model, Child extends Model> {
  ParentChildRelationship<Parent, Child> _relationship;
  VariableMirror field;
  VariableMirror foreignField;
}
