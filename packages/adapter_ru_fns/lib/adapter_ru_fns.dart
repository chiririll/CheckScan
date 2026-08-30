import 'package:adapter_core/adapter_core.dart';

class RuFnsAdapter implements ReceiptAdapter {
  const RuFnsAdapter();

  static final _query = RegExp(r'(?:^|[?&])([a-z]+)=([^&]*)', caseSensitive: false);

  @override
  String get id => 'ru_fns';

  @override
  String? canHandle(String rawQr) {
    final fields = parseFields(rawQr);
    if (fields == null) return null;
    return '${fields.fn}|${fields.fd}|${fields.fp}';
  }

  @override
  Future<EqReceipt> parse(
    String rawQr, {
    void Function(String status)? onStatus,
  }) async {
    onStatus?.call('ru_fns_loading');
    final fields = parseFields(rawQr);
    if (fields == null) {
      throw const AdapterParseException('ru_fns', 'invalid_qr');
    }
    return EqReceipt(
      id: 'ru-${fields.fn}-${fields.fd}-${fields.fp}',
      issuedAt: fields.issuedAt ?? DateTime.now(),
      currency: 'RUB',
      receiptType: fields.n == '2' ? 'refund' : 'sale',
      merchantName: null,
      items: const [],
      grandTotal: fields.sum ?? 0,
      extensions: {
        'checkscan.qr_raw': rawQr,
        'ru_fns': {
          'fn': fields.fn,
          'i': fields.fd,
          'fp': fields.fp,
          's': fields.sum,
          't': fields.t,
          'n': fields.n,
        },
      },
    );
  }

  static FnsQrFields? parseFields(String rawQr) {
    final values = <String, String>{};
    for (final match in _query.allMatches(rawQr)) {
      values[match.group(1)!.toLowerCase()] = Uri.decodeQueryComponent(match.group(2)!);
    }
    final fn = values['fn'];
    final fd = values['i'];
    final fp = values['fp'];
    if (fn == null || fn.isEmpty || fd == null || fd.isEmpty || fp == null || fp.isEmpty) {
      return null;
    }
    return FnsQrFields(
      fn: fn,
      fd: fd,
      fp: fp,
      t: values['t'],
      n: values['n'],
      sum: double.tryParse((values['s'] ?? '').replaceAll(',', '.')),
      issuedAt: _parseTime(values['t']),
    );
  }

  static DateTime? _parseTime(String? raw) {
    if (raw == null || raw.length < 13) return null;
    final compact = raw.replaceAll('T', '');
    if (compact.length < 12) return null;
    final year = int.tryParse(compact.substring(0, 4));
    final month = int.tryParse(compact.substring(4, 6));
    final day = int.tryParse(compact.substring(6, 8));
    final hour = int.tryParse(compact.substring(8, 10));
    final minute = int.tryParse(compact.substring(10, 12));
    final second = compact.length >= 14 ? int.tryParse(compact.substring(12, 14)) ?? 0 : 0;
    if (year == null || month == null || day == null || hour == null || minute == null) {
      return null;
    }
    return DateTime(year, month, day, hour, minute, second);
  }
}

class FnsQrFields {
  const FnsQrFields({
    required this.fn,
    required this.fd,
    required this.fp,
    this.t,
    this.n,
    this.sum,
    this.issuedAt,
  });

  final String fn;
  final String fd;
  final String fp;
  final String? t;
  final String? n;
  final double? sum;
  final DateTime? issuedAt;
}
