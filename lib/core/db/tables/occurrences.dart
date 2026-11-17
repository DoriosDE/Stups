import 'package:drift/drift.dart';

import '../enums.dart';
import '../defaults.dart';
import 'tasks.dart';

/// Ein Tag einer Aufgabe. Wird erst gespeichert, wenn jemand die Aufgabe
/// startet, erledigt, verschiebt oder auslässt (siehe docs/SPEC.md).
class Occurrences extends Table {
  TextColumn get id => text().clientDefault(newId)();
  TextColumn get taskId =>
      text().references(Tasks, #id, onDelete: KeyAction.cascade)();

  /// Kalendertag als lokaler Text `yyyy-MM-dd`.
  TextColumn get date => text()();
  TextColumn get status => textEnum<OccurrenceStatus>().withDefault(
    Constant(OccurrenceStatus.open.name),
  )();
  DateTimeColumn get startedAt => dateTime().nullable()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get actualMin => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {taskId, date},
  ];

  @override
  List<String> get customConstraints => [
    "CHECK (date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
  ];
}
