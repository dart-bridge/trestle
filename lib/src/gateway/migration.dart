part of trestle.gateway;

abstract class Migration {
  Future run(Gateway gateway);

  Future rollback(Gateway gateway);
}
