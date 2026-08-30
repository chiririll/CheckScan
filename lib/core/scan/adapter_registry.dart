import 'package:adapter_core/adapter_core.dart';
import 'package:adapter_eq_payload/adapter_eq_payload.dart';
import 'package:adapter_ru_fns/adapter_ru_fns.dart';

class AdapterMatch {
  const AdapterMatch({required this.adapter, required this.hash});
  final ReceiptAdapter adapter;
  final String hash;

  String get storageKey => '${adapter.id}:$hash';
}

class AdapterChain {
  AdapterChain([List<ReceiptAdapter>? adapters])
      : adapters = adapters ?? const [EqPayloadAdapter(), RuFnsAdapter()];

  final List<ReceiptAdapter> adapters;

  AdapterMatch? match(String rawQr) {
    for (final adapter in adapters) {
      final hash = adapter.canHandle(rawQr);
      if (hash != null && hash.isNotEmpty) {
        return AdapterMatch(adapter: adapter, hash: hash);
      }
    }
    return null;
  }

  ReceiptAdapter? byId(String id) {
    for (final adapter in adapters) {
      if (adapter.id == id) return adapter;
    }
    return null;
  }
}
