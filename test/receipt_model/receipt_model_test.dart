import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:receipt_model/receipt_model.dart';

Map<String, dynamic> _nativeReceipt(String fixture) {
  final envelope = jsonDecode(File('test/fixtures/native/$fixture').readAsStringSync()) as Map<String, dynamic>;
  return Map<String, dynamic>.from((envelope['data'] as Map)['receipt'] as Map);
}

void main() {
  group('parseMinor', () {
    test('reads decimal text into minor units exactly', () {
      expect(parseMinor('1247', 2), 124700);
      expect(parseMinor('89.99', 2), 8999);
      expect(parseMinor('1247,5', 2), 124750);
      expect(parseMinor('.05', 2), 5);
      expect(parseMinor('-12.345', 2), -1235);
      expect(parseMinor('0.004', 2), 0);
      expect(parseMinor('99', 0), 99);
    });

    test('rejects anything that is not a plain decimal', () {
      for (final raw in ['', '.', '1.2.3', '1e3', 'abc', '1 000']) {
        expect(parseMinor(raw, 2), isNull, reason: raw);
      }
    });
  });

  test('splitMinor keeps the fraction as zero-padded text', () {
    expect(splitMinor(124705, 2), (negative: false, whole: 1247, fraction: '05'));
    expect(splitMinor(-50, 2), (negative: true, whole: 0, fraction: '50'));
    expect(splitMinor(99, 0), (negative: false, whole: 99, fraction: ''));
  });

  test('minorExponent defaults to 2', () {
    expect(minorExponent('RUB'), 2);
    expect(minorExponent('rsd'), 2);
    expect(minorExponent('JPY'), 0);
  });

  test('decodes what the native library returns for an eQ QR', () {
    final receipt = Receipt.fromJson(_nativeReceipt('resolve_eq_payload.json'));
    expect(receipt.total, 124700);
    expect(receipt.merchantName, 'Пятёрочка');
    expect(receipt.items.single.name, 'Молоко 1 л');
    expect(receipt.items.single.quantity, 2);
    expect(receipt.items.single.price, 8900);
    expect(receipt.items.single.sum, 17800);
  });

  test('decodes the offline FNS parse', () {
    final receipt = Receipt.fromJson(_nativeReceipt('resolve_ru_fns_local.json'));
    expect(receipt.total, 124700);
    expect(receipt.items, isEmpty);
    expect(receipt.merchantName, isNull);
  });

  test('encode round-trips and is what the native library reads back', () {
    final original = Receipt.fromJson(_nativeReceipt('resolve_eq_payload.json'));
    final json = jsonDecode(original.encode()) as Map<String, dynamic>;
    expect(json['format'], receiptFormat);
    expect(json['version'], receiptFormatVersion);
    expect(json['total'], isA<int>());
    final again = Receipt.decode(original.encode());
    expect(again.total, original.total);
    expect(again.items.single.sum, 17800);
    expect(again.issuedAt, original.issuedAt);
  });

  test('refuses eQ and other formats', () {
    expect(
      () => Receipt.fromJson({'eq_version': '1.0.0', 'receipt': {'id': 'x'}}),
      throwsFormatException,
    );
  });
}
