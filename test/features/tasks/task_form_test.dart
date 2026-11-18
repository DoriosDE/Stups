import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stups/core/db/app_database.dart';
import 'package:stups/features/tasks/task_repository.dart';

import '../../support/app_harness.dart';

/// Das Formular „Neue Aufgabe“ an der echten App.
void main() {
  Future<AppDatabase> openNewTaskForm(WidgetTester tester) async {
    final db = await pumpStupsApp(tester);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Aufgaben'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Neue Aufgabe'));
    await tester.pumpAndSettle();
    return db;
  }

  /// Öffnet das Formular zum Bearbeiten einer Aufgabe, die schon vor Jahren
  /// angelegt wurde, mit den Details aufgeklappt.
  Future<AppDatabase> openEditFormWithOldDates(WidgetTester tester) async {
    final db = await pumpStupsApp(
      tester,
      seed: (db) async {
        final personal = await (db.select(
          db.areas,
        )..where((a) => a.builtInKey.equals(BuiltInArea.personal))).getSingle();
        await TaskRepository(db).create(
          TaskDraft(
            title: 'Steuer machen',
            areaId: personal.id,
            dueDate: DateTime(2020, 1, 1),
            reminderAt: DateTime(2020, 1, 1, 9),
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
    await tester.tap(find.byTooltip('Bearbeiten'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mehr Details'));
    await tester.pumpAndSettle();
    return db;
  }

  Future<List<Task>> savedTasks(WidgetTester tester, AppDatabase db) async =>
      (await tester.runAsync(() => db.select(db.tasks).get()))!;

  /// Scrollt das Formular, bis [target] auf dem Bildschirm liegt. Die Liste
  /// baut ihre Einträge erst, wenn sie in Reichweite scrollen; gebaut heißt
  /// aber noch nicht sichtbar.
  Future<void> scrollTo(WidgetTester tester, Finder target) async {
    await tester.scrollUntilVisible(
      target,
      200,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester) async {
    final save = find.widgetWithText(FilledButton, 'Speichern');
    await scrollTo(tester, save);
    await tester.tap(save);
    await tester.pumpAndSettle();
  }

  testWidgets('„Speichern“ ist gesperrt, solange kein Titel im Feld steht', (
    tester,
  ) async {
    await openNewTaskForm(tester);
    final save = find.widgetWithText(FilledButton, 'Speichern');
    final titleField = find.widgetWithText(
      TextField,
      'Was willst du erledigen?',
    );

    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.enterText(titleField, '  \n ');
    await tester.pump();
    expect(tester.widget<FilledButton>(save).onPressed, isNull);

    await tester.enterText(titleField, 'Wäsche waschen');
    await tester.pump();
    expect(tester.widget<FilledButton>(save).onPressed, isNotNull);
  });

  testWidgets('Details sind eingeklappt und öffnen sich auf Tipp', (
    tester,
  ) async {
    await openNewTaskForm(tester);
    const estimate = 'Geschätzte Dauer in Minuten';
    expect(find.widgetWithText(TextField, estimate), findsNothing);

    await tester.tap(find.text('Mehr Details'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, estimate), findsOneWidget);
    expect(find.text('Priorität'), findsOneWidget);
    expect(find.text('Bereich'), findsOneWidget);
  });

  testWidgets(
    'Dauer, Priorität und Bereich aus den Details werden gespeichert',
    (tester) async {
      final db = await openNewTaskForm(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Was willst du erledigen?'),
        'Steuer machen',
      );
      await tester.tap(find.text('Mehr Details'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'Geschätzte Dauer in Minuten'),
        '25',
      );
      await scrollTo(tester, find.text('A'));
      await tester.tap(find.text('A'));
      await scrollTo(tester, find.widgetWithText(ChoiceChip, 'Arbeit'));
      await tester.tap(find.widgetWithText(ChoiceChip, 'Arbeit'));
      await tester.pump();
      await tapSave(tester);

      final task = (await savedTasks(tester, db)).single;
      final work = await tester.runAsync(
        () => (db.select(
          db.areas,
        )..where((a) => a.builtInKey.equals(BuiltInArea.work))).getSingle(),
      );
      expect(task.estimateMin, 25);
      expect(task.priority, Priority.a);
      expect(task.areaId, work!.id);
    },
  );

  testWidgets(
    'weitere Schritte lassen sich hinzufügen und werden gespeichert',
    (tester) async {
      final db = await openNewTaskForm(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'Was willst du erledigen?'),
        'Wäsche waschen',
      );
      await tester.tap(find.text('Mehr Details'));
      await tester.pumpAndSettle();
      for (final step in ['Wäsche sortieren', 'Maschine starten']) {
        final add = find.text('Schritt hinzufügen');
        await scrollTo(tester, add);
        await tester.tap(add);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.widgetWithText(TextField, 'Weiterer Schritt').last,
          step,
        );
      }
      await tester.pump();
      await tapSave(tester);

      final steps = await tester.runAsync(() => db.select(db.subtasks).get());
      expect(steps!.map((s) => s.title), [
        'Wäsche sortieren',
        'Maschine starten',
      ]);
    },
  );

  testWidgets('Fälligkeit wird im Datumsdialog gewählt und gespeichert', (
    tester,
  ) async {
    final db = await openNewTaskForm(tester);
    final now = DateTime.now();
    // Ein Tag, der nie der heutige ist, damit der Dialogkopf nicht mittrifft.
    final day = now.day == 20 ? 21 : 20;

    await tester.enterText(
      find.widgetWithText(TextField, 'Was willst du erledigen?'),
      'Steuer machen',
    );
    await tester.tap(find.text('Mehr Details'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Fällig am'));
    await tester.tap(find.text('Fällig am'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('$day'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tapSave(tester);

    final task = (await savedTasks(tester, db)).single;
    final month = now.month.toString().padLeft(2, '0');
    expect(task.dueDate, '${now.year}-$month-$day');
  });

  testWidgets('Erinnerung wird als Tag und Uhrzeit gewählt und gespeichert', (
    tester,
  ) async {
    final db = await openNewTaskForm(tester);
    final now = DateTime.now();
    final day = now.day == 20 ? 21 : 20;

    await tester.enterText(
      find.widgetWithText(TextField, 'Was willst du erledigen?'),
      'Steuer machen',
    );
    await tester.tap(find.text('Mehr Details'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Erinnerung'));
    await tester.tap(find.text('Erinnerung'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('$day'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    // Zeitdialog: die Voreinstellung 9:00 bestätigen.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tapSave(tester);

    final task = (await savedTasks(tester, db)).single;
    expect(
      task.reminderAt!.isAtSameMomentAs(
        DateTime(now.year, now.month, day, 9, 0),
      ),
      isTrue,
    );
  });

  testWidgets('ein altes Fälligkeitsdatum lässt sich im Dialog öffnen und '
      'bestätigen', (tester) async {
    final db = await openEditFormWithOldDates(tester);

    await scrollTo(tester, find.text('Fällig am'));
    await tester.tap(find.text('Fällig am'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tapSave(tester);

    expect((await savedTasks(tester, db)).single.dueDate, '2020-01-01');
  });

  testWidgets('eine vergangene Erinnerung lässt sich im Dialog öffnen und '
      'bestätigen', (tester) async {
    final db = await openEditFormWithOldDates(tester);

    await scrollTo(tester, find.text('Erinnerung'));
    await tester.tap(find.text('Erinnerung'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    // Zeitdialog: die gespeicherte Uhrzeit 9:00 bestätigen.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tapSave(tester);

    final reminder = (await savedTasks(tester, db)).single.reminderAt!;
    expect(reminder.isAtSameMomentAs(DateTime(2020, 1, 1, 9)), isTrue);
  });

  testWidgets('„Neue Aufgabe“ legt eine Aufgabe mit erstem Mini-Schritt an', (
    tester,
  ) async {
    final db = await openNewTaskForm(tester);

    await tester.enterText(
      find.widgetWithText(TextField, 'Was willst du erledigen?'),
      'Wäsche waschen',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Was ist der allererste Mini-Schritt?'),
      'Wäschekorb zur Maschine tragen',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Speichern'));
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsNothing);
    final task = (await savedTasks(tester, db)).single;
    expect(task.title, 'Wäsche waschen');
    expect(task.firstStep, 'Wäschekorb zur Maschine tragen');
    expect(task.priority, Priority.b);
  });
}
