import 'dart:math' as math;

import '../model/catalog_position.dart';
import '../text/name_normalizer.dart';
import '../text/similarity.dart';
import 'assist_draft.dart';
import 'assist_log.dart';
import 'assist_parse.dart';

/// Minimum similarity to attach a parsed line to an unassigned position.
///
/// Normalized equals score 1. A shortened cashier string that still shares
/// its distinctive tokens typically lands in 0.65–0.85. Unrelated products
/// stay below ~0.4. 0.60 keeps OCR and spacing mismatches and rejects
/// accidental attachments.
const assistMatchMinConfidence = 0.60;

class AssistLineMatch {
  const AssistLineMatch({required this.position, required this.confidence});

  final CatalogPosition position;
  final double confidence;
}

class _Claim {
  const _Claim({
    required this.groupIndex,
    required this.rawLine,
    required this.position,
    required this.confidence,
  });

  final int groupIndex;
  final String rawLine;
  final CatalogPosition position;
  final double confidence;
}

/// Leading cashier / catalog id, with or without a following name.
/// Does not rewrite the stored line — only used to claim a position.
final _leadingId = RegExp(r'^(\S+?)\s*[:\-–](?:\s+|$)');
final _nameAfterId = RegExp(r'^\S+?\s*[:\-–]\s*(.+)$');
final _firstToken = RegExp(r'^(\S+)(?:\s+|$)');

AssistParseResult reviewAssistReply(String raw, List<CatalogPosition> unassigned) {
  assistLog('review rawLen=${raw.length} unassigned=${unassigned.length}');
  if (raw.trim().isEmpty) {
    assistLog('fail AssistParseError.empty / assistErrorEmpty');
    return const AssistParseResult.fail(AssistParseError.empty);
  }
  late final AssistParsedReply parsed;
  try {
    parsed = parseAssistReply(raw);
  } catch (error) {
    assistLog('parse threw: $error → AssistParseError.noProducts / assistErrorNoProducts');
    return const AssistParseResult.fail(AssistParseError.noProducts);
  }
  if (parsed.groups.isEmpty) {
    assistLog('fail AssistParseError.noProducts / assistErrorNoProducts');
    return const AssistParseResult.fail(AssistParseError.noProducts);
  }
  final draft = matchAssistGroups(parsed.groups, unassigned);
  final merged = parsed.orphans.isEmpty
      ? draft
      : AssistDraft(
          products: draft.products,
          unmatched: [
            ...draft.unmatched,
            for (final line in parsed.orphans) AssistUnmatchedLine(raw: line),
          ],
        );
  if (merged.isEmpty) {
    assistLog('fail AssistParseError.nothingToApply / assistErrorNothing');
    return const AssistParseResult.fail(AssistParseError.nothingToApply);
  }
  final assigned = [for (final product in merged.products) ...product.positions].length;
  assistLog(
    'review ok products=${merged.products.length} assigned=$assigned '
    'unmatched=${merged.unmatched.length} canApply=${merged.canApply}',
  );
  return AssistParseResult.ok(merged);
}

AssistDraft matchAssistGroups(
  List<AssistParsedGroup> groups,
  List<CatalogPosition> unassigned, {
  double minConfidence = assistMatchMinConfidence,
}) {
  final knownIds = {for (final position in unassigned) position.id};
  final claims = <_Claim>[];
  final unmatched = <AssistUnmatchedLine>[];

  for (var i = 0; i < groups.length; i++) {
    for (final line in groups[i].lines) {
      final hit = matchAssistLine(line, unassigned, knownIds: knownIds);
      if (hit == null || hit.confidence < minConfidence) {
        unmatched.add(AssistUnmatchedLine(raw: line));
      } else {
        claims.add(_Claim(groupIndex: i, rawLine: line, position: hit.position, confidence: hit.confidence));
      }
    }
  }

  claims.sort((a, b) {
    final byScore = b.confidence.compareTo(a.confidence);
    if (byScore != 0) return byScore;
    return b.rawLine.length.compareTo(a.rawLine.length);
  });

  final taken = <String>{};
  final byGroup = <int, List<AssistMatchedPosition>>{};
  for (final claim in claims) {
    if (taken.contains(claim.position.id)) {
      unmatched.add(AssistUnmatchedLine(raw: claim.rawLine));
      continue;
    }
    taken.add(claim.position.id);
    byGroup.putIfAbsent(claim.groupIndex, () => []).add(
      AssistMatchedPosition(
        positionId: claim.position.id,
        displayName: claim.position.displayName,
        confidence: claim.confidence,
        rawLine: claim.rawLine,
      ),
    );
  }

  final products = [
    for (var i = 0; i < groups.length; i++)
      AssistDraftProduct(name: groups[i].productName, positions: byGroup[i] ?? const []),
  ];
  assistLog('match assigned=${taken.length} unmatched=${unmatched.length}');
  return AssistDraft(products: products, unmatched: unmatched);
}

