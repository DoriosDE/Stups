import 'package:drift/drift.dart';

import '../../core/db/app_database.dart';
import '../../core/db/day_key.dart';

/// Ein Schritt einer Aufgabe beim Anlegen oder Bearbeiten.
///
/// Der erste Schritt der Liste ist der „allererste Mini-Schritt“; es gibt kein
/// Sonderfeld dafür. Ein bestehender Schritt trägt seine [id], damit seine
/// Haken beim Bearbeiten an ihm bleiben und nicht am Text oder an der Position.
class StepDraft {
  /// Ein neuer Schritt.
  const StepDraft(this.title) : id = null;

  /// Ein Schritt, den es schon gibt.
  const StepDraft.existing(String this.id, this.title);

  final String? id;
  final String title;
}

/// Was man beim Anlegen oder Bearbeiten einer Aufgabe angibt.
class TaskDraft {
  const TaskDraft({
    required this.title,
    required this.areaId,
    this.steps = const [],
    this.estimateMin,
    this.priority = Priority.b,
    this.dueDate,
    this.reminderAt,
  });

  final String title;
  final String areaId;

  /// Die Schritte in ihrer Reihenfolge; der erste ist der allererste
  /// Mini-Schritt.
  final List<StepDraft> steps;
  final int? estimateMin;
  final Priority priority;

  /// Nur der Kalendertag zählt.
  final DateTime? dueDate;
  final DateTime? reminderAt;

  /// Ohne Leerraum am Rand; leere Schritte fallen weg; eine Schätzung von 0
  /// Minuten gilt als keine Schätzung. Ein leerer Titel ist ein Fehler, denn
  /// eine Aufgabe ohne Titel gibt es nicht.
  TaskDraft _cleaned() {
    final cleanTitle = title.trim();
    if (cleanTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'darf nicht leer sein');
    }
    return TaskDraft(
      title: cleanTitle,
      areaId: areaId,
      steps: [
        for (final step in steps)
          if (step.title.trim().isNotEmpty)
            step.id == null
                ? StepDraft(step.title.trim())
                : StepDraft.existing(step.id!, step.title.trim()),
      ],
      estimateMin: estimateMin != null && estimateMin! > 0 ? estimateMin : null,
      priority: priority,
      dueDate: dueDate,
      reminderAt: reminderAt,
    );
  }
}

/// Eine Aufgabe mit ihren Unterschritten und, wenn sie erledigt wurde, dem
/// jüngsten Vorkommen.
class TaskDetail {
  const TaskDetail({
    required this.task,
    required this.subtasks,
    this.occurrence,
  });

  final Task task;
  final List<Subtask> subtasks;
  final Occurrence? occurrence;
}

/// Eine Zeile der Aufgabenliste.
class TaskListEntry {
  const TaskListEntry({required this.task, required this.done});

  final Task task;
  final bool done;
}

/// Aufgaben anlegen, bearbeiten und erledigen.
class TaskRepository {
  /// [now] liefert den aktuellen Zeitpunkt; Tests legen ihn fest.
  TaskRepository(this._db, {this._now = DateTime.now});

  final AppDatabase _db;
  final DateTime Function() _now;

  Future<String> create(TaskDraft input) async {
    final draft = input._cleaned();
    return _db.transaction(() async {
      final task = await _db
          .into(_db.tasks)
          .insertReturning(
            TasksCompanion.insert(
              areaId: draft.areaId,
              title: draft.title,
              estimateMin: Value(draft.estimateMin),
              priority: Value(draft.priority),
              dueDate: Value(_dayText(draft.dueDate)),
              reminderAt: Value(draft.reminderAt),
            ),
          );
      await _insertSteps(task.id, draft.steps);
      return task.id;
    });
  }

