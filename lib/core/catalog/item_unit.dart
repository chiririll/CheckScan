enum ItemUnit {
  piece,
  pack,
  kg,
  g,
  l,
  ml;

  static ItemUnit? tryParse(String? code) {
    if (code == null || code.isEmpty) return null;
    for (final value in ItemUnit.values) {
      if (value.name == code) return value;
    }
    return null;
  }
}
