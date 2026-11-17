import 'package:drift/drift.dart';

import '../ids.dart';

/// „Kopf frei machen“: Einträge ohne Kategorie, Datum oder Priorität. Beim
/// Sortieren wird ein Eintrag zur Aufgabe oder gelöscht.
class InboxItems extends Table {
  TextColumn get id => text().clientDefault(newId)();
  // Die Spalte heißt `text` (siehe SPEC), die Eigenschaft `content`, weil
  // `text` in drift die Methode zum Anlegen von Spalten ist.
  TextColumn get content => text().named('text')();
  DateTimeColumn get createdAt =>
      dateTime().clientDefault(() => DateTime.now().toUtc())();

  @override
  Set<Column> get primaryKey => {id};
}
