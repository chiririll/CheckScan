extension IterableLookup<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T item) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }

  /// Insertion-ordered groups.
  Map<K, List<T>> groupBy<K>(K Function(T item) key) {
    final groups = <K, List<T>>{};
    for (final item in this) {
      groups.putIfAbsent(key(item), () => []).add(item);
    }
    return groups;
  }
}

/// Blank or whitespace-only → null, otherwise trimmed.
String? trimmedOrNull(String? raw) {
  final trimmed = raw?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
