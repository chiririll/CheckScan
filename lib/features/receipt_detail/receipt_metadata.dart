import 'package:flutter/material.dart';

import '../../core/models/receipt_record.dart';
import '../../l10n/app_localizations.dart';

const _qrRawExtension = 'checkscan.qr_raw';

class ReceiptMetaRow {
  const ReceiptMetaRow({required this.label, required this.value});

  final String label;
  final String value;
}

List<ReceiptMetaRow> receiptMetadataRows(ReceiptRecord record, AppLocalizations l10n) {
  final receipt = record.receipt;
  final rows = <ReceiptMetaRow>[];
  final seen = <String>{};

  void add(String label, Object? value) {
    final text = _formatValue(value, l10n);
    if (text.isEmpty) return;
    if (!seen.add('$label=$text')) return;
    rows.add(ReceiptMetaRow(label: label, value: text));
  }

  add(l10n.metaTaxId, receipt.taxId);
  add(l10n.metaReceiptType, _receiptTypeLabel(receipt.receiptType, l10n));
  add(l10n.metaReceiptId, receipt.id.isNotEmpty ? receipt.id : record.id);

  var hasQr = false;
  void walk(String key, Object? value) {
    if (_isInternalKey(key)) return;
    if (key == _qrRawExtension) {
      add(l10n.metaQr, value);
      hasQr = true;
      return;
    }
    if (value is Map) {
      for (final entry in value.entries) {
        walk('${entry.key}', entry.value);
      }
      return;
    }
    if (value is List) return;
    add(key, value);
  }

  for (final entry in receipt.extensions.entries) {
    walk(entry.key, entry.value);
  }
  if (!hasQr) add(l10n.metaQr, record.rawQr);

  return rows;
}

class ReceiptMetadataTile extends StatelessWidget {
  const ReceiptMetadataTile({super.key, required this.record});

  final ReceiptRecord record;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final rows = receiptMetadataRows(record, l10n);
    if (rows.isEmpty) return const SizedBox.shrink();

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 4),
        title: Text(l10n.metadataSection, style: const TextStyle(fontWeight: FontWeight.w600)),
        children: [
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 128,
                    child: Text(
                      row.label,
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(row.value, style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

bool _isInternalKey(String key) {
  return key.startsWith('checkscan.') && key != _qrRawExtension;
}

String _receiptTypeLabel(String type, AppLocalizations l10n) {
  return switch (type) {
    'refund' => l10n.metaReceiptTypeRefund,
    'sale' => l10n.metaReceiptTypeSale,
    _ => type,
  };
}

String _formatValue(Object? value, AppLocalizations l10n) {
  if (value == null) return '';
  if (value is bool) return value ? l10n.metaYes : l10n.metaNo;
  if (value is String) return value.trim();
  if (value is num && value == value.roundToDouble()) return value.round().toString();
  return '$value';
}
