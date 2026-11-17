import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stups/app.dart';
import 'package:stups/core/db/app_database.dart';
import 'package:stups/core/db/app_database_provider.dart';
import 'package:stups/features/inbox/inbox_repository.dart';

/// Die Inbox im Tab „Aufgaben“ an der echten App mit In-Memory-Datenbank.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));

  /// Legt Gedanken an und öffnet den Tab „Aufgaben“.
  Future<void> pumpTasksTab(
    WidgetTester tester, {
    List<String> thoughts = const [],
  }) async {
    // Die Texte unten sind deutsch; Tests laufen sonst mit Systemsprache Englisch.
    tester.platformDispatcher.localesTestValue = const [Locale('de')];
    addTearDown(tester.platformDispatcher.clearLocalesTestValue);
    await tester.runAsync(() async {
      for (final thought in thoughts) {
        await InboxRepository(db).add(thought);
      }
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
        child: const StupsApp(),
      ),
    );
    // Die Datenbank erst schließen, wenn die Oberfläche ihre Streams abbestellt
    // hat und die Fake-Zeit deren Timer abgearbeitet hat; sonst hängt das
    // Schließen für immer.
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(db.close);
    });
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(NavigationDestination, 'Aufgaben'));
    await tester.pumpAndSettle();
  }

  testWidgets('die Inbox listet jeden Gedanken mit „Zur Aufgabe“ und Löschen', (
    tester,
  ) async {
    await pumpTasksTab(
      tester,
      thoughts: ['Mama zurückrufen', 'Fahrrad zur Reparatur bringen'],
    );

    expect(find.text('Mama zurückrufen'), findsOneWidget);
    expect(find.text('Fahrrad zur Reparatur bringen'), findsOneWidget);
    expect(find.text('Zur Aufgabe'), findsNWidgets(2));
    expect(find.byTooltip('Mama zurückrufen löschen'), findsOneWidget);
    expect(
      find.byTooltip('Fahrrad zur Reparatur bringen löschen'),
      findsOneWidget,
    );
    expect(find.text('Inbox leer'), findsNothing);
  });

  testWidgets('Löschen entfernt den Gedanken, die anderen bleiben', (
    tester,
  ) async {
    await pumpTasksTab(
      tester,
      thoughts: ['Mama zurückrufen', 'Fahrrad zur Reparatur bringen'],
    );

    await tester.tap(find.byTooltip('Mama zurückrufen löschen'));
    await tester.pumpAndSettle();

    expect(find.text('Mama zurückrufen'), findsNothing);
    expect(find.text('Fahrrad zur Reparatur bringen'), findsOneWidget);
  });

  testWidgets('„Zur Aufgabe“ nimmt den Gedanken aus der Inbox und legt die '
      'Aufgabe an', (tester) async {
    await pumpTasksTab(
      tester,
      thoughts: ['Mama zurückrufen', 'Fahrrad zur Reparatur bringen'],
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Zur Aufgabe').first);
    await tester.pumpAndSettle();

    expect(find.text('Mama zurückrufen'), findsNothing);
    expect(find.text('Fahrrad zur Reparatur bringen'), findsOneWidget);
    final tasks = await tester.runAsync(() => db.select(db.tasks).get());
    expect([for (final task in tasks!) task.title], ['Mama zurückrufen']);
  });

  testWidgets(
    'nach „Zur Aufgabe“ erinnert eine Meldung an den ersten Schritt',
    (tester) async {
      await pumpTasksTab(tester, thoughts: ['Mama zurückrufen']);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Zur Aufgabe'));
      await tester.pumpAndSettle();

      expect(
        find.text('Als Aufgabe angelegt. Ergänze später den ersten Schritt.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('eine leere Inbox zeigt, dass der Kopf frei ist', (tester) async {
    await pumpTasksTab(tester);

    expect(find.text('Inbox leer'), findsOneWidget);
    expect(
      find.text('Kopf frei. Neue Gedanken fängst du mit dem Plus-Button.'),
      findsOneWidget,
    );
  });
}
