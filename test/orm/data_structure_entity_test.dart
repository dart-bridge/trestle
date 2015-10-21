import 'package:test/test.dart';
import 'package:trestle/trestle.dart';
import 'dart:mirrors';

main() {
  Entity<Article> articleEntity;

  setUp(() {
    articleEntity = new DataStructureEntity<Article>(reflectType(Article));
  });

  test('it uses the name of the model for choosing table name', () {
    expect(articleEntity.table, equals('articles'));
  });

  test('it applies a map to fields', () {
    final article = articleEntity.deserialize({'title': 'x'});
    expect(article.title, equals('x'));
  });

  test('it serializes a model', () {
    final article = new Article()
      ..title = 'y';
    expect(articleEntity.serialize(article), equals({
      'title': 'y'
    }));
  });
}

class Article {
  String title;
}
