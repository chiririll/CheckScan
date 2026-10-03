
class HomePeriod {
  const HomePeriod({required this.year, required this.month});

  factory HomePeriod.current([DateTime? now]) {
    final n = now ?? DateTime.now();
    return HomePeriod(year: n.year, month: n.month);
  }

  final int year;
  final int month;

  DateTime get asDate => DateTime(year, month);

  bool contains(DateTime date) => date.year == year && date.month == month;

  HomePeriod get previous => month == 1
      ? HomePeriod(year: year - 1, month: 12)
      : HomePeriod(year: year, month: month - 1);

  HomePeriod get next => month == 12
      ? HomePeriod(year: year + 1, month: 1)
      : HomePeriod(year: year, month: month + 1);

  bool isBefore(HomePeriod other) => year < other.year || (year == other.year && month < other.month);

  @override
  bool operator ==(Object other) => other is HomePeriod && year == other.year && month == other.month;

  @override
  int get hashCode => Object.hash(year, month);
}
