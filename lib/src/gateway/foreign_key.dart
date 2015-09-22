part of trestle.gateway;

abstract class ForeignKey {
  ForeignKey onDelete(String response);

  ForeignKey onUpdate(String response);
}
