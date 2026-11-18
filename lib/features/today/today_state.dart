import '../../core/db/app_database.dart';
import '../tasks/task_repository.dart';
import 'day_plan_repository.dart';

/// Was „Heute“ zeigt: die Energie, der Tagesplan und ob es noch mehr gäbe.
class TodayState {
  const TodayState({
    required this.energy,
    required this.plan,
    required this.hasMore,
  });

  /// Die gewählte Energie, oder `null`, solange der Energie-Check offen ist.
  final Energy? energy;

  /// Die Aufgaben des Tages in der Reihenfolge des Plans.
  final List<TaskListEntry> plan;

  /// Gibt es noch offene Aufgaben außerhalb des Plans?
  final bool hasMore;

  /// Der nächste Schritt: die erste Aufgabe des Plans, die noch offen ist.
  TaskListEntry? get next => plan.where((entry) => !entry.done).firstOrNull;

  int get doneCount => plan.where((entry) => entry.done).length;
}

/// Setzt den Plan von heute mit den Aufgaben zusammen. Aufgaben, die es nicht
/// mehr gibt, fallen weg.
TodayState buildTodayState(DayPlan? plan, List<TaskListEntry> tasks) {
  final ids = plan?.taskIds ?? const <String>[];
  final byId = {for (final entry in tasks) entry.task.id: entry};
  return TodayState(
    energy: plan?.energy,
    plan: [for (final id in ids) ?byId[id]],
    hasMore: tasks.any(
      (entry) =>
          !entry.done && entry.task.active && !ids.contains(entry.task.id),
    ),
  );
}
