import 'dart:convert';

import 'package:eq_models/eq_models.dart';
import 'package:providers_native/providers_native.dart';

class ProviderMatch {
  const ProviderMatch({required this.adapterId, required this.hash, this.label = ''});

  final String adapterId;
  final String hash;
  final String label;

  String get storageKey => '$adapterId:$hash';
}

class ResolveResult {
  const ResolveResult({
    required this.adapterId,
    required this.hash,
    required this.receipt,
    this.label = '',
  });

  final String adapterId;
  final String hash;
  final String label;
  final EqReceipt receipt;

  String get storageKey => '$adapterId:$hash';
}

class UnknownReceiptFormat implements Exception {
  const UnknownReceiptFormat();
}

class ProviderParseException implements Exception {
  const ProviderParseException(this.adapterId, this.message);

  final String adapterId;
  final String message;

  @override
  String toString() => 'ProviderParseException($adapterId): $message';
}

class ProviderSecretSpec {
  const ProviderSecretSpec({required this.key, required this.label});

  final String key;
  final String label;
}

List<ProviderSecretSpec> secretSpecsFromProvidersJson(String raw) {
  final value = jsonDecode(raw);
  if (value is! List) return const [];
  final specs = <ProviderSecretSpec>[];
  for (final item in value) {
    if (item is! Map) continue;
    final id = '${item['id'] ?? ''}';
    final label = '${item['label'] ?? id}';
    final secrets = item['secrets'];
    if (secrets is! List) continue;
    for (final secret in secrets) {
      if (secret is! Map) continue;
      final secretId = '${secret['id'] ?? ''}';
      if (id.isEmpty || secretId.isEmpty) continue;
      specs.add(ProviderSecretSpec(key: '$id.$secretId', label: label));
    }
  }
  return specs;
}

abstract class ProvidersBackend {
  Future<ProviderMatch?> match(String rawQr, {String? hint});
  Future<ResolveResult> resolve(String rawQr, {String? hint, bool remote = false, bool wait = false, String? current});
  Future<List<ProviderSecretSpec>> secretSpecs() async => const [];
}

class NativeProvidersBackend implements ProvidersBackend {
  NativeProvidersBackend({IsolatedNativeProviders? lib, Map<String, String> Function()? config})
    : _lib = lib ?? IsolatedNativeProviders(config: config);

  final IsolatedNativeProviders _lib;

  @override
  Future<ProviderMatch?> match(String rawQr, {String? hint}) async {
    final raw = await _lib.match(rawQr, hint: hint ?? '');
    _trace('match hint=${hint ?? ''} qr=${_preview(rawQr)} -> ${_preview(raw)}');
    final decoded = _decode(raw);
    if (_errorCode(decoded) == 'unknown_format') return null;
    _throwIfError(decoded, adapterId: hint);
    return ProviderMatch(
      adapterId: '${decoded['adapter_id']}',
      hash: '${decoded['hash']}',
      label: '${decoded['label'] ?? ''}',
    );
  }

  @override
  Future<ResolveResult> resolve(
    String rawQr, {
    String? hint,
    bool remote = false,
    bool wait = false,
    String? current,
  }) async {
    final raw = await _lib.resolve(
      rawQr,
      hint: hint ?? '',
      remote: remote,
      wait: wait,
      current: current ?? '',
    );
    _trace('resolve remote=$remote wait=$wait hint=${hint ?? ''} qr=${_preview(rawQr)} -> ${_preview(raw)}');
    final decoded = _decode(raw);
    _throwIfError(decoded, adapterId: hint);
    final adapterId = '${decoded['adapter_id']}';
    return ResolveResult(
      adapterId: adapterId,
      hash: '${decoded['hash']}',
      label: '${decoded['label'] ?? ''}',
      receipt: EqReceipt.fromJson(decoded),
    );
  }

  @override
  Future<List<ProviderSecretSpec>> secretSpecs() async {
    return secretSpecsFromProvidersJson(await _lib.providers());
  }

  Map<String, dynamic> _decode(String raw) {
    final value = jsonDecode(raw);
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw const ProviderParseException('', 'invalid_native_json');
  }

  String? _errorCode(Map<String, dynamic> json) {
    final error = json['error'];
    if (error is Map && error['code'] != null) return error['code'].toString();
    return null;
  }

  void _throwIfError(Map<String, dynamic> json, {String? adapterId}) {
    final code = _errorCode(json);
    if (code == null) return;
    final message = json['error'] is Map ? '${(json['error'] as Map)['message']}' : code;
    if (code == 'unknown_format') {
      throw const UnknownReceiptFormat();
    }
    throw ProviderParseException(adapterId ?? '', message);
  }

  void _trace(String message) {
    print('[checkscan] $message');
  }

  String _preview(String raw, [int max = 240]) {
    final text = raw.replaceAll('\n', r'\n');
    if (text.length <= max) return text;
    return '${text.substring(0, max)}…(${text.length})';
  }
}
