import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stups/core/db/app_database.dart';

import '../../generated/schema.dart';

/// Sicherheitsnetz für Schemaänderungen: Die Datenbank im Code muss zum
/// Schnappschuss unter `drift_schemas/` passen. Wer das Schema ändert, erhöht
/// `schemaVersion`, schreibt eine Migration und erzeugt einen neuen
/// Schnappschuss (siehe docs/HANDOFF.md, Abschnitt „Datenbank“).
void main() {
  late SchemaVerifier verifier;

  setUpAll(() => verifier = SchemaVerifier(GeneratedHelper()));

  test(
    'das Schema im Code entspricht dem Schnappschuss von Version 1',
    () async {
      // Frisch aus dem Code angelegt (nicht aus dem Schnappschuss), sonst wäre
      // der Vergleich mit dem Schnappschuss trivial gleich.
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, 1);
    },
  );
}
