import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stups/core/clock/clock_provider.dart';
import 'package:stups/core/db/app_database.dart';
import 'package:stups/features/tasks/task_repository.dart';

import '../../support/app_harness.dart';
import '../../support/fake_screen_awake.dart';

/// Der Fokus-Ablauf: von „Los geht’s“ über den Countdown bis „Fertig“ oder
/// „Für heute reicht’s“.
void main() {
  late DateTime now;
  late FakeScreenAwake awake;

  setUp(() {
    now = DateTime(2026, 11, 18, 9, 0);
    awake = FakeScreenAwake();
  });

  Future<void> seedTask(AppDatabase db) async {
    final area = await (db.select(
      db.areas,
    )..where((a) => a.builtInKey.equals(BuiltInArea.work))).getSingle();
    await TaskRepository(db).create(
      TaskDraft(
        title: 'Steuer machen',
        areaId: area.id,
        steps: [
          StepDraft('Ordner aus dem Regal holen'),
          StepDraft('Belege sortieren'),
        ],
        estimateMin: 20,
        priority: Priority.a,
      ),
    );
  }

  /// Zwei Aufgaben: „Steuer machen“ (A) steht im Plan vor „Wäsche waschen“.
  Future<void> seedTwoTasks(AppDatabase db) async {
    await seedTask(db);
    final area = await (db.select(
      db.areas,
    )..where((a) => a.builtInKey.equals(BuiltInArea.work))).getSingle();
    await TaskRepository(db)
        .create(TaskDraft(title: 'Wäsche waschen', areaId: area.id));
  }

  /// Startet die App, wählt die Energie und öffnet den Fokus der ersten
  /// Aufgabe des Plans.
  Future<AppDatabase> openFocus(
    WidgetTester tester, {
    Future<void> Function(AppDatabase)? seed,
    String energy = 'Wenig',
  }) async {
    // Ein hohes Telefon, damit auch der Parkplatz im Bild ist.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = await pumpStupsApp(
      tester,
      seed: seed ?? seedTask,
      overrides: [clockProvider.overrideWithValue(() => now)],
      screenAwake: awake,
    );
    await tester.tap(find.widgetWithText(FilledButton, energy));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Los geht’s'));
    await tester.pumpAndSettle();
    return db;
  }

  /// Die Uhr springt, und die App merkt es beim nächsten Tick.
  Future<void> advance(WidgetTester tester, Duration by) async {
    now = now.add(by);
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> start(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(FilledButton, label));
    await tester.pumpAndSettle();
  }

  testWidgets('zeigt Aufgabe, Schritte und die Wahl der Dauer', (tester) async {
    await openFocus(tester);

    expect(find.text('Steuer machen'), findsOneWidget);
    expect(find.text('Ordner aus dem Regal holen'), findsOneWidget);
    expect(find.text('Belege sortieren'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '5 Min.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '10 Min.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '15 Min.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Frei'), findsOneWidget);
    // Noch kein Countdown.
    expect(find.textContaining(':'), findsNothing);
  });

  testWidgets('ein Tipp auf die Dauer startet den Countdown', (tester) async {
    final db = await openFocus(tester);

    await start(tester, '10 Min.');

    expect(find.text('10:00'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '10 Min.'), findsNothing);
    final occurrence = (await tester.runAsync(
      () => db.select(db.occurrences).getSingle(),
    ))!;
    expect(occurrence.status, OccurrenceStatus.started);
  });

  testWidgets('„Frei“ fragt nach den Minuten', (tester) async {
    await openFocus(tester);

    await start(tester, 'Frei');
    await tester.enterText(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextField),
      ),
      '25',
    );
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Los'));
    await tester.pumpAndSettle();

    expect(find.text('25:00'), findsOneWidget);
  });

  testWidgets('der Countdown läuft mit der Uhr', (tester) async {
    await openFocus(tester);
    await start(tester, '10 Min.');

    await advance(tester, const Duration(seconds: 30));

    expect(find.text('9:30'), findsOneWidget);
  });

  testWidgets('nach dem Hintergrundbetrieb stimmt die Zeit sofort', (
    tester,
  ) async {
    await openFocus(tester);
    await start(tester, '10 Min.');

    // Die App war 4 Minuten im Hintergrund; es kam kein Tick.
    now = now.add(const Duration(minutes: 4));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('6:00'), findsOneWidget);
  });

  testWidgets(
    'wer zurückgeht und wiederkommt, findet den laufenden Countdown',
    (tester) async {
      await openFocus(tester);
      await start(tester, '10 Min.');
      await advance(tester, const Duration(minutes: 3));

      await tester.tap(find.byTooltip('Zurück'));
      await tester.pumpAndSettle();
      expect(find.text('Dein nächster Schritt'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Los geht’s'));
      await tester.pumpAndSettle();

      expect(find.text('7:00'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '10 Min.'), findsNothing);
    },
  );

  group('Zeitende', () {
    Future<void> runOut(WidgetTester tester) async {
      await openFocus(tester);
      await start(tester, '5 Min.');
      await advance(tester, const Duration(minutes: 5, seconds: 30));
    }

    testWidgets('bietet „Noch 5 Minuten“ und „Fertig“', (tester) async {
      await runOut(tester);

      expect(find.text('Die Zeit ist um.'), findsOneWidget);
      expect(find.text('0:00'), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Noch 5 Minuten'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Fertig'), findsOneWidget);
    });

    testWidgets('„Noch 5 Minuten“ startet einen neuen Abschnitt', (
      tester,
    ) async {
      await runOut(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Noch 5 Minuten'));
      await tester.pumpAndSettle();

      expect(find.text('5:00'), findsOneWidget);
      expect(find.text('Die Zeit ist um.'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Fertig'), findsNothing);
    });

    testWidgets('„Fertig“ fragt die Dauer ab, vorbelegt mit der gebrauchten '
        'Zeit, und feiert', (tester) async {
      await runOut(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Fertig'));
      await tester.pumpAndSettle();
      // Der Countdown dauerte 5 Minuten; die 30 Sekunden danach zählen nicht.
      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, 'Minuten'),
      );
      expect(field.controller!.text, '5');
      await tester.tap(find.widgetWithText(FilledButton, 'Fertig').last);
      await tester.pumpAndSettle();

      expect(find.text('„Steuer machen“ ist erledigt.'), findsOneWidget);
      await tester.tap(find.text('Zu Heute'));
      await tester.pumpAndSettle();
      expect(find.text('1 Tat'), findsOneWidget);
    });

    testWidgets('„Fertig“ beendet die Sitzung', (tester) async {
      await runOut(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Fertig'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Fertig').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hier bleiben'));
      await tester.pumpAndSettle();

      expect(find.text('Die Zeit ist um.'), findsNothing);
      expect(find.text('Dein nächster Schritt'), findsNothing);
      expect(find.textContaining('Für heute geschafft'), findsOneWidget);
    });
  });

  testWidgets('„Schon fertig“ beendet auch vor Zeitende', (tester) async {
    final db = await openFocus(tester);
    await start(tester, '15 Min.');
    await advance(tester, const Duration(minutes: 2));

    await tester.tap(find.text('Schon fertig'));
    await tester.pumpAndSettle();
    final field = tester.widget<TextField>(
      find.widgetWithText(TextField, 'Minuten'),
    );
    expect(field.controller!.text, '2');
    await tester.tap(find.widgetWithText(FilledButton, 'Fertig'));
    await tester.pumpAndSettle();

    final occurrence = (await tester.runAsync(
      () => db.select(db.occurrences).getSingle(),
    ))!;
    expect(occurrence.status, OccurrenceStatus.done);
    expect(occurrence.actualMin, 2);
  });

  testWidgets('„Für heute reicht’s“ geht jederzeit, ohne Vorwurf', (
    tester,
  ) async {
    final db = await openFocus(tester);
    await start(tester, '10 Min.');
    await advance(tester, const Duration(minutes: 1));

    await tester.tap(find.text('Für heute reicht’s'));
    await tester.pumpAndSettle();

    // Zurück bei Heute, die Aufgabe bleibt offen und im Plan.
    expect(find.text('Dein nächster Schritt'), findsOneWidget);
    expect(find.text('Steuer machen'), findsOneWidget);
    expect(find.text('0 Taten'), findsOneWidget);
    expect(find.text('Du hast angefangen. Das zählt.'), findsOneWidget);
    final settings = (await tester.runAsync(
      () => db.select(db.settings).get(),
    ))!;
    expect(settings.where((s) => s.key == 'focusSession'), isEmpty);

    // Ein neuer Anlauf beginnt frisch.
    await tester.tap(find.widgetWithText(FilledButton, 'Los geht’s'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(FilledButton, '10 Min.'), findsOneWidget);
  });

  testWidgets('„Für heute reicht’s“ gibt es auch vor dem Start', (
    tester,
  ) async {
    await openFocus(tester);

    expect(find.text('Für heute reicht’s'), findsOneWidget);
  });

  group('Bildschirm bleibt an', () {
    testWidgets('vor dem Start nicht', (tester) async {
      await openFocus(tester);

      expect(awake.isOn, isFalse);
    });

    testWidgets('solange der Countdown läuft', (tester) async {
      await openFocus(tester);

      await start(tester, '10 Min.');

      expect(awake.isOn, isTrue);
    });

    testWidgets('bei Zeitende wieder frei, mit „Noch 5 Minuten“ wieder an', (
      tester,
    ) async {
      await openFocus(tester);
      await start(tester, '5 Min.');

      await advance(tester, const Duration(minutes: 5, seconds: 30));
      expect(awake.isOn, isFalse);

      await tester.tap(find.widgetWithText(FilledButton, 'Noch 5 Minuten'));
      await tester.pumpAndSettle();
      expect(awake.isOn, isTrue);
    });

    testWidgets('frei beim Zurückgehen', (tester) async {
      await openFocus(tester);
      await start(tester, '10 Min.');

      await tester.tap(find.byTooltip('Zurück'));
      await tester.pumpAndSettle();

      expect(awake.isOn, isFalse);
    });

    testWidgets('frei nach „Für heute reicht’s“', (tester) async {
      await openFocus(tester);
      await start(tester, '10 Min.');

      await tester.tap(find.text('Für heute reicht’s'));
      await tester.pumpAndSettle();

      expect(awake.isOn, isFalse);
    });

    testWidgets('frei nach „Fertig“', (tester) async {
      await openFocus(tester);
      await start(tester, '10 Min.');

      await tester.tap(find.text('Schon fertig'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Fertig'));
      await tester.pumpAndSettle();

      expect(awake.isOn, isFalse);
    });
  });

  group('Schritte abhaken', () {
    testWidgets('vor dem Start sind die Schritte nur zu sehen', (tester) async {
      await openFocus(tester);

      expect(find.byType(Checkbox), findsNothing);
    });

    testWidgets('ein Tipp hakt den Schritt ab, der nächste rückt nach', (
      tester,
    ) async {
      final db = await openFocus(tester);
      await start(tester, '10 Min.');

      await tester.tap(find.text('Ordner aus dem Regal holen'));
      await tester.pumpAndSettle();

      expect(find.text('Jetzt dran'), findsOneWidget);
      expect(find.text('Erster Mini-Schritt'), findsNothing);
      expect(find.text('Geschafft'), findsOneWidget);
      final checks = (await tester.runAsync(
        () => db.select(db.subtaskChecks).get(),
      ))!;
      expect(checks.map((c) => c.done), [true]);
      // Der Countdown läuft ungestört.
      expect(find.text('10:00'), findsOneWidget);
    });

    testWidgets('ein zweiter Tipp nimmt den Haken zurück', (tester) async {
      await openFocus(tester);
      await start(tester, '10 Min.');
      await tester.tap(find.text('Ordner aus dem Regal holen'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ordner aus dem Regal holen'));
      await tester.pumpAndSettle();

      expect(find.text('Erster Mini-Schritt'), findsOneWidget);
      expect(find.text('Geschafft'), findsNothing);
    });

    testWidgets('der letzte Haken bringt ein sanftes Angebot, kein Muss', (
      tester,
    ) async {
      await openFocus(tester);
      await start(tester, '10 Min.');
      expect(find.text('Alle Schritte geschafft.'), findsNothing);

      await tester.tap(find.text('Ordner aus dem Regal holen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Belege sortieren'));
      await tester.pumpAndSettle();

      expect(find.text('Alle Schritte geschafft.'), findsOneWidget);
      // Der Countdown läuft weiter, und man kann einfach bleiben.
      expect(find.text('10:00'), findsOneWidget);
      await tester.tap(find.widgetWithText(FilledButton, 'Fertig'));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'Minuten'), findsOneWidget);
    });

    testWidgets('die Haken bleiben, wenn man wiederkommt', (tester) async {
      await openFocus(tester);
      await start(tester, '10 Min.');
      await tester.tap(find.text('Ordner aus dem Regal holen'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Zurück'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Los geht’s'));
      await tester.pumpAndSettle();

      expect(find.text('Geschafft'), findsOneWidget);
      expect(find.text('Jetzt dran'), findsOneWidget);
    });
  });

  group('zweite Aufgabe', () {
    /// Für „Steuer machen“ läuft der Fokus; dann rückt „Wäsche waschen“ nach,
    /// und man wählt dort eine Dauer. Die Rückfrage steht im Bild.
    Future<AppDatabase> startSecondTask(WidgetTester tester) async {
      final db = await openFocus(tester, seed: seedTwoTasks, energy: 'Mittel');
      await start(tester, '10 Min.');
      await advance(tester, const Duration(minutes: 1));
      await tester.tap(find.byTooltip('Zurück'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Morgen nochmal?'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Los geht’s'));
      await tester.pumpAndSettle();
      expect(find.text('Wäsche waschen'), findsOneWidget);
      await start(tester, '5 Min.');
      return db;
    }

    testWidgets('fragt vor dem Wechsel und nennt die laufende Aufgabe', (
      tester,
    ) async {
      await startSecondTask(tester);

      expect(
        find.text('Bei „Steuer machen“ läuft noch ein Fokus.'),
        findsOneWidget,
      );
      // Noch nichts ist passiert: kein Countdown für die neue Aufgabe.
      expect(find.text('5:00'), findsNothing);
    });

    testWidgets('„Hier starten“ beendet die alte Sitzung ohne Vorwurf', (
      tester,
    ) async {
      final db = await startSecondTask(tester);

      await tester.tap(find.widgetWithText(FilledButton, 'Hier starten'));
      await tester.pumpAndSettle();

      expect(find.text('5:00'), findsOneWidget);
      // „Steuer machen“ bleibt offen: gestartet, nicht erledigt.
      final occurrences = (await tester.runAsync(
        () => db.select(db.occurrences).get(),
      ))!;
      expect(occurrences.map((o) => o.status), [
        OccurrenceStatus.started,
        OccurrenceStatus.started,
      ]);
    });

    testWidgets('„Bei der Aufgabe bleiben“ führt zurück zu ihr', (
      tester,
    ) async {
      await startSecondTask(tester);

      await tester.tap(find.text('Bei „Steuer machen“ bleiben'));
      await tester.pumpAndSettle();

      expect(find.text('Steuer machen'), findsOneWidget);
      expect(find.text('9:00'), findsOneWidget);
      expect(find.text('Wäsche waschen'), findsNothing);
    });
  });

  group('Ablenkungs-Parkplatz', () {
    testWidgets('ein Einfall landet in der Inbox, das Feld wird frei', (
      tester,
    ) async {
      final db = await openFocus(tester);
      await start(tester, '10 Min.');

      await tester.enterText(
        find.widgetWithText(TextField, 'z. B. Mama zurückrufen'),
        'Mama zurückrufen',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Parken'));
      await tester.pumpAndSettle();

      expect(find.text('Geparkt. Er wartet in der Inbox.'), findsOneWidget);
      final field = tester.widget<TextField>(
        find.widgetWithText(TextField, 'z. B. Mama zurückrufen'),
      );
      expect(field.controller!.text, isEmpty);
      final items = (await tester.runAsync(
        () => db.select(db.inboxItems).get(),
      ))!;
      expect(items.map((i) => i.content), ['Mama zurückrufen']);
      // Der Countdown läuft ungestört weiter.
      expect(find.text('10:00'), findsOneWidget);
    });

    testWidgets('den Parkplatz gibt es schon vor dem Start', (tester) async {
      final db = await openFocus(tester);

      await tester.enterText(
        find.widgetWithText(TextField, 'z. B. Mama zurückrufen'),
        'Mama zurückrufen',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Parken'));
      await tester.pumpAndSettle();

      expect(find.text('Geparkt. Er wartet in der Inbox.'), findsOneWidget);
      final items = (await tester.runAsync(
        () => db.select(db.inboxItems).get(),
      ))!;
      expect(items.map((i) => i.content), ['Mama zurückrufen']);
      // Noch kein Countdown: die Wahl der Dauer steht weiter da.
      expect(find.widgetWithText(FilledButton, '10 Min.'), findsOneWidget);
    });

    testWidgets('ohne Text ist „Parken“ aus', (tester) async {
      await openFocus(tester);
      await start(tester, '10 Min.');

      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Parken'),
      );
      expect(button.onPressed, isNull);
    });
  });
}
