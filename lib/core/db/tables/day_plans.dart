import 'package:drift/drift.dart';

import '../enums.dart';

/// Plan für einen Tag: Energie am Morgen und die gewählten Aufgaben.
class DayPlans extends Table {
  /// Kalendertag als lokaler Text `yyyy-MM-dd`; pro Tag ein Plan.
  TextColumn get date => text()();
  TextColumn get energy => textEnum<Energy>().nullable()();

  /// Gewählte Aufgaben-IDs als JSON-Liste; typisiert wird das mit Ticket 05.
  TextColumn get plannedTaskIds => text().withDefault(const Constant('[]'))();
  TextColumn get reviewNote => text().nullable()();

  @override
  Set<Column> get primaryKey => {date};

  @override
  List<String> get customConstraints => [
    "CHECK (date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]')",
  ];
}
