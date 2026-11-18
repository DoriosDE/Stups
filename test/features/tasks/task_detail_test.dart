import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stups/core/db/app_database.dart';
import 'package:stups/features/tasks/task_repository.dart';

import '../../support/app_harness.dart';

/// Die Detailansicht einer Aufgabe: ansehen, erledigen, bearbeiten.
void main() {
  Future<String> areaId(AppDatabase db, String builtInKey) async {
    final area = await (db.select(
      db.areas,
    )..where((a) => a.builtInKey.equals(builtInKey))).getSingle();
    return area.id;
  }

  /// Öffnet die Detailansicht der Aufgabe „Steuer machen“.
  Future<AppDatabase> openTaxTask(
    WidgetTester tester, {
    int? estimateMin = 10,
  }) async {
    final db = await pumpStupsApp(
      tester,
      seed: (db) async {
        await TaskRepository(db).create(
          TaskDraft(
            title: 'Steuer machen',
            areaId: await areaId(db, BuiltInArea.work),
            steps: [
              StepDraft('Ordner aus dem Regal holen'),
              StepDraft('Belege sortieren'),
              StepDraft('Formular ausfüllen'),
            ],
            estimateMin: estimateMin,
            priority: Priority.a,
            dueDate: DateTime(2026, 12, 1),
          ),
        );
      },
    );
    await tester.tap(find.widgetWithText(NavigationDestination, 'Aufgaben'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alle Aufgaben'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Steuer machen'));
    await tester.pumpAndSettle();
    return db;
  }

  testWidgets('„Erledigt“ fragt nach den Minuten und zeigt den Vergleich', (
    tester,
  ) async {
    final db = await openTaxTask(tester, estimateMin: 10);

    await tester.tap(find.widgetWithText(FilledButton, 'Erledigt'));
    await tester.pumpAndSettle();
    expect(find.text('Wie viele Minuten hast du gebraucht?'), findsOneWidget);
    // Vorbelegt mit der Schätzung.
    final minutes = find.widgetWithText(TextField, 'Minuten');
    expect(tester.widget<TextField>(minutes).controller!.text, '10');

    await tester.enterText(minutes, '14');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Fertig'));
    await tester.pumpAndSettle();

    expect(find.text('Geschafft!'), findsOneWidget);
    expect(find.text('Geschätzt 10 Min., gebraucht 14 Min.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Erledigt'), findsNothing);
    final occurrence = (await tester.runAsync(
      () => db.select(db.occurrences).getSingle(),
    ))!;
    expect(occurrence.actualMin, 14);
    expect(occurrence.status, OccurrenceStatus.done);
  });

  testWidgets(
    'ohne Schätzung ist das Feld leer und „Fertig“ gesperrt, bis eine '
    'Zahl da ist',
    (tester) async {
      await openTaxTask(tester, estimateMin: null);

      await tester.tap(find.widgetWithText(FilledButton, 'Erledigt'));
      await tester.pumpAndSettle();
      final minutes = find.widgetWithText(TextField, 'Minuten');
      final confirm = find.widgetWithText(FilledButton, 'Fertig');
      expect(tester.widget<TextField>(minutes).controller!.text, isEmpty);
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

      await tester.enterText(minutes, '0');
      await tester.pump();
      expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

      await tester.enterText(minutes, '14');
      await tester.pump();
      expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(find.text('Gebraucht: 14 Min.'), findsOneWidget);
    },
  );

  testWidgets('Bearbeiten öffnet das Formular mit den Angaben und speichert '
      'Änderungen', (tester) async {
    final db = await openTaxTask(tester, estimateMin: 30);

    await tester.tap(find.byTooltip('Bearbeiten'));
    await tester.pumpAndSettle();
    final title = find.widgetWithText(TextField, 'Was willst du erledigen?');
    expect(tester.widget<TextField>(title).controller!.text, 'Steuer machen');
    expect(
      tester
          .widget<TextField>(
            find.widgetWithText(
              TextField,
              'Was ist der allererste Mini-Schritt?',
            ),
          )
          .controller!
          .text,
      'Ordner aus dem Regal holen',
    );

    await tester.enterText(title, 'Steuererklärung abgeben');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    // Zurück in der Detailansicht; nichts anderes ging verloren.
    expect(find.text('Steuererklärung abgeben'), findsOneWidget);
    expect(find.text('Etwa 30 Minuten'), findsOneWidget);
    expect(find.text('Priorität A'), findsOneWidget);
    expect(find.text('Ordner aus dem Regal holen'), findsOneWidget);
    expect(find.text('Belege sortieren'), findsOneWidget);
    expect(find.text('Formular ausfüllen'), findsOneWidget);
    expect(find.textContaining('Fällig am'), findsOneWidget);
    expect(
      await tester.runAsync(() => db.select(db.tasks).get()),
      hasLength(1),
    );
  });

  testWidgets('ein Tipp auf die Zeile zeigt die Aufgabe mit allen Angaben', (
    tester,
  ) async {
    await openTaxTask(tester, estimateMin: 30);

    expect(find.text('Arbeit'), findsOneWidget);
    expect(find.text('Steuer machen'), findsOneWidget);
    expect(find.text('Priorität A'), findsOneWidget);
    expect(find.text('Etwa 30 Minuten'), findsOneWidget);
    expect(find.text('Erster Mini-Schritt'), findsOneWidget);
    expect(find.text('Ordner aus dem Regal holen'), findsOneWidget);
    expect(find.text('Danach'), findsOneWidget);
    expect(find.text('Belege sortieren'), findsOneWidget);
    expect(find.text('Formular ausfüllen'), findsOneWidget);
    expect(find.textContaining('Fällig am'), findsOneWidget);
  });
}
