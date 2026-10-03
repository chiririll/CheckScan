extension IterableLookup<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T item) test) {
    for (final item in this) {
      if (test(item)) return item;
    }
    return null;
  }

  Map<K, T> indexBy<K>(K Function(T item) key) => {for (final item in this) key(item): item};

  /// Insertion-ordered groups.
  Map<K, List<T>> groupBy<K>(K Function(T item) key) {
    final groups = <K, List<T>>{};
    for (final item in this) {
      groups.putIfAbsent(key(item), () => []).add(item);
    }
    return groups;
  }
}

/// Case-insensitive substring filter; an empty query keeps everything.
List<T> filterByQuery<T>(Iterable<T> items, String query, Iterable<String> Function(T item) fields) {
  final needle = query.trim().toLowerCase();
  if (needle.isEmpty) return items.toList();
  return [
    for (final item in items)
      if (fields(item).any((field) => field.toLowerCase().contains(needle))) item,
  ];
}

/// Blank or whitespace-only → null, otherwise trimmed.
String? trimmedOrNull(String? raw) {
  final trimmed = raw?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}
