import 'package:drift/drift.dart';

import 'occurrences.dart';
import 'subtasks.dart';

/// Haken bei einem Unterschritt an einem konkreten Tag.
class SubtaskChecks extends Table {
  TextColumn get occurrenceId =>
      text().references(Occurrences, #id, onDelete: KeyAction.cascade)();
  TextColumn get subtaskId =>
      text().references(Subtasks, #id, onDelete: KeyAction.cascade)();
  BoolColumn get done => boolean()();

  @override
  Set<Column> get primaryKey => {occurrenceId, subtaskId};
}
