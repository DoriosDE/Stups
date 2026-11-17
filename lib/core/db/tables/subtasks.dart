import 'package:drift/drift.dart';

import '../ids.dart';
import 'tasks.dart';

/// Unterschritte einer Aufgabe, in der Reihenfolge von [sortOrder].
class Subtasks extends Table {
  TextColumn get id => text().clientDefault(newId)();
  TextColumn get taskId =>
      text().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