  /// Ersetzt alle Felder und Schritte der Aufgabe [id] durch [input].
  Future<void> update(String id, TaskDraft input) async {
    final draft = input._cleaned();
    await _db.transaction(() async {
      await (_db.update(_db.tasks)..where((t) => t.id.equals(id))).write(
        TasksCompanion(
          areaId: Value(draft.areaId),
          title: Value(draft.title),
          estimateMin: Value(draft.estimateMin),
          priority: Value(draft.priority),
          dueDate: Value(_dayText(draft.dueDate)),
          reminderAt: Value(draft.reminderAt),
        ),
      );
      await _syncSteps(id, draft.steps);
    });
  }

  /// Gleicht die Schritte der Aufgabe mit [steps] ab, und zwar über die ID:
  /// Bestehende Schritte behalten ihre Zeile (und damit ihre Haken) und
  /// bekommen Text und Platz aus der Liste, neue werden angelegt, und Schritte,
  /// die nicht mehr in der Liste stehen, fallen mit ihren Haken weg.
  Future<void> _syncSteps(String taskId, List<StepDraft> steps) async {
    final existing = await (_db.select(
      _db.subtasks,
    )..where((s) => s.taskId.equals(taskId))).get();
    final existingIds = {for (final step in existing) step.id};
    final keptIds = {
      for (final step in steps)
        if (step.id != null && existingIds.contains(step.id)) step.id!,
    };
    for (final step in existing) {
      if (!keptIds.contains(step.id)) {
        await (_db.delete(
          _db.subtasks,
        )..where((s) => s.id.equals(step.id))).go();
      }
    }
    for (final (index, step) in steps.indexed) {
      if (keptIds.contains(step.id)) {
        await (_db.update(
          _db.subtasks,
        )..where((s) => s.id.equals(step.id!))).write(
          SubtasksCompanion(title: Value(step.title), sortOrder: Value(index)),
        );
      } else {
        await _insertStep(taskId, index, step.title);
      }
    }
  }

  Future<void> _insertSteps(String taskId, List<StepDraft> steps) async {
    for (final (index, step) in steps.indexed) {
      await _insertStep(taskId, index, step.title);
    }
  }

  Future<void> _insertStep(String taskId, int index, String title) async {
    await _db
        .into(_db.subtasks)
        .insert(
          SubtasksCompanion.insert(
            taskId: taskId,
            title: title,
            sortOrder: index,
          ),
        );
  }

  /// Die sichtbaren Bereiche in der Reihenfolge, in der sie angelegt wurden.
  Stream<List<Area>> watchAreas() {
    final query = _db.select(_db.areas)
      ..where((a) => a.hidden.equals(false))
      ..orderBy([(a) => OrderingTerm.asc(CustomExpression<int>('rowid'))]);
    return query.watch();
  }

  /// Alle Aufgaben, oder nur die eines Bereichs.
  Stream<List<TaskListEntry>> watchTasks({String? areaId}) {
    final query = _db.select(_db.tasks).join([
      leftOuterJoin(
        _db.occurrences,
        _db.occurrences.taskId.equalsExp(_db.tasks.id) &
            _db.occurrences.status.equalsValue(OccurrenceStatus.done),
      ),
    ]);
    if (areaId != null) query.where(_db.tasks.areaId.equals(areaId));
    return query.watch().map((rows) {
      // Eine Aufgabe kann an mehreren Tagen erledigt sein: eine Zeile je Tag.
      final entries = <String, TaskListEntry>{};
      for (final row in rows) {
        final task = row.readTable(_db.tasks);
        final done = row.readTableOrNull(_db.occurrences) != null;
        entries[task.id] = TaskListEntry(
          task: task,
          done: done || (entries[task.id]?.done ?? false),
        );
      }
      return entries.values.toList()..sort(_listOrder);
    });
  }

  /// Offene Aufgaben zuerst, darin A vor B vor C, dann die ältere zuerst.
  static int _listOrder(TaskListEntry a, TaskListEntry b) {
    final byDone = (a.done ? 1 : 0).compareTo(b.done ? 1 : 0);
    if (byDone != 0) return byDone;
    final byPriority = a.task.priority.index.compareTo(b.task.priority.index);
    if (byPriority != 0) return byPriority;
    return a.task.createdAt.compareTo(b.task.createdAt);
  }

