import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stups/app.dart';
import 'package:stups/core/db/app_database.dart';
import 'package:stups/core/db/app_database_provider.dart';
import 'package:stups/core/screen_awake/screen_awake.dart';

import 'fake_screen_awake.dart';

/// Startet die App mit einer In-Memory-Datenbank und liefert diese zurück.
///
/// [seed] legt vor dem Start Daten an, [overrides] ersetzen Provider (zum
/// Beispiel die Uhr). Tests halten den Bildschirm nie wirklich wach; wer prüfen
/// will, ob die App es will, übergibt ein [screenAwake] (`FakeScreenAwake`),
/// das er danach befragt. Die Systemsprache ist [locale]
/// (Deutsch), weil Tests sonst mit Englisch laufen. Die Datenbank wird erst
/// geschlossen, wenn die Oberfläche ihre Streams abbestellt hat und die
/// Fake-Zeit deren Timer abgearbeitet hat; sonst hängt das Schließen für immer
/// (siehe docs/HANDOFF.md, „Datenbank“).
Future<AppDatabase> pumpStupsApp(
  WidgetTester tester, {
  Locale locale = const Locale('de'),
  Future<void> Function(AppDatabase db)? seed,
  List<Override> overrides = const [],
  ScreenAwake? screenAwake,
}) async {
  tester.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.platformDispatcher.clearLocalesTestValue);
  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  });
  if (seed != null) await tester.runAsync(() => seed(db));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        screenAwakeProvider.overrideWithValue(screenAwake ?? FakeScreenAwake()),
        ...overrides,
      ],
      child: const StupsApp(),
    ),
  );
  await tester.pumpAndSettle();
  return db;
}
