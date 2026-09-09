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

final _headingMarks = RegExp(r'^#{1,6}\s+');
final _bulletMarks = RegExp(r'^[*+\-•–—]\s+');
final _numberedList = RegExp(r'^\d+[.)]\s+');
final _boldWrap = RegExp(r'\*{1,2}([^*]+)\*{1,2}');
final _italicWrap = RegExp(r'_{1,2}([^_]+)_{1,2}');
final _labelPrefix = RegExp(r'^(товар|product|категория|группа)\s*[:\-–]\s*', caseSensitive: false);
final _fence = RegExp(r'^```');
final _packSize = RegExp(
  r'\d+(?:[.,]\d+)?\s*(?:г|гр|g|кг|kg|мл|ml|л|l|шт|kom|ком|уп)',
  caseSensitive: false,
);
final _idThenName = RegExp(r'^(\S{1,16})\s*[:\-–]\s+(.+)$');
final _latinCapsWord = RegExp(r'[A-Z]{3,}');
final _letter = RegExp(r'\p{L}', unicode: true);
final _preamble = RegExp(
  r'^(вот|конечно|ниже|результат|группировка|хорошо|ок|here|sure|okay|ok|the|i)\b',
  caseSensitive: false,
);

String cleanAssistLine(String raw) {
  var line = raw.trim();
  if (line.isEmpty || _fence.hasMatch(line)) return '';
  line = line.replaceFirst(_headingMarks, '');
  line = line.replaceFirst(_bulletMarks, '');
  line = line.replaceFirst(_numberedList, '');
  line = line.replaceAllMapped(_boldWrap, (match) => match[1] ?? '');
  line = line.replaceAllMapped(_italicWrap, (match) => match[1] ?? '');
  line = line.replaceFirst(_labelPrefix, '');
  return line.trim();
}

bool looksLikePositionLine(String line) {
  if (line.isEmpty) return false;
  if (_packSize.hasMatch(line)) return true;
  if (line.length >= 28) return true;
  final id = _idThenName.firstMatch(line);
  if (id != null) {
    final prefix = id[1]!;
    final rest = id[2]!;
    if (RegExp(r'^\d+$').hasMatch(prefix) && rest.isNotEmpty) return true;
    if (rest.length >= 16) return true;
  }
  return _latinCapsWord.allMatches(line).length >= 2 && line.length >= 12;
}

bool looksLikePreamble(String line) {
  if (_preamble.hasMatch(line)) return true;
  if (line.length > 48 && line.contains(' ')) return true;
  return RegExp(r'[.!?]$').hasMatch(line) && line.length > 24;
}

bool looksLikeProductTitle(String line) {
  if (line.isEmpty || looksLikePositionLine(line) || looksLikePreamble(line)) return false;
  if (line.length > 42) return false;
  final words = [for (final part in line.split(RegExp(r'\s+'))) if (part.isNotEmpty) part];
  if (words.isEmpty || words.length > 5) return false;
  if (RegExp(r'[.!?]$').hasMatch(line) && words.length > 2) return false;
  var letters = 0;
  var chars = 0;
  for (final rune in line.runes) {
    final ch = String.fromCharCode(rune);
    if (ch.trim().isEmpty) continue;
    chars += 1;
    if (_letter.hasMatch(ch)) letters += 1;
  }
  return chars > 0 && letters / chars >= 0.7;
}

AssistParsedReply parseAssistReply(String raw) {
  final fromJson = _tryParseJson(raw);
  if (fromJson != null) return fromJson;

  final groups = <AssistParsedGroup>[];
  final orphans = <String>[];
  String? currentName;
  var currentLines = <String>[];

  void flush() {
    final name = currentName?.trim();
    if (name == null || name.isEmpty) return;
    groups.add(AssistParsedGroup(productName: name, lines: List.of(currentLines)));
    currentName = null;
    currentLines = [];
  }

  for (final rawLine in raw.split(RegExp(r'\r?\n'))) {
    final line = cleanAssistLine(rawLine);
    if (line.isEmpty) continue;
    if (looksLikePositionLine(line)) {
      if (currentName == null) {
        orphans.add(line);
      } else {
        currentLines.add(line);
      }
      continue;
    }
    if (looksLikePreamble(line)) continue;
    if (looksLikeProductTitle(line)) {
      if (currentName != null && currentLines.isEmpty) {
        currentName = line;
      } else {
        flush();
        currentName = line;
        currentLines = [];
      }
      continue;
    }
    if (currentName != null) {
      currentLines.add(line);
    }
  }
  flush();
  return AssistParsedReply(
    groups: [for (final group in groups) if (group.lines.isNotEmpty) group],
    orphans: orphans,
  );
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
  var text = raw.trim();
  if (text.isEmpty) return null;
  text = text.replaceFirst(RegExp(r'^```(?:json)?', caseSensitive: false), '');
  text = text.replaceFirst(RegExp(r'```\s*$'), '');
  final start = text.indexOf('{');
  final end = text.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  return text.substring(start, end + 1);
}
