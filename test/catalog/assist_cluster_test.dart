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

  test('proposed name is the title-cased stem', () {
    const milkA = CatalogPosition(id: 'a', displayName: 'Молоко Леб 2.5% 1.7л');
    const milkB = CatalogPosition(id: 'b', displayName: 'МОЛОКО ЛЕБ 2,5% 0,93Л');
    expect(proposedClusterName([milkA, milkB]), 'Молоко Леб');
    final cluster = buildUnassignedClusters([milkA, milkB]).single;
    expect(cluster.name, 'Молоко Леб');
    expect(cluster.preview, hasLength(2));
    expect(cluster.hiddenCount, 0);
  });

  test('cluster preview keeps three names and counts the rest', () {
    final positions = [
      for (var i = 0; i < 5; i++) CatalogPosition(id: '$i', displayName: 'Молоко Леб ${i + 1}л'),
    ];
    final cluster = buildUnassignedClusters(positions).single;
    expect(cluster.preview, hasLength(clusterPreviewLimit));
    expect(cluster.hiddenCount, 2);
  });

  test('does not glue two brands that only share the first token', () {
    const a = CatalogPosition(id: 'a', displayName: 'Haribo Goldbaren 100g');
    const b = CatalogPosition(id: 'b', displayName: 'Haribo Roulette 25g');
    final clusters = clusterUnassigned([a, b]);
    expect(clusters.every((cluster) => cluster.length == 1), isTrue);
  });

  test('keeps a bus ticket out of a food cluster', () {
    const milk = CatalogPosition(id: 'm', displayName: 'Молоко 1л');
    const ticket = CatalogPosition(id: 't', displayName: 'Bulevar Cara Lazara-Šekspirova - Terminal /ком');
    final clusters = clusterUnassigned([milk, ticket]);
    expect(clusters, hasLength(2));
  });

  test('hard-caps a cluster so 40 milks do not become one product', () {
    final positions = [
      for (var i = 0; i < 40; i++) CatalogPosition(id: '$i', displayName: 'Молоко $i 1л'),
    ];
    expect(clusterUnassigned(positions).every((cluster) => cluster.length <= assistClusterLimit), isTrue);
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
