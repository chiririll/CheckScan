import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'assist_html.dart';
import 'assist_log.dart';

const assistClipboardChannelName = 'checkscan/clipboard';

class AssistClipData {
  const AssistClipData({this.plain = '', this.html});

  final String plain;
  final String? html;

  bool get hasHtml => html != null && html!.trim().isNotEmpty;
}

@visibleForTesting
Future<AssistClipData> Function() assistClipboardLoader = loadAssistClipboard;

Future<AssistClipData> loadAssistClipboard() async {
  if (defaultTargetPlatform == TargetPlatform.android) {
    try {
      final raw = await const MethodChannel(assistClipboardChannelName).invokeMethod<dynamic>('getClip');
      if (raw is Map) {
        final plain = raw['plain']?.toString() ?? '';
        final html = raw['html']?.toString();
        return AssistClipData(plain: plain, html: (html == null || html.isEmpty) ? null : html);
      }
    } on MissingPluginException {
      // Tests and hosts without the channel: fall back to Flutter text/plain.
    } catch (error) {
      assistLog('clipboard throw: $error');
    }
  }
  try {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return AssistClipData(plain: data?.text ?? '');
  } catch (error) {
    assistLog('clipboard throw: $error');
    return const AssistClipData();
  }
}

/// Clipboard path: [fieldText] is null. Confirm path: pass the field as plain fallback.
Future<String> resolveAssistPaste({String? fieldText}) async {
  final clip = await assistClipboardLoader();
  return resolveAssistPasteText(clip, fieldText: fieldText);
}

String resolveAssistPasteText(AssistClipData clip, {String? fieldText}) {
  assistLog('plain len=${clip.plain.length} preview="${assistPreview(clip.plain)}"');
  final html = clip.html;
  if (clip.hasHtml) {
    assistLog('html present=true len=${html!.length} preview="${assistPreview(html)}"');
    final converted = assistHtmlToPrefixed(html);
    final prefix = assistFirstPrefixType(converted);
    if (prefix != null) {
      assistLog('source=html');
      assistLog('first prefix after convert=$prefix');
      return converted;
    }
  } else {
    assistLog('html present=false');
  }

  final plain = fieldText ?? clip.plain;
  assistLog('source=plain');
  assistLog('first prefix after convert=${assistFirstPrefixType(plain) ?? '—'}');
  return plain;
}
