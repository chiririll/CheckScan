import 'dart:math' as math;

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
      curr[j + 1] = math.min(math.min(prev[j + 1] + 1, curr[j] + 1), prev[j] + cost);
    }
    prev.setAll(0, curr);
  }
  return prev[b.length];
}

/// Edit distance as a share of the longer string: 0 = equal, 1 = nothing shared.
double editRatio(String a, String b, [int? distance]) {
  final longest = math.max(a.length, b.length);
  if (longest == 0) return 0;
  return (distance ?? levenshtein(a, b)) / longest;
}

/// Close when the distance is at most [maxEdits] or at most [maxRatio] of the longer string.
bool isEditClose(String a, String b, {required int maxEdits, required double maxRatio}) {
  final distance = levenshtein(a, b);
  return distance <= maxEdits || editRatio(a, b, distance) <= maxRatio;
}
