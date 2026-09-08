import 'package:sqflite/sqflite.dart';

import '../storage/database.dart';
import 'merchant.dart';
import 'merchant_seeder.dart';

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
      aliases.putIfAbsent('${row['merchant_id']}', () => []).add(
        MerchantAlias(
          id: '${row['id']}',
          name: row['name'] as String?,
          taxId: row['tax_id'] as String?,
        ),
      );
    }
    return [
      for (final row in rows)
        Merchant(
          id: '${row['id']}',
          name: '${row['name']}',
          parentId: row['parent_id'] == null ? null : '${row['parent_id']}',
          policy: MerchantPolicy.normalize(row['policy'] as String?),
          categoryId: row['category_id'] == null ? null : '${row['category_id']}',
          aliases: aliases['${row['id']}'] ?? const [],
        ),
    ];
  }

  Future<Merchant?> findById(String id) async {
    for (final merchant in await listAll()) {
      if (merchant.id == id) return merchant;
    }
    return null;
  }

  Future<String> resolve({String? name, String? taxId}) async {
    final db = await _db;
    return db.transaction((txn) async {
      final trimmedTax = taxId == null || taxId.trim().isEmpty ? null : taxId.trim();
      final trimmedName = name == null || name.trim().isEmpty ? null : name.trim();
      if (trimmedTax != null) {
        final byTax = await txn.query('merchant_alias', where: 'tax_id = ?', whereArgs: [trimmedTax], limit: 1);
        if (byTax.isNotEmpty) return '${byTax.first['merchant_id']}';
      }
      if (trimmedName != null) {
        final byName = await txn.query('merchant_alias', where: 'name = ?', whereArgs: [trimmedName], limit: 1);
        if (byName.isNotEmpty) return '${byName.first['merchant_id']}';
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
    final values = <String, Object?>{};
    if (name != null) values['name'] = name.trim();
    if (clearParent) {
      values['parent_id'] = null;
    } else if (parentId != null && parentId != id) {
      values['parent_id'] = int.parse(parentId);
    }
    if (policy != null) values['policy'] = MerchantPolicy.normalize(policy);
    if (clearCategory) {
      values['category_id'] = null;
    } else if (categoryId != null) {
      values['category_id'] = int.parse(categoryId);
    }
    if (values.isEmpty) return;
    await (await _db).update('merchant', values, where: 'id = ?', whereArgs: [int.parse(id)]);
  }

  Future<void> addAlias(String merchantId, {String? name, String? taxId}) async {
    final trimmedName = name == null || name.trim().isEmpty ? null : name.trim();
    final trimmedTax = taxId == null || taxId.trim().isEmpty ? null : taxId.trim();
    if (trimmedName == null && trimmedTax == null) return;
    await (await _db).insert('merchant_alias', {
      'name': trimmedName,
      'tax_id': trimmedTax,
      'merchant_id': int.parse(merchantId),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> seedIfNeeded() async {
    await seedKnownMerchants(await _db);
  }
}
