import 'package:drift/drift.dart';

import '../enums.dart';
import '../defaults.dart';
import 'areas.dart';

/// Aufgaben, die gemeinsame Regel für alle Bereiche. Konkrete Tage stehen in
/// `Occurrences`.
class Tasks extends Table {
  TextColumn get id => text().clientDefault(newId)();
  TextColumn get areaId =>
      text().references(Areas, #id, onDelete: KeyAction.restrict)();

  /// Verweis auf einen Raum (Haushalt, ab v0.3); die Tabelle gibt es noch nicht.
  TextColumn get roomId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get note => text().nullable()();
  IntColumn get estimateMin => integer().nullable()();
  TextColumn get priority =>
      textEnum<Priority>().withDefault(Constant(Priority.b.name))();

  /// Kalendertag als lokaler Text `yyyy-MM-dd`.
  TextColumn get dueDate => text().nullable()();

  /// Wiederholungsregel als JSON; die Engine kommt mit v0.2.
  TextColumn get recurrence => text().nullable()();
  DateTimeColumn get reminderAt => dateTime().nullable()();
  IntColumn get warnMin => integer().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().clientDefault(nowUtc)();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (due_date IS NULL OR due_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
  ];
}
