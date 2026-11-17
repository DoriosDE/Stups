import 'package:drift/drift.dart';

import '../defaults.dart';

/// „Kopf frei machen“: Einträge ohne Kategorie, Datum oder Priorität. Beim
/// Sortieren wird ein Eintrag zur Aufgabe oder gelöscht.
class InboxItems extends Table {
  TextColumn get id => text().clientDefault(newId)();
  // Spalte `text`, in Dart `content` (siehe docs/HANDOFF.md, „Datenbank“).
  TextColumn get content => text().named('text')();
  DateTimeColumn get createdAt => dateTime().clientDefault(nowUtc)();

  @override
  Set<Column> get primaryKey => {id};
}
