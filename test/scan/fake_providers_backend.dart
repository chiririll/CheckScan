import 'package:checkscan/core/scan/providers_backend.dart';
import 'package:eq_models/eq_models.dart';

class FakeProvidersBackend implements ProvidersBackend {
  FakeProvidersBackend({this.throwOnResolve = false, this.nextReceipt});

  final bool throwOnResolve;
  EqReceipt? nextReceipt;

  static const fnsQuery = 't=20260828T1842&s=1247.00&fn=8710000100905518&i=12&fp=4135164163&n=1';
  static const fnsHash = '8710000100905518|12|4135164163';
  static const eqId = '550e8400-e29b-41d4-a716-446655440000';

  @override
  Future<ProviderMatch?> match(String rawQr, {String? hint}) async {
    if (rawQr == 'boom') {
      return const ProviderMatch(adapterId: 'boom', hash: 'h', label: 'X');
    }
    if (rawQr.contains('fn=8710000100905518')) {
      return const ProviderMatch(adapterId: 'ru_fns', hash: fnsHash, label: 'RU');
    }
    if (rawQr.contains(eqId)) {
      return const ProviderMatch(adapterId: 'eq_payload', hash: eqId, label: 'EQ');
    }
    return null;
  }

  @override
  Future<ResolveResult> resolve(String rawQr, {String? hint, bool remote = false, bool wait = false}) async {
    if (throwOnResolve || rawQr == 'boom') {
      throw const ProviderParseException('boom', 'fail');
    }
    final matched = await match(rawQr, hint: hint);
    if (matched == null) {
      throw const UnknownReceiptFormat();
    }
    if (nextReceipt != null) {
      return ResolveResult(
        adapterId: matched.adapterId,
        hash: matched.hash,
        label: matched.label,
        receipt: nextReceipt!,
      );
    }
    if (matched.adapterId == 'ru_fns') {
      return ResolveResult(
        adapterId: matched.adapterId,
        hash: matched.hash,
        label: matched.label,
        receipt: EqReceipt(
          id: 'ru-$fnsHash',
          issuedAt: DateTime(2026, 8, 28, 18, 42),
          currency: 'RUB',
          receiptType: 'sale',
          grandTotal: 1247,
        ),
      );
    }
    return ResolveResult(
      adapterId: matched.adapterId,
      hash: matched.hash,
      label: matched.label,
      receipt: EqReceipt(
        id: eqId,
        issuedAt: DateTime(2026, 8, 28, 18, 42),
        currency: 'RUB',
        receiptType: 'sale',
        merchantName: 'Пятёрочка',
        grandTotal: 1247,
        items: const [EqItem(description: 'Молоко 1 л', quantity: 2, unitPrice: 89, totalPrice: 178)],
      ),
    );
  }
}