AssistLineMatch? matchAssistLine(
  String rawLine,
  List<CatalogPosition> unassigned, {
  Set<String>? knownIds,
}) {
  if (unassigned.isEmpty) return null;
  final ids = knownIds ?? {for (final position in unassigned) position.id};
  final cleaned = rawLine.trim();
  final byId = _matchById(cleaned, unassigned, ids);
  if (byId != null) return byId;

  final query = _nameFromLine(cleaned);
  AssistLineMatch? best;
  for (final position in unassigned) {
    final score = assistNameSimilarity(query, position.displayName);
    if (best == null || score > best.confidence) {
      best = AssistLineMatch(position: position, confidence: score);
    }
  }
  return best;
}

String normalizeAssistName(String raw) {
  return normalizeItemName(raw.replaceAll('ё', 'е').replaceAll('Ё', 'Е'));
}

double assistNameSimilarity(String left, String right) {
  final a = normalizeAssistName(left);
  final b = normalizeAssistName(right);
  if (a.isEmpty || b.isEmpty) return 0;
  if (a == b) return 1;
  return math.max(1 - editRatio(a, b), math.max(_trigramDice(a, b), _tokenScore(a, b)));
}

AssistLineMatch? _matchById(String line, List<CatalogPosition> unassigned, Set<String> knownIds) {
  final token = _leadingToken(line);
  if (token == null || !knownIds.contains(token)) return null;
  for (final position in unassigned) {
    if (position.id == token) return AssistLineMatch(position: position, confidence: 1);
  }
  return null;
}

String? _leadingToken(String line) {
  final colon = _leadingId.firstMatch(line);
  if (colon != null) return colon[1];
  final space = _firstToken.firstMatch(line);
  var token = space?[1];
  if (token != null && token.endsWith(':')) {
    token = token.substring(0, token.length - 1);
  }
  return token;
}

String _nameFromLine(String line) {
  final rest = _nameAfterId.firstMatch(line)?[1]?.trim();
  return (rest == null || rest.isEmpty) ? line : rest;
}

Set<String> _trigrams(String text) {
  if (text.length < 3) return {text};
  return {for (var i = 0; i <= text.length - 3; i++) text.substring(i, i + 3)};
}

double _trigramDice(String a, String b) {
  final sa = _trigrams(a);
  final sb = _trigrams(b);
  if (sa.isEmpty || sb.isEmpty) return 0;
  var inter = 0;
  for (final gram in sa) {
    if (sb.contains(gram)) inter += 1;
  }
  return (2 * inter) / (sa.length + sb.length);
}

double _tokenScore(String a, String b) {
  final ta = {for (final part in a.split(' ')) if (part.isNotEmpty) part};
  final tb = {for (final part in b.split(' ')) if (part.isNotEmpty) part};
  if (ta.isEmpty || tb.isEmpty) return 0;
  final inter = ta.intersection(tb);
  if (inter.isEmpty) return 0;
  final jaccard = inter.length / ta.union(tb).length;
  final smaller = ta.length < tb.length ? ta.length : tb.length;
  return 0.55 * (inter.length / smaller) + 0.45 * jaccard;
}
