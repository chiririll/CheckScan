import 'dart:convert';

import 'package:checkscan/core/models/receipt_status.dart';
import 'package:checkscan/core/scan/native_adapter.dart';
import 'package:eq_models/eq_models.dart';

class FakeNativeAdapter implements NativeAdapter {
  FakeNativeAdapter({this.failResolve = false, this.nextReceipt, this.resolveStatus});

  final bool failResolve;
  EqReceipt? nextReceipt;
  int? resolveStatus;
  Map<String, String> config = {};

  static const fnsQuery = 't=20260828T1842&s=1247.00&fn=8710000100905518&i=12&fp=4135164163&n=1';
  static const fnsHash = '8710000100905518|12|4135164163';
  static const eqId = '550e8400-e29b-41d4-a716-446655440000';

  @override
  void configure(Map<String, String> snapshot) {
    config = Map<String, String>.from(snapshot);
  }

  @override
  Future<List<SettingField>> settings() async => const [
        SettingField(key: 'ru_fns.token', type: 'secret', label: 'RU'),
      ];

  @override
  Future<AdapterResult<AdapterMatch>> match(String rawQr, {String? hint}) async {
    if (rawQr == 'boom') {
      return const AdapterResult(
        status: statusOk,
        data: AdapterMatch(adapterId: 'boom', hash: 'h', label: 'X'),
      );
    }
    if (rawQr.contains('fn=8710000100905518')) {
      return const AdapterResult(
        status: statusOk,
        data: AdapterMatch(adapterId: 'ru_fns', hash: fnsHash, label: 'RU'),
      );
    }
    if (rawQr.contains(eqId)) {
      return const AdapterResult(
        status: statusOk,
        data: AdapterMatch(adapterId: 'eq_payload', hash: eqId, label: 'EQ'),
      );
    }
    return const AdapterResult(status: statusUnknownFormat, message: 'unknown_format');
  }

  @override
  Future<AdapterResult<AdapterResolve>> resolve(
    String rawQr, {
    String? hint,
    bool remote = false,
    bool wait = false,
    String? current,
  }) async {
    if (failResolve || rawQr == 'boom') {
      return const AdapterResult(status: statusParseError, message: 'fail');
    }
    final matched = await match(rawQr, hint: hint);
    final found = matched.data;
    if (found == null) {
      return AdapterResult(status: matched.status, message: matched.message);
    }
    if (nextReceipt != null) {
      return AdapterResult(
        status: resolveStatus ?? statusOk,
        data: AdapterResolve(
          adapterId: found.adapterId,
          hash: found.hash,
          label: found.label,
          receipt: nextReceipt!,
        ),
      );
    }
    if (current != null && current.isNotEmpty) {
      final decoded = jsonDecode(current);
      return AdapterResult(
        status: resolveStatus ?? statusIncomplete,
        data: AdapterResolve(
          adapterId: found.adapterId,
          hash: found.hash,
          label: found.label,
          receipt: EqReceipt.fromJson(decoded is Map<String, dynamic> ? decoded : Map<String, dynamic>.from(decoded as Map)),
        ),
      );
    }
    if (found.adapterId == 'ru_fns') {
      return AdapterResult(
        status: statusIncomplete,
        data: AdapterResolve(
          adapterId: found.adapterId,
          hash: found.hash,
          label: found.label,
          receipt: EqReceipt(
            id: 'ru-$fnsHash',
            issuedAt: DateTime(2026, 8, 28, 18, 42),
            currency: 'RUB',
            receiptType: 'sale',
            grandTotal: 1247,
          ),
        ),
      );
    }
    return AdapterResult(
      status: statusOk,
      data: AdapterResolve(
        adapterId: found.adapterId,
        hash: found.hash,
        label: found.label,
        receipt: EqReceipt(
          id: eqId,
          issuedAt: DateTime(2026, 8, 28, 18, 42),
          currency: 'RUB',
          receiptType: 'sale',
          merchantName: 'Пятёрочка',
          grandTotal: 1247,
          items: const [EqItem(description: 'Молоко 1 л', quantity: 2, unitPrice: 89, totalPrice: 178)],
        ),
      ),
    );
  }
}
