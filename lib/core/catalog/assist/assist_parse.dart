import 'dart:convert';

import 'assist_log.dart';

class AssistParsedGroup {
  const AssistParsedGroup({required this.productName, required this.lines});

  final String productName;
  final List<String> lines;
}

class AssistParsedReply {
  const AssistParsedReply({this.groups = const [], this.orphans = const []});

  final List<AssistParsedGroup> groups;
  final List<String> orphans;

  bool get isEmpty => groups.isEmpty;
}

final _fence = RegExp(r'^```');
final _lineBreaks = RegExp(r'\r\n|\n|\r');
final _formatJunk = RegExp(r'[\u200B-\u200D\uFEFF\u2060]');
final _oddSpace = RegExp(r'[\u00A0\u1680\u2000-\u200A\u202F\u205F\u3000]');
final _wrappingFence = RegExp(r'^```[^\r\n]*\r?\n([\s\S]*?)\r?\n```\s*$');
final _indent = RegExp(r'^[ \t]+');
final _trailingSpace = RegExp(r'[ \t]+$');

/// Structural marker still sitting on the line. Detect this *before* peeling.
///
/// `#` / `###` → `#`; `*` → `*`; `-` → `-`; `1.` / `2)` → `.` / `)`.
/// A cashier id (`25016:`) is not a prefix.
final _headingMark = RegExp(r'^#{1,6}(?=\s|$)');
final _starMark = RegExp(r'^\*(?=\s|$)');
final _dashMark = RegExp(r'^-(?=\s|$)');
final _numberedMark = RegExp(r'^\d+([.)])(?=\s|$)');

String _stripBom(String raw) => raw.replaceAll(_formatJunk, '').replaceAll(_oddSpace, ' ');

/// Raw line for prefix detection: BOM / odd spaces, indent, trailing space.
/// Markers stay on the line.
String _lineForPrefixDetect(String raw) {
  var line = _stripBom(raw);
  line = line.replaceFirst(_trailingSpace, '');
  line = line.replaceFirst(_indent, '');
  return line;
}

String _keptLine(String raw) {
  final line = _stripBom(raw).trim();
  if (line.isEmpty || _fence.hasMatch(line)) return '';
  return line;
}

/// Leading marker on a line, if any.
///
/// Law: detect the type on the line *with the marker still there*, remember it,
/// and only then peel that one marker. Do not strip `###` / `*` / `-` / `1.`
/// first and then try to classify — nothing would be left to search.
({String type, String text})? assistLinePrefix(String raw) {
  final line = _lineForPrefixDetect(raw);
  if (line.isEmpty || _fence.hasMatch(line)) return null;

  final type = _detectPrefixType(line);
  if (type == null) return null;

  final text = _peelPrefix(line, type);
  return (type: type, text: text);
}

/// Classify while `###`, `*`, `-`, `1.` are still on [line].
String? _detectPrefixType(String line) {
  if (_headingMark.hasMatch(line)) return '#';
  if (_starMark.hasMatch(line)) return '*';
  if (_dashMark.hasMatch(line)) return '-';
  final numbered = _numberedMark.firstMatch(line);
  if (numbered != null) return numbered[1];
  return null;
}

/// Peel only the marker already classified as [type]. Payload stays intact.
String _peelPrefix(String line, String type) {
  final match = switch (type) {
    '#' => _headingMark.firstMatch(line),
    '*' => _starMark.firstMatch(line),
    '-' => _dashMark.firstMatch(line),
    '.' || ')' => _numberedMark.firstMatch(line),
    _ => null,
  };
  if (match == null) return line.trim();
  return line.substring(match.end).trim();
}

AssistParsedReply parseAssistReply(String raw) {
  try {
    return _parseAssistReply(raw);
  } catch (error) {
    assistLog('parse threw: $error');
    return const AssistParsedReply();
  }
}

