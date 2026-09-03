import 'package:checkscan/core/catalog/assist_cluster.dart';
import 'package:checkscan/core/catalog/catalog_position.dart';
import 'package:checkscan/core/catalog/catalog_product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('groups the same milk across pack sizes and keeps bread apart', () {
    const milkA = CatalogPosition(id: 'a', displayName: 'Молоко Леб 2.5% 1.7л');
    const milkB = CatalogPosition(id: 'b', displayName: 'МОЛОКО ЛЕБ 2,5% 0,93Л');
    const bread = CatalogPosition(id: 'c', displayName: 'Хлеб дарницкий 0,6кг');
    const kefir = CatalogPosition(id: 'd', displayName: 'Кефир 900мл');
    final clusters = clusterUnassigned([milkA, bread, milkB, kefir]);
    expect(clusters.first.map((e) => e.id), containsAll(['a', 'b']));
    expect(clusters.any((cluster) => cluster.length == 1 && cluster.single.id == 'c'), isTrue);
    expect(clusters.any((cluster) => cluster.length == 1 && cluster.single.id == 'd'), isTrue);
  });

  test('caps a huge cluster at the batch limit', () {
    final positions = [
      for (var i = 0; i < 40; i++) CatalogPosition(id: '$i', displayName: 'Молоко $i 1л'),
    ];
    expect(nextAssistBatch(positions), hasLength(assistBatchLimit));
  });

  test('cluster peers ignore pack size and stay on the same product', () {
    const milkA = CatalogPosition(id: 'a', displayName: 'Молоко Леб 2.5% 1.7л');
    const milkB = CatalogPosition(id: 'b', displayName: 'МОЛОКО ЛЕБ 2,5% 0,93Л');
    const bread = CatalogPosition(id: 'c', displayName: 'Хлеб дарницкий 0,6кг');
    expect(clusterPeers(milkA, [milkA, milkB, bread]).single.id, 'b');
    expect(clusterPeers(milkA, [milkA, milkB.copyWith(productId: 'other')]), isEmpty);
  });

  test('picks similar products by stem', () {
    const batch = [CatalogPosition(id: 'p', displayName: 'Молоко Леб 2.5% 1.7л')];
    const products = [
      CatalogProduct(id: 'milk', name: 'Молоко'),
      CatalogProduct(id: 'bread', name: 'Хлеб'),
    ];
    expect(similarProductsFor(batch, products).single.id, 'milk');
  });
}
