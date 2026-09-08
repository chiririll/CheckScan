import 'package:sqflite/sqflite.dart';

import '../storage/migrations/migration.dart';
import 'merchant.dart';

class KnownMerchantSeed {
  const KnownMerchantSeed({
    required this.name,
    required this.aliases,
    this.policy = MerchantPolicy.parse,
    this.categoryKey,
  });

  final String name;
  final List<String> aliases;
  final String policy;
  final String? categoryKey;
}

const knownMerchantSeeds = [
  KnownMerchantSeed(name: 'Maxi', aliases: ['DELHAIZE SERBIA DOO BEOGRAD', 'Maxi']),
  KnownMerchantSeed(name: 'Магнит', aliases: ['Магнит', 'Магазин  Магнит  Кузьминское']),
  KnownMerchantSeed(name: 'Idea', aliases: ['Idea Marketi doo', 'Idea']),
  KnownMerchantSeed(name: 'Univerexport', aliases: ['UNIVEREXPORT']),
  KnownMerchantSeed(name: 'dm', aliases: ['dm drogerie markt doo Beograd', 'dm']),
  KnownMerchantSeed(
    name: 'JGSP',
    aliases: ['JGSP NOVI SAD', 'JGSP'],
    policy: MerchantPolicy.ignore,
    categoryKey: '#transport',
  ),
  KnownMerchantSeed(
    name: 'Konoba',
    aliases: ['KONOBA RIBA RIBI GRIZE REP DOO', 'KONOBA'],
    policy: MerchantPolicy.ignore,
    categoryKey: '#cafe',
  ),
  KnownMerchantSeed(
    name: 'Yettel',
    aliases: ['Yettel d.o.o.', 'Yettel'],
    policy: MerchantPolicy.ignore,
  ),
];

Future<void> seedKnownMerchants(DatabaseExecutor db) async {
  if (!await tableExists(db, 'merchant')) return;
  final categoryIds = <String, int>{};
  if (await tableExists(db, 'category')) {
    for (final row in await db.query('category')) {
      categoryIds['${row['name']}'] = (row['id'] as num).toInt();
    }
  }

  for (final seed in knownMerchantSeeds) {
    final existing = await db.query('merchant', where: 'name = ?', whereArgs: [seed.name], limit: 1);
    var merchantId = existing.isEmpty ? null : (existing.first['id'] as num).toInt();
    if (merchantId == null) {
      merchantId = await db.insert('merchant', {
        'name': seed.name,
        'policy': seed.policy,
        'category_id': seed.categoryKey == null ? null : categoryIds[seed.categoryKey!],
      });
    }
    for (final alias in seed.aliases) {
      final hit = await db.query('merchant_alias', where: 'name = ?', whereArgs: [alias], limit: 1);
      if (hit.isNotEmpty) continue;
      await db.insert('merchant_alias', {
        'name': alias,
        'merchant_id': merchantId,
      });
    }
  }
}
