class SuggestionIgnore {
  const SuggestionIgnore({
    this.clusterItemIds = const {},
    this.productItemKeys = const {},
  });

  final Set<String> clusterItemIds;
  final Set<String> productItemKeys;

  bool ignoresCluster(String itemId) => clusterItemIds.contains(itemId);

  bool ignoresProduct(String productId, String itemId) => productItemKeys.contains(productKey(productId, itemId));

  static String productKey(String productId, String itemId) => '$productId|$itemId';
}
