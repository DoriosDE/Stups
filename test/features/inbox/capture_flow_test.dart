import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stups/app.dart';
import 'package:stups/core/db/app_database.dart';
import 'package:stups/core/db/app_database_provider.dart';
import 'package:stups/features/inbox/inbox_repository.dart';

/// Der Ablauf „Kopf frei machen“ an der echten App mit In-Memory-Datenbank.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));

  tearDown(() => db.close());

  Future<void> pumpApp(WidgetTester tester) async {
    // Die Texte unten sind deutsch; Tests laufen sonst mit Systemsprache Englisch.
    tester.platformDispatcher.localesTestValue = const [Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const StupsApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<List<String>> savedThoughts(WidgetTester tester) async {
    final items = await tester.runAsync(
      () => InboxRepository(db).watchItems().first,
    );
    return [for (final item in items!) item.content];
  }

  testWidgets('Plus-Button öffnet das Eingabefeld, „Fertig“ speichert in die '
      'Inbox und schließt es', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Kopf frei machen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Mama zurückrufen');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Fertig'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    expect(await savedThoughts(tester), ['Mama zurückrufen']);
  });

  testWidgets('nach dem Speichern bestätigt eine kurze Meldung die Inbox', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Kopf frei machen'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Mama zurückrufen');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Fertig'));
    await tester.pumpAndSettle();

    expect(find.text('In der Inbox gespeichert.'), findsOneWidget);
  });

  testWidgets('„Fertig“ ist gesperrt, solange nichts als Text im Feld steht', (
    tester,
  ) async {
    await pumpApp(tester);
    final done = find.widgetWithText(FilledButton, 'Fertig');

    await tester.tap(find.byTooltip('Kopf frei machen'));
    await tester.pumpAndSettle();
    expect(tester.widget<FilledButton>(done).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '  \n ');
    await tester.pump();
    expect(tester.widget<FilledButton>(done).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'Mama zurückrufen');
    await tester.pump();
    expect(tester.widget<FilledButton>(done).onPressed, isNotNull);
    expect(await savedThoughts(tester), isEmpty);
  });
}
