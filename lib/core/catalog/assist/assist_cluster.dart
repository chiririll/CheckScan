import 'dart:math' as math;

import '../model/catalog_position.dart';
import '../text/name_stem.dart';
import '../text/service_name.dart';
import '../text/similarity.dart';

const assistClusterLimit = 24;
const clusterPreviewLimit = 3;

class UnassignedCluster {
  const UnassignedCluster({required this.name, required this.positions});

  final String name;
  final List<CatalogPosition> positions;

  List<CatalogPosition> get preview =>
      positions.length <= clusterPreviewLimit ? positions : positions.sublist(0, clusterPreviewLimit);

  int get hiddenCount =>
      positions.length <= clusterPreviewLimit ? 0 : positions.length - clusterPreviewLimit;
}

bool stemsSimilar(String a, String b) {
  if (a.isEmpty || b.isEmpty) return false;
  if (a == b) return true;
  if (isEditClose(a, b, maxEdits: 3, maxRatio: 0.25)) return true;
  final left = stemTokens(a);
  final right = stemTokens(b);
  return left.isNotEmpty && right.isNotEmpty && left.first == right.first && tokensCompatible(left, right);
}

bool tokensCompatible(List<String> left, List<String> right) {
  if (left.isEmpty || right.isEmpty) return false;
  if (!_tokenSimilar(left.first, right.first)) return false;
  if (left.length == 1 || right.length == 1) return true;
  return _tokenSimilar(left[1], right[1]);
}

bool _tokenSimilar(String a, String b) => a == b || isEditClose(a, b, maxEdits: 2, maxRatio: 0.25);

bool shouldCluster(String stemA, String stemB) {
  if (stemA.isEmpty || stemB.isEmpty) return false;
  return tokensCompatible(stemTokens(stemA), stemTokens(stemB));
}

String titleCaseStem(String stem) {
  return [
    for (final word in stem.split(' '))
      if (word.isNotEmpty) '${word[0].toUpperCase()}${word.substring(1)}',
  ].join(' ');
}

String proposedClusterName(List<CatalogPosition> cluster) {
  if (cluster.isEmpty) return '';
  final counts = <String, int>{};
  for (final position in cluster) {
    final stem = itemNameStem(position.displayName);
    if (stem.isEmpty) continue;
    counts[stem] = (counts[stem] ?? 0) + 1;
  }
  if (counts.isEmpty) return cluster.first.displayName;
  final ranked = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      if (byCount != 0) return byCount;
      return a.key.length.compareTo(b.key.length);
    });
  return titleCaseStem(ranked.first.key);
}

List<UnassignedCluster> buildUnassignedClusters(List<CatalogPosition> positions, {Set<String> ignoreIds = const {}}) {
  return [
    for (final group in clusterUnassigned(positions, ignoreIds: ignoreIds))
      UnassignedCluster(name: proposedClusterName(group), positions: group),
  ];
}

List<List<CatalogPosition>> clusterUnassigned(List<CatalogPosition> positions, {Set<String> ignoreIds = const {}}) {
  if (positions.isEmpty) return const [];
  final active = [for (final position in positions) if (!ignoreIds.contains(position.id)) position];
  final ignored = [for (final position in positions) if (ignoreIds.contains(position.id)) position];
  final goods = [for (final position in active) if (!looksLikeService(position.displayName)) position];
  final services = [for (final position in active) if (looksLikeService(position.displayName)) position];
  return [
    ..._clusterPool(goods),
    ..._clusterPool(services),
    for (final position in ignored) [position],
  ];
}

List<List<CatalogPosition>> _clusterPool(List<CatalogPosition> positions) {
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
      if (shouldCluster(stems[i], stems[j])) union(i, j);
    }
  }

  final groups = <int, List<CatalogPosition>>{};
  for (var i = 0; i < positions.length; i++) {
    groups.putIfAbsent(find(i), () => []).add(positions[i]);
  }
  final clusters = <List<CatalogPosition>>[];
  for (final group in groups.values) {
    if (group.length <= assistClusterLimit) {
      clusters.add(group);
      continue;
    }
    for (var offset = 0; offset < group.length; offset += assistClusterLimit) {
      clusters.add(group.sublist(offset, math.min(offset + assistClusterLimit, group.length)));
    }
  }
  clusters.sort((a, b) => b.length.compareTo(a.length));
  return clusters;
}
