import 'assist_parse.dart';

/// Rebuild parser prefixes from HTML *structure*, not from `###` / `*` characters.
///
/// Chat copy stores headings and lists as tags (`<h3>`, `<li>`, sometimes
/// `<p><strong>`). The symbols themselves are not in the clipboard. We invent
/// two prefix families so [parseAssistReply] can detect-then-strip as usual:
/// heading-like → `#` family (`###`), list-like → `*`.
final _heading = RegExp(r'<h([1-6])\b[^>]*>([\s\S]*?)</h\1>', caseSensitive: false);
final _listItem = RegExp(r'<li\b[^>]*>([\s\S]*?)</li>', caseSensitive: false);
final _blockStrong = RegExp(
  r'<(p|div)\b[^>]*>\s*<(strong|b)\b[^>]*>([\s\S]*?)</\2>\s*</\1>',
  caseSensitive: false,
);
final _tag = RegExp(r'<[^>]+>');
final _break = RegExp(r'<br\s*/?>', caseSensitive: false);
final _wrapSpace = RegExp(r'[\t\r\n]+');
final _hexEntity = RegExp(r'&#x([0-9a-fA-F]+);');
final _decEntity = RegExp(r'&#(\d+);');
final _lineBreaks = RegExp(r'\r\n|\n|\r');

class _HtmlBlock {
  const _HtmlBlock(this.start, this.end, this.heading, this.inner);

  final int start;
  final int end;
  final bool heading;
  final String inner;
}

String assistHtmlToPrefixed(String html) {
  final blocks = <_HtmlBlock>[
    for (final match in _heading.allMatches(html)) _HtmlBlock(match.start, match.end, true, match[2]!),
    for (final match in _blockStrong.allMatches(html)) _HtmlBlock(match.start, match.end, true, match[3]!),
    for (final match in _listItem.allMatches(html)) _HtmlBlock(match.start, match.end, false, match[1]!),
  ]..sort((a, b) => a.start.compareTo(b.start));

  final kept = <_HtmlBlock>[];
  for (final block in blocks) {
    if (kept.any((parent) => block.start >= parent.start && block.end <= parent.end)) continue;
    kept.add(block);
  }

  final lines = <String>[];
  for (final block in kept) {
    final text = _visibleText(block.inner);
    if (text.isEmpty) continue;
    lines.add(block.heading ? '### $text' : '* $text');
  }
  return lines.join('\n');
}

String? assistFirstPrefixType(String text) {
  for (final line in text.split(_lineBreaks)) {
    final marked = assistLinePrefix(line);
    if (marked != null) return marked.type;
  }
  return null;
}

String _visibleText(String raw) {
  var text = raw.replaceAll(_break, ' ').replaceAll(_tag, '');
  text = _decodeEntities(text);
  return text.replaceAll(_wrapSpace, ' ').trim();
}

String _decodeEntities(String raw) {
  var text = raw
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&apos;', "'");
  text = text.replaceAllMapped(_hexEntity, (match) => String.fromCharCode(int.parse(match[1]!, radix: 16)));
  text = text.replaceAllMapped(_decEntity, (match) => String.fromCharCode(int.parse(match[1]!)));
  return text.replaceAll('&amp;', '&');
}