AssistParsedReply _parseAssistReply(String raw) {
  final text = _unwrapAssistPayload(raw);
  assistLog(
    'parse len=${raw.length} unwrapped=${text.length} curly=${text.startsWith('{')} '
    'preview="${assistPreview(text)}"',
  );
  final fromJson = _tryParseJson(text);
  if (fromJson != null && !fromJson.isEmpty) {
    assistLog('parse via json');
    _logParsed(fromJson, firstType: '{', seen: const ['{']);
    return fromJson;
  }
  if (fromJson != null) assistLog('json empty, falling through to prefixes');
  return _parsePrefixed(text);
}

AssistParsedReply _parsePrefixed(String raw) {
  final groups = <AssistParsedGroup>[];
  final seen = <String>[];
  String? productType;
  String? currentName;
  var currentLines = <String>[];

  void flush() {
    final name = currentName?.trim();
    if (name == null || name.isEmpty) return;
    groups.add(AssistParsedGroup(productName: name, lines: List.of(currentLines)));
    currentName = null;
    currentLines = [];
  }

  for (final rawLine in raw.split(_lineBreaks)) {
    if (_keptLine(rawLine).isEmpty) continue;

    // Detect on the raw-ish line (markers still present), then peel once.
    final marked = assistLinePrefix(rawLine);
    final kept = marked?.text ?? _keptLine(rawLine);
    assistLog(
      'raw="${assistPreview(rawLine)}" prefix=${marked?.type ?? '—'} '
      'kept="${assistPreview(kept)}"',
    );
    if (marked == null) {
      if (currentName != null && kept.isNotEmpty) currentLines.add(kept);
      continue;
    }

    seen.add(marked.type);
    productType ??= marked.type;
    if (marked.type == productType) {
      flush();
      currentName = marked.text;
      currentLines = [];
    } else if (currentName != null && marked.text.isNotEmpty) {
      currentLines.add(marked.text);
    }
  }
  flush();

  if (groups.isEmpty) {
    final reason = seen.isEmpty ? 'no prefixed lines' : 'no named groups after flush';
    assistLog('parse empty: $reason seen=${seen.join(',')}');
    return const AssistParsedReply();
  }
  _logParsed(AssistParsedReply(groups: groups), firstType: productType, seen: seen);
  return AssistParsedReply(groups: groups);
}

void _logParsed(AssistParsedReply parsed, {String? firstType, List<String> seen = const []}) {
  assistLog('first prefix type=${firstType ?? '—'} seen=${seen.join(',')}');
  assistLog('groups=${parsed.groups.length}');
  for (var i = 0; i < parsed.groups.length; i++) {
    final group = parsed.groups[i];
    assistLog('  [$i] "${group.productName}" positions=${group.lines.length}');
  }
}

String _unwrapAssistPayload(String raw) {
  var text = _stripBom(raw).trim();
  final wrapped = _wrappingFence.firstMatch(text);
  if (wrapped != null) return wrapped[1]!.trim();
  return text;
}

AssistParsedReply? _tryParseJson(String raw) {
  final extracted = _extractJsonObject(raw);
  if (extracted == null) return null;
  final Object decoded;
  try {
    decoded = jsonDecode(extracted);
  } on FormatException catch (error) {
    assistLog('json decode failed: $error');
    return null;
  }
  if (decoded is! Map || decoded['products'] is! List) {
    assistLog('json skipped: no products list');
    return null;
  }
  final groups = <AssistParsedGroup>[];
  for (final item in decoded['products'] as List) {
    if (item is! Map) continue;
    final name = '${item['name'] ?? ''}'.trim();
    if (name.isEmpty) continue;
    final lines = <String>[];
    final rawPositions = item['positions'];
    if (rawPositions is List) {
      for (final row in rawPositions) {
        final line = _jsonPositionLine(row);
        if (line != null) lines.add(line);
      }
    }
    groups.add(AssistParsedGroup(productName: name, lines: lines));
  }
  return AssistParsedReply(groups: groups);
}

String? _jsonPositionLine(Object? row) {
  if (row is String) {
    final text = row.trim();
    return text.isEmpty ? null : text;
  }
  if (row is! Map) return null;
  final id = '${row['id'] ?? ''}'.trim();
  final name = '${row['name'] ?? ''}'.trim();
  if (id.isNotEmpty && name.isNotEmpty) return '$id: $name';
  if (id.isNotEmpty) return id;
  if (name.isNotEmpty) return name;
  return null;
}

String? _extractJsonObject(String raw) {
  var text = _keptLine(raw);
  if (text.isEmpty) return null;
  text = text.replaceFirst(RegExp(r'^```(?:json)?', caseSensitive: false), '');
  text = text.replaceFirst(RegExp(r'```\s*$'), '');
  text = _keptLine(text);
  if (!text.startsWith('{')) return null;
  final end = text.lastIndexOf('}');
  if (end <= 0) return null;
  final leftover = text.substring(end + 1);
  if (_hasNonFenceContent(leftover)) {
    assistLog('json skipped: leftover after } "${assistPreview(leftover)}"');
    return null;
  }
  return text.substring(0, end + 1);
}

bool _hasNonFenceContent(String raw) {
  for (final line in raw.split(_lineBreaks)) {
    if (_keptLine(line).isNotEmpty) return true;
  }
  return false;
}
