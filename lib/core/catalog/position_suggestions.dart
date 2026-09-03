import 'catalog_position.dart';
import 'name_normalizer.dart';
import 'unit_parser.dart';

List<CatalogPosition> suggestPositionMerges(
  String raw, {
  required List<CatalogPosition> positions,
  String? excludeId,
  int limit = 5,
}) {
  final norm = normalizeItemName(raw);
  if (norm.isEmpty) return const [];
  final parsed = parseItemUnit(raw);
  final scored = <({CatalogPosition position, int score})>[];
  for (final position in positions) {
    if (position.id == excludeId) continue;
    final otherNorm = normalizeItemName(position.displayName);
    if (otherNorm.isEmpty) continue;
    if (otherNorm == norm) {
      scored.add((position: position, score: 0));
      continue;
    }
    final otherUnit = parseItemUnit(position.displayName);
    if (!_compatibleUnits(parsed, otherUnit)) continue;
    final dist = levenshtein(norm, otherNorm);
    final maxLen = norm.length > otherNorm.length ? norm.length : otherNorm.length;
    if (dist <= 2 || dist / maxLen <= 0.15) {
      scored.add((position: position, score: dist));
    }
  }
  scored.sort((a, b) => a.score.compareTo(b.score));
  return [for (final entry in scored.take(limit)) entry.position];
}

bool _compatibleUnits(ParsedUnit? a, ParsedUnit? b) {
  if (a == null || b == null) return true;
  if (a.unit != b.unit) return false;
  if (a.size != null && b.size != null && a.size != b.size) return false;
  return true;
}

int levenshtein(String a, String b) {
  if (a == b) return 0;
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;
  final prev = List<int>.generate(b.length + 1, (i) => i);
  final curr = List<int>.filled(b.length + 1, 0);
  for (var i = 0; i < a.length; i++) {
    curr[0] = i + 1;
    for (var j = 0; j < b.length; j++) {
      final cost = a[i] == b[j] ? 0 : 1;
      final del = prev[j + 1] + 1;
      final ins = curr[j] + 1;
      final sub = prev[j] + cost;
      curr[j + 1] = del < ins ? (del < sub ? del : sub) : (ins < sub ? ins : sub);
    }
    for (var j = 0; j <= b.length; j++) {
      prev[j] = curr[j];
    }
  }
  return prev[b.length];
}
