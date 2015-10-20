import 'package:test/test.dart';
import 'package:trestle/trestle.dart';
import 'package:trestle/gateway.dart';
import 'dart:mirrors';
import 'dart:async';

main() {
  Gateway gateway;

  setUp(() {
    gateway = new Gateway(new InMemoryDriver());
  });

  Repository modelRepo(Type model) {
    return new Repository.of(new ModelEntity(reflectType(model)))
      ..connect(gateway);
  }

  Repository dataRepo(Type model) {
    return new Repository.of(new DataStructureEntity(reflectType(model)))
      ..connect(gateway);
  }

  Future seed(String table, List<Map<String, dynamic>> rows) {
    return gateway.table(table).addAll(rows);
  }

  Future expectTable(String table, List<Map<String, dynamic>> rows) async {
    expect(await gateway.table(table).get().toList(), equals(rows));
  }

  test('it has a collection of items', () async {
    await seed('empties', [
      {},
    ]);

    await dataRepo(Empty).save(new Empty());

    await expectTable('empties', [
      {}, {}
    ]);
  });
}

class Empty {}
