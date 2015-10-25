import 'package:test/test.dart';
import 'package:trestle/trestle.dart';
import 'dart:mirrors';

main() {
  MapsFieldsToModel<Article> articleEntity;

  setUp(() {
    articleEntity = new DataStructureEntity<Article>(reflectType(Article));
  });

  test('it uses the name of the model for choosing table name', () {
    expect(articleEntity.table, equals('articles'));
  });

  test('it applies a map to fields', () async {
    final article = await articleEntity.deserialize({'title': 'x'});
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
