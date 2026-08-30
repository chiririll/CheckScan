import 'dart:convert';
import 'dart:io';

import 'package:eq_models/eq_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final testdata = p.join('services', 'providers', 'testdata');

  test('parses eQ fixture from CheckScanProviders', () {
    final raw = File(p.join(testdata, 'eq_with_id.json')).readAsStringSync();
    final receipt = EqReceipt.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    expect(receipt.id, '550e8400-e29b-41d4-a716-446655440000');
    expect(receipt.merchantName, 'Пятёрочка');
    expect(receipt.items.single.description, 'Молоко 1 л');
    expect(receipt.grandTotal, 1247);
  });

  test('parses resolve envelope from CheckScanProviders', () {
    final raw = File(p.join(testdata, 'resolve_eq.json')).readAsStringSync();
    final map = jsonDecode(raw) as Map<String, dynamic>;
    final receipt = EqReceipt.fromJson(map);
    expect(map['adapter_id'], 'eq_payload');
    expect(receipt.id, '550e8400-e29b-41d4-a716-446655440000');
    expect(receipt.items, hasLength(1));
  });
}
