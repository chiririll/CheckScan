import 'catalog_position.dart';
import 'catalog_product.dart';
import 'name_stem.dart';
import 'position_suggestions.dart';

const assistBatchLimit = 30;

bool stemsSimilar(String a, String b) {
  if (a.isEmpty || b.isEmpty) return false;
  if (a == b) return true;
  final dist = levenshtein(a, b);
  final maxLen = a.length > b.length ? a.length : b.length;
  if (dist <= 3 || dist / maxLen <= 0.25) return true;
  final left = stemTokens(a);
  final right = stemTokens(b);
  return left.isNotEmpty && right.isNotEmpty && left.first == right.first;
}

List<List<CatalogPosition>> clusterUnassigned(List<CatalogPosition> positions) {
  if (positions.isEmpty) return const [];
  final stems = [for (final position in positions) itemNameStem(position.displayName)];
  final parent = List<int>.generate(positions.length, (i) => i);

  int find(int i) {
    while (parent[i] != i) {
      parent[i] = parent[parent[i]];
      i = parent[i];
    }
    return i;
  }

  void union(int a, int b) {
    final ra = find(a);
    final rb = find(b);
    if (ra != rb) parent[rb] = ra;
  }

  for (var i = 0; i < positions.length; i++) {
    for (var j = i + 1; j < positions.length; j++) {
      if (stemsSimilar(stems[i], stems[j])) union(i, j);
    }
  }

  final groups = <int, List<CatalogPosition>>{};
  for (var i = 0; i < positions.length; i++) {
    groups.putIfAbsent(find(i), () => []).add(positions[i]);
  }
  final clusters = groups.values.toList()..sort((a, b) => b.length.compareTo(a.length));
  return clusters;
}

List<CatalogPosition> nextAssistBatch(List<CatalogPosition> unassigned) {
  final clusters = clusterUnassigned(unassigned);
  if (clusters.isEmpty) return const [];
  final first = clusters.first;
  if (first.length <= assistBatchLimit) return first;
  return first.sublist(0, assistBatchLimit);
}

List<CatalogProduct> similarProductsFor(List<CatalogPosition> batch, List<CatalogProduct> products) {
  final stems = {for (final position in batch) itemNameStem(position.displayName)}.difference({''});
  return [
    for (final product in products)
      if (stems.any((stem) => stemsSimilar(stem, itemNameStem(product.name)))) product,
  ];
}
