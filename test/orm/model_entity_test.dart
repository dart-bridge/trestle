import 'package:test/test.dart';
import 'package:trestle/trestle.dart';
import 'package:trestle/gateway.dart';
import 'dart:mirrors';

main() {
  MapsFieldsToModel<Article> articleEntity;

  setUp(() {
    articleEntity = new ModelEntity<Article>(
        new Gateway(new InMemoryDriver()),
        reflectType(Article));
  });

  test('it uses the name of the model for choosing table name', () {
    expect(articleEntity.table, equals('articles'));
  });

  test('it applies a map to fields', () async {
    final article = await articleEntity.deserialize({'id': 1, 'title': 'x'});
    expect(article.id, equals(1));
    expect(article.title, equals('x'));
  });

  test('it serializes a model', () {
    final article = new Article()
      ..id = 2
      ..title = 'y';
    expect(articleEntity.serialize(article), allOf(
        containsPair('id', 2),
        containsPair('title', 'y')
    ));
  });
}

class Article extends Model {
  @field String title;
}