  /// Hält fest, dass die Aufgabe heute erledigt wurde, und wie lange es dauerte.
  Future<void> complete(String taskId, {required int actualMin}) async {
    final now = _now();
    final done = OccurrencesCompanion(
      status: Value(OccurrenceStatus.done),
      completedAt: Value(now),
      actualMin: Value(actualMin),
    );
    await _db
        .into(_db.occurrences)
        .insert(
          done.copyWith(taskId: Value(taskId), date: Value(_dayText(now)!)),
          onConflict: DoUpdate(
            (old) => done,
            target: [_db.occurrences.taskId, _db.occurrences.date],
          ),
        );
  }

  /// Hält fest, dass die Aufgabe heute begonnen wurde, und liefert die ID des
  /// Vorkommens von heute. Gibt es heute schon eines (begonnen oder erledigt),
  /// bleibt es unverändert.
  Future<String> startToday(String taskId) async {
    final now = _now();
    final date = _dayText(now)!;
    await _db
        .into(_db.occurrences)
        .insert(
          OccurrencesCompanion.insert(
            taskId: taskId,
            date: date,
            status: Value(OccurrenceStatus.started),
            startedAt: Value(now),
          ),
          mode: InsertMode.insertOrIgnore,
        );
    final occurrence = await (_db.select(
      _db.occurrences,
    )..where((o) => o.taskId.equals(taskId) & o.date.equals(date))).getSingle();
    return occurrence.id;
  }

  /// Die Taten: so viele erledigte Vorkommen gibt es. Es gibt keine eigene
  /// Tabelle dafür (siehe docs/SPEC.md, Datenmodell). Ein Vorkommen gilt pro
  /// Aufgabe und Tag einmal, wer es zweimal erledigt, hat keine zweite Tat.
  Stream<int> watchDeedCount() {
    final count = _db.occurrences.id.count();
    final query = _db.selectOnly(_db.occurrences)
      ..addColumns([count])
      ..where(_db.occurrences.status.equalsValue(OccurrenceStatus.done));
    return query.map((row) => row.read(count)!).watchSingle();
  }

  Stream<TaskDetail?> watchTask(String id) {
    // Schritte und Vorkommen hängen beide an der Aufgabe, deshalb kommen die
    // Zeilen als Kreuzprodukt; die Schritte werden danach nach ID bereinigt.
    final query =
        _db.select(_db.tasks).join([
            leftOuterJoin(
              _db.subtasks,
              _db.subtasks.taskId.equalsExp(_db.tasks.id),
            ),
            // Nur erledigte Vorkommen: ein begonnenes macht die Aufgabe nicht
            // zur erledigten.
            leftOuterJoin(
              _db.occurrences,
              _db.occurrences.taskId.equalsExp(_db.tasks.id) &
                  _db.occurrences.status.equalsValue(OccurrenceStatus.done),
            ),
          ])
          ..where(_db.tasks.id.equals(id))
          ..orderBy([
            OrderingTerm.asc(_db.subtasks.sortOrder),
            OrderingTerm.desc(_db.occurrences.date),
          ]);
    return query.watch().map((rows) {
      if (rows.isEmpty) return null;
      final steps = <String, Subtask>{};
      for (final row in rows) {
        final step = row.readTableOrNull(_db.subtasks);
        if (step != null) steps[step.id] = step;
      }
      return TaskDetail(
        task: rows.first.readTable(_db.tasks),
        subtasks: steps.values.toList(),
        occurrence: rows
            .map((row) => row.readTableOrNull(_db.occurrences))
            .nonNulls
            .firstOrNull,
      );
    });
  }
}

String? _dayText(DateTime? day) => day == null ? null : dayKey(day);
