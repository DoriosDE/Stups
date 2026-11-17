import 'package:drift/drift.dart';

import '../ids.dart';

/// Bereiche (Haushalt, Arbeit, Persönliches und eigene).
///
/// Eingebaute Bereiche tragen nur eine Kennung ([builtInKey]) und keinen Text;
/// ihr Anzeigename kommt aus den Sprachdateien. [name] gibt es nur bei
/// eigenen Bereichen.
class Areas extends Table {
  TextColumn get id => text().clientDefault(newId)();
  TextColumn get builtInKey => text().nullable().unique()();
  TextColumn get name => text().nullable()();
  TextColumn get colorKey => text()();
  TextColumn get iconKey => text()();
  BoolColumn get hidden => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    'CHECK (built_in_key IS NOT NULL OR name IS NOT NULL)',
  ];
}
