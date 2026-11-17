import 'package:drift/drift.dart';

import '../defaults.dart';
import 'occurrences.dart';

/// Einfälle aus dem Fokusmodus („Ablenkungs-Parkplatz“). Sie wandern in die
/// Inbox; die Notiz bleibt auch bestehen, wenn ihr Vorkommen gelöscht wird.
class DistractionNotes extends Table {
  TextColumn get id => text().clientDefault(newId)();
  // Spalte `text`, in Dart `content` (siehe docs/HANDOFF.md, „Datenbank“).
  TextColumn get content => text().named('text')();
  DateTimeColumn get createdAt => dateTime().clientDefault(nowUtc)();
  TextColumn get occurrenceId => text().nullable().references(
    Occurrences,
    #id,
    onDelete: KeyAction.setNull,
  )();

  @override
  Set<Column> get primaryKey => {id};
}
