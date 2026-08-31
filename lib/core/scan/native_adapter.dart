import 'package:eq_models/eq_models.dart';
import 'package:providers_native/providers_native.dart' as native;

class SettingField {
  const SettingField({required this.key, required this.type, required this.label});

  final String key;
  final String type;
  final String label;
}

class AdapterMatch {
  const AdapterMatch({required this.adapterId, required this.hash, this.label = ''});

  final String adapterId;
  final String hash;
  final String label;

  String get storageKey => '$adapterId:$hash';
}

class AdapterResolve {
  const AdapterResolve({
    required this.adapterId,
    required this.hash,
    required this.receipt,
    this.label = '',
  });

  final String adapterId;
  final String hash;
  final String label;
  final EqReceipt receipt;
}

class AdapterResult<T> {
  const AdapterResult({required this.status, this.message = '', this.data});

  final int status;
  final String message;
  final T? data;
}

abstract class NativeAdapter {
  Future<AdapterResult<AdapterMatch>> match(String rawQr, {String? hint});

  Future<AdapterResult<AdapterResolve>> resolve(
    String rawQr, {
    String? hint,
    bool remote = false,
    bool wait = false,
    String? current,
  });

  Future<List<SettingField>> settings();

  void configure(Map<String, String> snapshot);
}

class IsolatedNativeAdapter implements NativeAdapter {
  IsolatedNativeAdapter({native.IsolatedNativeProviders? lib}) : _lib = lib ?? native.IsolatedNativeProviders();

  final native.IsolatedNativeProviders _lib;

  @override
  void configure(Map<String, String> snapshot) => _lib.configure(snapshot);

  @override
  Future<AdapterResult<AdapterMatch>> match(String rawQr, {String? hint}) async {
    final env = await _lib.match(rawQr, hint: hint ?? '');
    final data = env.data;
    return AdapterResult(
      status: env.status,
      message: env.message,
      data: data == null ? null : AdapterMatch(adapterId: data.adapterId, hash: data.hash, label: data.label),
    );
  }

  @override
  Future<AdapterResult<AdapterResolve>> resolve(
    String rawQr, {
    String? hint,
    bool remote = false,
    bool wait = false,
    String? current,
  }) async {
    final env = await _lib.resolve(
      rawQr,
      hint: hint ?? '',
      remote: remote,
      wait: wait,
      current: current ?? '',
    );
    final data = env.data;
    return AdapterResult(
      status: env.status,
      message: env.message,
      data: data == null
          ? null
          : AdapterResolve(
              adapterId: data.adapterId,
              hash: data.hash,
              label: data.label,
              receipt: EqReceipt.fromJson(data.receipt),
            ),
    );
  }

  @override
  Future<List<SettingField>> settings() async {
    final env = await _lib.settings();
    return [
      for (final field in env.data ?? const <native.SettingField>[])
        SettingField(key: field.key, type: field.type, label: field.label),
    ];
  }
}
