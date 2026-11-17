import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stups/app.dart';
import 'package:stups/core/db/app_database.dart';
import 'package:stups/core/db/app_database_provider.dart';

/// Startet die App mit einer In-Memory-Datenbank und liefert diese zurück.
///
/// Die Systemsprache ist [locale] (Deutsch), weil Tests sonst mit Englisch
/// laufen. Die Datenbank wird erst geschlossen, wenn die Oberfläche ihre
/// Streams abbestellt hat und die Fake-Zeit deren Timer abgearbeitet hat; sonst
/// hängt das Schließen für immer (siehe docs/HANDOFF.md, „Datenbank“).
Future<AppDatabase> pumpStupsApp(
  WidgetTester tester, {
  Locale locale = const Locale('de'),
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  });
  await tester.pumpWidget(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const StupsApp(),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}
