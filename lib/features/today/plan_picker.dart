import '../../core/db/app_database.dart';

/// Mehr als drei Aufgaben schlägt „Heute“ nie vor (siehe docs/SPEC.md).
const maxPlanSize = 3;

/// Wie viele Aufgaben zur Energie am Morgen passen: wenig 1, mittel 2, viel 3.
int planSizeFor(Energy energy) => switch (energy) {
  Energy.low => 1,
  Energy.medium => 2,
  Energy.high => 3,
};

/// Wählt bis zu [count] Aufgaben (höchstens [maxPlanSize]) für den Tag.
///
/// Zuerst A, dann B, dann C; darin die früheste Fälligkeit zuerst, Aufgaben
/// ohne Fälligkeit zuletzt, dann die ältere. [tasks] sind die offenen
/// Aufgaben; gesperrte (inaktive) und die in [exclude] fallen weg.
List<String> pickPlanTaskIds(
  Iterable<Task> tasks, {
  required int count,
  Set<String> exclude = const {},
}) {
  final candidates = [
    for (final task in tasks)
      if (task.active && !exclude.contains(task.id)) task,
  ]..sort(_planOrder);
  final limit = count.clamp(0, maxPlanSize);
  return [for (final task in candidates.take(limit)) task.id];
}

int _planOrder(Task a, Task b) {
  final byPriority = a.priority.index.compareTo(b.priority.index);
  if (byPriority != 0) return byPriority;
  final byDue = switch ((a.dueDate, b.dueDate)) {
    (null, null) => 0,
    (null, _) => 1,
    (_, null) => -1,
    (final x?, final y?) => x.compareTo(y),
  };
  if (byDue != 0) return byDue;
  return a.createdAt.compareTo(b.createdAt);
}
