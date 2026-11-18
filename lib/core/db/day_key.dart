/// Kalendertag als lokaler Text `yyyy-MM-dd` (siehe docs/HANDOFF.md).
String dayKey(DateTime day) {
  final month = day.month.toString().padLeft(2, '0');
  final date = day.day.toString().padLeft(2, '0');
  return '${day.year.toString().padLeft(4, '0')}-$month-$date';
}
