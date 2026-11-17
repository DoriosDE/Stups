import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_database.dart';

/// Die Datenbank der App (eine SQLite-Datei im App-Ordner). Tests ersetzen den
/// Provider durch eine In-Memory-Datenbank.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(driftDatabase(name: 'stups'));
  ref.onDispose(db.close);
  return db;
});
