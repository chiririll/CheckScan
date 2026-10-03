import 'package:sqflite/sqflite.dart';

import '../storage/database.dart';
import '../storage/row.dart';
import '../util/collections.dart';
import 'merchant.dart';

class MerchantRepository {
  MerchantRepository({required this.database});

  final CheckScanDatabase database;

  Future<Database> get _db => database.database;

  Future<List<Merchant>> listAll() async {
    final db = await _db;
    final rows = await db.query('merchant', orderBy: 'name ASC');
    final aliasRows = await db.query('merchant_alias');
    final aliases = <String, List<MerchantAlias>>{};
    for (final row in aliasRows) {
      aliases.putIfAbsent(row.str('merchant_id'), () => []).add(
        MerchantAlias(id: row.str('id'), name: row.optStr('name'), taxId: row.optStr('tax_id')),
      );
    }
    return [
      for (final row in rows)
        Merchant(
          id: row.str('id'),
          name: row.str('name'),
          parentId: row.optStr('parent_id'),
          policy: MerchantPolicy.normalize(row.optStr('policy')),
          categoryId: row.optStr('category_id'),
          aliases: aliases[row.str('id')] ?? const [],
        ),
    ];
  }

  Future<Merchant?> findById(String id) async => (await listAll()).firstWhereOrNull((merchant) => merchant.id == id);

  /// Merchant id for a receipt: by tax id, then by name, else a new merchant.
  Future<String> resolve({String? name, String? taxId}) async {
    final trimmedTax = trimmedOrNull(taxId);
    final trimmedName = trimmedOrNull(name);
    return (await _db).transaction((txn) async {
      for (final (column, value) in [('tax_id', trimmedTax), ('name', trimmedName)]) {
        if (value == null) continue;
        final rows = await txn.query('merchant_alias', where: '$column = ?', whereArgs: [value], limit: 1);
        if (rows.isNotEmpty) return rows.first.str('merchant_id');
      }
      final merchantId = await txn.insert('merchant', {
        'name': trimmedName ?? '—',
        'policy': MerchantPolicy.parse,
      });
      await txn.insert('merchant_alias', {
        'name': trimmedName,
        'tax_id': trimmedTax,
        'merchant_id': merchantId,
      });
      return '$merchantId';
    });
  }

  Future<void> update(
    String id, {
    String? name,
    String? parentId,
    bool clearParent = false,
    String? policy,
    String? categoryId,
    bool clearCategory = false,
  }) async {
    final values = <String, Object?>{
      'name': ?name?.trim(),
      if (clearParent) 'parent_id': null else if (parentId != null && parentId != id) 'parent_id': dbId(parentId),
      if (policy != null) 'policy': MerchantPolicy.normalize(policy),
      if (clearCategory) 'category_id': null else if (categoryId != null) 'category_id': dbId(categoryId),
    };
    if (values.isEmpty) return;
    await (await _db).update('merchant', values, where: 'id = ?', whereArgs: [dbId(id)]);
  }

  Future<void> addAlias(String merchantId, {String? name, String? taxId}) async {
    final trimmedName = trimmedOrNull(name);
    final trimmedTax = trimmedOrNull(taxId);
    if (trimmedName == null && trimmedTax == null) return;
    await (await _db).insert('merchant_alias', {
      'name': trimmedName,
      'tax_id': trimmedTax,
      'merchant_id': dbId(merchantId),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
