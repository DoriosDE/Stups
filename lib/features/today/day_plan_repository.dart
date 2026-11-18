import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/db/app_database.dart';
import 'plan_picker.dart';

extension DayPlanTasks on DayPlan {
  /// Die geplanten Aufgaben-IDs in ihrer Reihenfolge.
  List<String> get taskIds => [
    for (final id in jsonDecode(plannedTaskIds) as List<dynamic>) id as String,
  ];
}

/// Der Tagesplan: Energie am Morgen und die gewählten Aufgaben.
///
/// Der Plan gilt für genau einen Kalendertag. Was am Abend offen ist, verfällt
/// einfach: Am nächsten Tag gibt es einen neuen Plan, die Aufgabe bleibt in der
/// Aufgabenliste.
class DayPlanRepository {
  DayPlanRepository(this._db);

  final AppDatabase _db;

  /// Der Plan für [day] (`yyyy-MM-dd`), oder `null`, solange es keinen gibt.
  Stream<DayPlan?> watchPlan(String day) {
    return (_db.select(
      _db.dayPlans,
    )..where((p) => p.date.equals(day))).watchSingleOrNull();
  }

  /// Merkt sich die Energie und wählt dazu die Aufgaben.
  ///
  /// Was heute schon erledigt wurde, bleibt im Plan und zählt mit; der Rest
  /// wird bis zur Anzahl der Energie aufgefüllt.
  Future<void> chooseEnergy(String day, Energy energy) {
    return _db.transaction(() async {
      final old = await _plannedIds(day);
      final doneToday = await _doneTaskIds(day: day);
      final kept = [
        for (final id in old)
          if (doneToday.contains(id)) id,
      ];
      final picked = pickPlanTaskIds(
        await _openTasks(),
        count: planSizeFor(energy) - kept.length,
        exclude: kept.toSet(),
      );
      await _save(day, energy: Value(energy), ids: [...kept, ...picked]);
    });
  }

  /// „Doch noch eine Aufgabe“: nimmt die nächste offene Aufgabe in den Plan,
  /// auch über die Energie hinaus. Gibt es keine mehr, bleibt alles, wie es ist.
  Future<void> addOneMore(String day) {
    return _db.transaction(() async {
      final ids = await _plannedIds(day);
      final next = pickPlanTaskIds(
        await _openTasks(),
        count: 1,
        exclude: ids.toSet(),
      );
      if (next.isEmpty) return;
      await _save(day, ids: [...ids, ...next]);
    });
  }

  /// „Morgen nochmal?“: nimmt die Aufgabe aus dem Plan von [day]. Sie bleibt
  /// unverändert in der Aufgabenliste.
  Future<void> dropFromPlan(String day, String taskId) {
    return _db.transaction(() async {
      final ids = await _plannedIds(day);
      await _save(
        day,
        ids: [
          for (final id in ids)
            if (id != taskId) id,
        ],
      );
    });
  }

  Future<List<String>> _plannedIds(String day) async {
    final plan = await (_db.select(
      _db.dayPlans,
    )..where((p) => p.date.equals(day))).getSingleOrNull();
    return plan?.taskIds ?? const [];
  }

  Future<void> _save(
    String day, {
    Value<Energy?> energy = const Value.absent(),
    required List<String> ids,
  }) async {
    await _db
        .into(_db.dayPlans)
        .insert(
          DayPlansCompanion(
            date: Value(day),
            energy: energy,
            plannedTaskIds: Value(jsonEncode(ids)),
          ),
          onConflict: DoUpdate(
            (old) => DayPlansCompanion(
              energy: energy,
              plannedTaskIds: Value(jsonEncode(ids)),
            ),
            target: [_db.dayPlans.date],
          ),
        );
  }

  /// Aufgaben, die noch nie erledigt wurden. Eine Aufgabe ist einmalig und hat
  /// genau ein Vorkommen (siehe docs/SPEC.md, Datenmodell).
  Future<List<Task>> _openTasks() async {
    final done = await _doneTaskIds();
    final tasks = await _db.select(_db.tasks).get();
    return [
      for (final task in tasks)
        if (!done.contains(task.id)) task,
    ];
  }

  /// Aufgaben mit erledigtem Vorkommen, oder nur die an [day] erledigten.
  Future<Set<String>> _doneTaskIds({String? day}) async {
    final query = _db.select(_db.occurrences)
      ..where((o) => o.status.equalsValue(OccurrenceStatus.done));
    if (day != null) query.where((o) => o.date.equals(day));
    return {for (final o in await query.get()) o.taskId};
  }
}
