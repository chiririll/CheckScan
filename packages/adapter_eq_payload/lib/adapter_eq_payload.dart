import 'dart:convert';

import 'package:adapter_core/adapter_core.dart';
import 'package:crypto/crypto.dart';

class EqPayloadAdapter implements ReceiptAdapter {
  const EqPayloadAdapter();

  @override
  String get id => 'eq_payload';

  @override
  String? canHandle(String rawQr) {
    final map = _asMap(rawQr);
    if (map == null) return null;
    if (map['eq_version'] == null && map['receipt'] == null) return null;
    try {
      final receipt = EqReceipt.fromJson(map);
      if (receipt.id.isNotEmpty) return receipt.id;
      return sha256.convert(utf8.encode(receipt.encode())).toString();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<EqReceipt> parse(
    String rawQr, {
    void Function(String status)? onStatus,
  }) async {
    onStatus?.call('eq_reading');
    final map = _asMap(rawQr);
    if (map == null) {
      throw const AdapterParseException('eq_payload', 'invalid_json');
    }
    return EqReceipt.fromJson(map);
  }

  Map<String, dynamic>? _asMap(String raw) {
    final text = raw.trim();
    if (!text.startsWith('{')) return null;
    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }
}
