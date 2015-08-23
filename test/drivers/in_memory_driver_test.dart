import 'package:test/test.dart';
import 'package:trestle/src/gateway/gateway.dart';
import 'package:trestle/src/drivers/drivers.dart';
import 'dart:async';

main() {
  Gateway gateway;

  setUp(() {
    gateway = new Gateway(new InMemoryDriver());
  });

  Query query() => gateway.table('test');

  Future assertTableContents(Iterable expectedContents) async {
    expect(await query().get().toList(), equals(expectedContents));
  }

  Future assertQuery(Query query, Iterable expected) async {
    expect(await query.get().toList(), equals(expected));
  }

  group('CRUD', () {
    test('it contains tables and rows', () async {
      await assertTableContents([]);
      await query().add({});
      await assertTableContents([{}]);
    });

    test('it can add multiple', () async {
      await query().addAll([{}, {}]);
      await assertTableContents([{}, {}]);
    });

    test('it can list only some of the fields', () async {
      await query().add({'x': 1, 'y': 2});
      expect(await query().get(['x']).toList(), equals([{'x': 1}]));
    });

    test('it can update rows', () async {
      await query().add({'x': 1, 'y': 2});
      await query().update({'x': 2});
      await assertTableContents([{'x': 2, 'y': 2}]);
    });

    test('it can delete rows', () async {
      await query().addAll([{}, {}, {}]);
      await query().delete();
      await assertTableContents([]);
    });
  });

  group('aggregates', () {
    test('it can count the rows in a table', () async {
      expect(await query().count(), equals(0));
      await query().add({});
      expect(await query().count(), equals(1));
    });

    test('it can get the sum of all the rows for a field', () async {
      await query().addAll([{'x': 2}, {'x': 5}]);
      expect(await query().sum('x'), equals(7));
    });

    test('it can get the average of all the rows for a field', () async {
      await query().addAll([{'x': 2}, {'x': 5}]);
      expect(await query().average('x'), equals(3.5));
    });

    test('it can get the minimum and maximum values of a field across all rows', () async {
      await query().addAll([{'x': 2}, {'x': 5}]);
      expect(await query().min('x'), equals(2));
      expect(await query().max('x'), equals(5));
    });
  });

  group('constraints', () {
    test('where constraint', () async {
      await query().addAll([{'x': 1}, {'x': 2}, {'x': 3}]);

      await assertQuery(
          query().where((row) => row.x == 1),
          [{'x': 1}]);

      await assertQuery(
          query().where((row) => row.x > 1),
          [{'x': 2}, {'x': 3}]);
    });

    test('find is a helper method for id match', () async {
      await query().addAll([{'id': 1}, {'id': 2}]);
      expect(await query().find(2).first(), equals({'id': 2}));
    });

    test('limit constraint', () async {
      await query().addAll([{'x': 1}, {'x': 2}, {'x': 3}]);

      await assertQuery(
          query().limit(2),
          [{'x': 1}, {'x': 2}]);
    });

    test('offset constraint', () async {
      await query().addAll([{'x': 1}, {'x': 2}, {'x': 3}]);

      await assertQuery(
          query().offset(1),
          [{'x': 2}, {'x': 3}]);
    });

    test('sortBy constraint', () async {
      var a2 = {'123': 2, 'abc': 'a'};
      var b1 = {'123': 1, 'abc': 'b'};
      var c3 = {'123': 3, 'abc': 'c'};

      await query().addAll([a2, c3, b1]);

      await assertQuery(
          query().sortBy('123'), [b1, a2, c3]);
      await assertQuery(
          query().sortBy('123', 'desc'), [c3, a2, b1]);
      await assertQuery(
          query().sortBy('abc'), [a2, b1, c3]);
      await assertQuery(
          query().sortBy('abc', 'desc'), [c3, b1, a2]);
    });

    test('distinct constraint', () async {
      await query().addAll([{'x': 1}, {'x': 2}, {'x': 1}]);
      await assertQuery(
          query().distinct(),
          [{'x': 1}, {'x': 2}]);
    });

    test('join', () async {
      await gateway.table('firsts').addAll([
        {'id': 1, 'x': 'a', 'second_id': 1},
        {'id': 2, 'x': 'b', 'second_id': 2},
        {'id': 3, 'x': 'c', 'second_id': 1},
      ]);
      await gateway.table('seconds').addAll([
        {'id': 1, 'y': 'a'},
        {'id': 2, 'y': 'b'},
      ]);
      await assertQuery(
          gateway.table('firsts')
          .join('seconds', (first, second) => first.secondId == second.id),
          [
            {'id': 1, 'x': 'a', 'second_id': 1, 'y': 'a'},
            {'id': 2, 'x': 'b', 'second_id': 2, 'y': 'b'},
            {'id': 3, 'x': 'c', 'second_id': 1, 'y': 'a'},
          ]);
    });
  });
}