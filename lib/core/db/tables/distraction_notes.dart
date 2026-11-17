import 'package:drift/drift.dart';

import '../ids.dart';
import 'occurrences.dart';

/// Einfälle aus dem Fokusmodus („Ablenkungs-Parkplatz“). Sie wandern in die
/// Inbox; die Notiz bleibt auch bestehen, wenn ihr Vorkommen gelöscht wird.
class DistractionNotes extends Table {
  TextColumn get id => text().clientDefault(newId)();
  // Die Spalte heißt `text` (siehe SPEC), die Eigenschaft `content`, weil
  // `text` in drift die Methode zum Anlegen von Spalten ist.
  TextColumn get content => text().named('text')();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();
  TextColumn get occurrenceId => text().nullable().references(
    Occurrences,
    #id,
    onDelete: KeyAction.setNull,
  )();

  @override
  Set<Column> get primaryKey => {id};
}
