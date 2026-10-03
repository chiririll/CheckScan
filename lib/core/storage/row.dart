/// Typed reads from a sqflite row. Ids are stored as INTEGER and exposed as String.
extension RowRead on Map<String, Object?> {
  String str(String key) => '${this[key] ?? ''}';

  String? optStr(String key) => this[key] == null ? null : '${this[key]}';

  int? optInt(String key) => (this[key] as num?)?.toInt();

  double? optDouble(String key) => (this[key] as num?)?.toDouble();

  DateTime? date(String key) => DateTime.tryParse('${this[key]}');
}

/// String id → INTEGER column value.
int dbId(String id) => int.parse(id);
