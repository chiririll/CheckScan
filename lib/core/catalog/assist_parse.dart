import 'dart:convert';

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
final _punctRun = RegExp(r'^([^\s\p{L}\p{N}])\1*\s+(.*)$', unicode: true);
final _numbered = RegExp(r'^\d+([.)])\s+(.*)$');
final _letterLabel = RegExp(r'^(\p{L}+)\s*:\s+(.*)$', unicode: true);

String _tidyAssistLine(String raw) => raw.replaceAll(_formatJunk, '').trim();

/// Leading marker on a line, if any.
///
/// Type is the marker family, not a hardcoded role: a run of the same
/// punctuation (`###` and `#` → `#`; `*` → `*`), a numbered delimiter
/// (`1.` / `2.` → `.`), or a letter word plus colon (`Товар:` → `:`).
({String type, String text})? assistLinePrefix(String raw) {
  final line = _tidyAssistLine(raw);
  if (line.isEmpty || _fence.hasMatch(line)) return null;
  final punct = _punctRun.firstMatch(line);
  if (punct != null) return (type: punct[1]!, text: punct[2]!.trim());
  final numbered = _numbered.firstMatch(line);
  if (numbered != null) return (type: numbered[1]!, text: numbered[2]!.trim());
  final label = _letterLabel.firstMatch(line);
  if (label != null) return (type: ':', text: label[2]!.trim());
  return null;
}

String cleanAssistLine(String raw) {
  final marked = assistLinePrefix(raw);
  if (marked != null) return marked.text;
  final line = _tidyAssistLine(raw);
  if (line.isEmpty || _fence.hasMatch(line)) return '';
  return line;
}

AssistParsedReply parseAssistReply(String raw) {
  final fromJson = _tryParseJson(raw);
  if (fromJson != null && !fromJson.isEmpty) return fromJson;

  final groups = <AssistParsedGroup>[];
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
    final trimmed = _tidyAssistLine(rawLine);
    if (trimmed.isEmpty || _fence.hasMatch(trimmed)) continue;

    final marked = assistLinePrefix(trimmed);
    if (marked == null) {
      if (currentName != null) currentLines.add(trimmed);
      continue;
    }

    productType ??= marked.type;
    if (marked.type == productType) {
      flush();
      currentName = marked.text;
      currentLines = [];
    } else if (currentName != null) {
      currentLines.add(marked.text);
    }
  }
  flush();
  return AssistParsedReply(groups: [for (final group in groups) if (group.lines.isNotEmpty) group]);
}

AssistParsedReply? _tryParseJson(String raw) {
  final extracted = _extractJsonObject(raw);
  if (extracted == null) return null;
  final Object decoded;
  try {
    decoded = jsonDecode(extracted);
  } on FormatException {
    return null;
  }
  if (decoded is! Map || decoded['products'] is! List) return null;
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
  return AssistParsedReply(groups: [for (final group in groups) if (group.lines.isNotEmpty) group]);
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
  var text = _tidyAssistLine(raw);
  if (text.isEmpty) return null;
  text = text.replaceFirst(RegExp(r'^```(?:json)?', caseSensitive: false), '');
  text = text.replaceFirst(RegExp(r'```\s*$'), '');
  text = _tidyAssistLine(text);
  if (!text.startsWith('{')) return null;
  final end = text.lastIndexOf('}');
  if (end <= 0) return null;
  return text.substring(0, end + 1);
}
