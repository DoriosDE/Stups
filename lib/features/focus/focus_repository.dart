import 'package:drift/drift.dart';

import '../../core/db/app_database.dart';
import '../inbox/inbox_repository.dart';
import '../tasks/task_repository.dart';
import 'focus_session.dart';

/// Fokus-Sitzungen: Start, Verlängern, Beenden und der Ablenkungs-Parkplatz.
///
/// Es gibt höchstens eine Sitzung. Sie steht samt Endzeitpunkt in der Tabelle
/// `Settings` (Schlüssel [_key]) und überlebt so den Hintergrundbetrieb und
/// einen Neustart der App.
class FocusRepository {
  /// [now] liefert den aktuellen Zeitpunkt; Tests legen ihn fest.
  FocusRepository(this._db, {DateTime Function() now = DateTime.now})
    : _now = now,
      _tasks = TaskRepository(_db, now: now),
      _inbox = InboxRepository(_db);

  static const _key = 'focusSession';

  final AppDatabase _db;
  final DateTime Function() _now;
  final TaskRepository _tasks;
  final InboxRepository _inbox;

  /// Die laufende Sitzung; `null`, wenn keine läuft.
  Stream<FocusSession?> watch() {
    final query = _db.select(_db.settings)..where((s) => s.key.equals(_key));
    return query.watchSingleOrNull().map(
      (row) => row == null ? null : FocusSession.fromJson(row.value),
    );
  }

  /// Beginnt eine Sitzung von [length] und ersetzt eine laufende.
  Future<FocusSession> start(String taskId, Duration length) async {
    final occurrenceId = await _tasks.startToday(taskId);
    final session = FocusSession.start(
      taskId: taskId,
      occurrenceId: occurrenceId,
      now: _now(),
      length: length,
    );
    await _save(session);
    return session;
  }

  /// Verlängert die laufende Sitzung um [by] („Noch 5 Minuten“).
  Future<void> extend(Duration by) async {
    final session = await _current();
    if (session == null) return;
    await _save(session.extended(by, now: _now()));
  }

  /// Beendet die Sitzung („Für heute reicht’s“, oder weil die Aufgabe erledigt
  /// ist). Das Vorkommen bleibt, wie es ist.
  Future<void> stop() async {
    await (_db.delete(_db.settings)..where((s) => s.key.equals(_key))).go();
  }

  /// Parkt einen Einfall: Er landet in der Inbox, und als Notiz bleibt
  /// vermerkt, aus welchem Vorkommen er kam.
  Future<void> park(String text, {String? occurrenceId}) async {
    final content = text.trim();
    if (content.isEmpty) return;
    await _db.transaction(() async {
      await _inbox.add(content);
      await _db
          .into(_db.distractionNotes)
          .insert(
            DistractionNotesCompanion.insert(
              content: content,
              occurrenceId: Value(occurrenceId),
            ),
          );
    });
  }

  Future<FocusSession?> _current() async {
    final row = await (_db.select(
      _db.settings,
    )..where((s) => s.key.equals(_key))).getSingleOrNull();
    return row == null ? null : FocusSession.fromJson(row.value);
  }

  Future<void> _save(FocusSession session) async {
    await _db
        .into(_db.settings)
        .insertOnConflictUpdate(
          SettingsCompanion.insert(key: _key, value: session.toJson()),
        );
  }
}
