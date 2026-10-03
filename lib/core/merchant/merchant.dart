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
    this.aliases = const [],
  });

  final String id;
  final String name;

  /// Network (chain) this store belongs to.
  final String? parentId;
  final List<MerchantAlias> aliases;
}
