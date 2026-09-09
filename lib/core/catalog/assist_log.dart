import 'package:flutter/foundation.dart';

const assistLogPrefix = '[checkscan] assist';

void assistLog(String message) {
  debugPrint('$assistLogPrefix $message');
}

String assistPreview(String raw, {int cap = 80}) {
  final escaped = raw.replaceAll(r'\', r'\\').replaceAll('\r', r'\r').replaceAll('\n', r'\n').replaceAll('\t', r'\t');
  if (escaped.length <= cap) return escaped;
  return '${escaped.substring(0, cap)}…';
}
