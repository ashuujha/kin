({DateTime from, DateTime to}) calendarMonth(
  DateTime now, {
  bool previous = false,
}) {
  final start = DateTime(now.year, now.month - (previous ? 1 : 0), 1);
  final end = DateTime(start.year, start.month + 1, 0);
  return (from: start, to: end);
}
