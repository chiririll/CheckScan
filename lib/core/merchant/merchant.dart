class MerchantPolicy {
  static const parse = 'parse';
  static const ignore = 'ignore';

  static String normalize(String? raw) => raw == ignore ? ignore : parse;
}

class MerchantAlias {
  const MerchantAlias({required this.id, this.name, this.taxId});

  final String id;
  final String? name;
  final String? taxId;
}

class Merchant {
  const Merchant({
    required this.id,
    required this.name,
    this.parentId,
    this.policy = MerchantPolicy.parse,
    this.categoryId,
    this.aliases = const [],
  });

  final String id;
  final String name;
  final String? parentId;
  final String policy;
  final String? categoryId;
  final List<MerchantAlias> aliases;

  bool get ignoresItems => policy == MerchantPolicy.ignore;

  String get networkId => parentId ?? id;
}
