import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stups/app.dart';
import 'package:stups/core/app_info/app_info_provider.dart';
import 'package:stups/core/db/app_database.dart';
import 'package:stups/core/db/app_database_provider.dart';
import 'package:stups/core/router/app_router.dart';
import 'package:stups/core/theme/app_theme.dart';
import 'package:stups/features/inbox/capture_sheet.dart';
import 'package:stups/features/inbox/inbox_repository.dart';
import 'package:stups/features/shell/placeholder_page.dart';
import 'package:stups/features/tasks/task_repository.dart';
import 'package:stups/features/tasks/tasks_screen.dart';

import '../../support/marker_localizations.dart';

/// Alle Oberflächentexte kommen aus den Sprachdateien. Die
/// Test-Übersetzung ersetzt jeden Text durch einen Marker; was keinen Marker
/// zeigt, steht fest im Code.
void main() {
  Future<void> pumpApp(
    WidgetTester tester, {
    String? location,
    String version = '0.0.0-test',
    List<String> thoughts = const [],
    Future<void> Function(AppDatabase db)? seed,
  }) async {
    final router = createRouter(initialLocation: location ?? AppRoutes.today);
    addTearDown(router.dispose);
    final db = AppDatabase(NativeDatabase.memory());
    // Die Datenbank erst schließen, wenn die Oberfläche ihre Streams abbestellt
    // hat und die Fake-Zeit deren Timer abgearbeitet hat; sonst hängt das
    // Schließen für immer.
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
      await tester.runAsync(db.close);
    });
    await tester.runAsync(() async {
      for (final thought in thoughts) {
        await InboxRepository(db).add(thought);
      }
      if (seed != null) await seed(db);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          packageInfoProvider.overrideWith(
            (ref) async => PackageInfo(
              appName: 'Stups',
              packageName: 'de.dorios.stups',
              version: version,
              buildNumber: '1',
            ),
          ),
        ],
        child: MaterialApp.router(
          theme: StupsTheme.light,
          localizationsDelegates: markerLocalizationsDelegates,
          supportedLocales: const [Locale('de')],
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('Seiten der Tabs', () {
    const pages = <({String location, String titleKey, String hintKey})>[
      (
        location: AppRoutes.routines,
        titleKey: 'tabRoutines',
        hintKey: 'routinesHint',
      ),
      (
        location: AppRoutes.household,
        titleKey: 'tabHousehold',
        hintKey: 'householdHint',
      ),
      (location: AppRoutes.more, titleKey: 'tabMore', hintKey: 'moreHint'),
    ];

    for (final page in pages) {
      testWidgets(
        '${page.location} zeigt Titel und Hinweis aus den Sprachdateien',
        (tester) async {
          await pumpApp(tester, location: page.location);

          final pageFinder = find.byType(PlaceholderPage);
          expect(
            find.descendant(
              of: pageFinder,
              matching: find.text(marker(page.titleKey)),
            ),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: pageFinder,
              matching: find.text(marker(page.hintKey)),
            ),
            findsOneWidget,
          );
        },
      );
    }
  });

  group('Aufgaben-Tab mit Inbox', () {
    testWidgets('zeigt Titel und die leere Inbox mit Texten aus den '
        'Sprachdateien', (tester) async {
      await pumpApp(tester, location: AppRoutes.tasks);

      final screen = find.byType(TasksScreen);
      for (final key in ['tabTasks', 'inboxEmptyTitle', 'inboxEmptyText']) {
        expect(
          find.descendant(of: screen, matching: find.text(marker(key))),
          findsOneWidget,
          reason: 'Text "$key" zeigt seinen Marker nicht',
        );
      }
    });

    testWidgets('zeigt Erklärung und Knöpfe eines Gedankens mit Texten aus den '
        'Sprachdateien', (tester) async {
      await pumpApp(
        tester,
        location: AppRoutes.tasks,
        thoughts: ['Mama zurückrufen'],
      );

      expect(find.text(marker('inboxIntro')), findsOneWidget);
      expect(find.text(marker('inboxToTask')), findsOneWidget);
      expect(
        find.byTooltip(marker('inboxDelete', 'Mama zurückrufen')),
        findsOneWidget,
      );
    });

    testWidgets('bestätigt „Zur Aufgabe“ mit einem Text aus den '
        'Sprachdateien', (tester) async {
      await pumpApp(
        tester,
        location: AppRoutes.tasks,
        thoughts: ['Mama zurückrufen'],
      );

      await tester.tap(find.text(marker('inboxToTask')));
      await tester.pumpAndSettle();

      expect(find.text(marker('inboxTaskCreated')), findsOneWidget);
    });
  });

  group('Aufgaben', () {
    Future<void> seedTask(AppDatabase db) async {
      final work = await (db.select(
        db.areas,
      )..where((a) => a.builtInKey.equals(BuiltInArea.work))).getSingle();
      await TaskRepository(db).create(
        TaskDraft(
          title: 'Steuer machen',
          areaId: work.id,
          steps: [StepDraft('Ordner holen'), StepDraft('Belege sortieren')],
          estimateMin: 30,
          priority: Priority.a,
          dueDate: DateTime(2026, 12, 1),
          reminderAt: DateTime(2026, 11, 30, 9),
        ),
      );
    }

    /// Markiert, welche Texte sichtbar sein müssen.
    void expectMarkers(Iterable<String> texts) {
      for (final text in texts) {
        expect(
          find.text(text),
          findsOneWidget,
          reason: 'Text "$text" zeigt seinen Marker nicht',
        );
      }
    }

    testWidgets('der Tab zeigt Umschalter, Knopf und die leere Liste mit '
        'Texten aus den Sprachdateien', (tester) async {
      await pumpApp(tester, location: AppRoutes.tasks);

      expectMarkers([
        marker('tasksTabInbox', '0'),
        marker('tasksTabAll'),
        marker('taskNew'),
      ]);

      await tester.tap(find.text(marker('tasksTabAll')));
      await tester.pumpAndSettle();

      expectMarkers([
        marker('tasksEmpty'),
        marker('tasksAreaAll'),
        marker('areaHousehold'),
        marker('areaWork'),
        marker('areaPersonal'),
      ]);
    });

    testWidgets('die Liste zeigt Bereich und Dauer mit Texten aus den '
        'Sprachdateien', (tester) async {
      await pumpApp(tester, location: AppRoutes.tasks, seed: seedTask);

      await tester.tap(find.text(marker('tasksTabAll')));
      await tester.pumpAndSettle();

      expectMarkers(['${marker('areaWork')} · ${marker('taskMinutes', '30')}']);
    });

    testWidgets('das Formular trägt Texte aus den Sprachdateien', (
      tester,
    ) async {
      // Hoch genug, damit die Liste alle Felder baut.
      tester.view.physicalSize = const Size(800, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpApp(tester, location: AppRoutes.newTask);

      expectMarkers([
        marker('taskNew'),
        marker('taskTitleLabel'),
        marker('taskFirstStepLabel'),
        marker('taskMoreDetails'),
        marker('taskSave'),
      ]);

      await tester.tap(find.text(marker('taskMoreDetails')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(marker('taskAddStep')));
      await tester.pumpAndSettle();

      expectMarkers([
        marker('taskEstimateLabel'),
        marker('taskStepLabel'),
        marker('taskPriorityLabel'),
        marker('taskAreaLabel'),
        marker('areaHousehold'),
        marker('areaWork'),
        marker('areaPersonal'),
        marker('taskDueLabel'),
        marker('taskReminderLabel'),
      ]);
      expect(find.text(marker('taskNotSet')), findsNWidgets(2));
    });

    testWidgets('das Formular zum Bearbeiten trägt seine Überschrift aus den '
        'Sprachdateien', (tester) async {
      late String id;
      await pumpApp(
        tester,
        seed: (db) async {
          await seedTask(db);
          id = (await db.select(db.tasks).getSingle()).id;
        },
      );
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      router.push(AppRoutes.editTaskPath(id));
      await tester.pumpAndSettle();

      expectMarkers([marker('taskEditTitle')]);
    });

    testWidgets('die Detailansicht trägt Texte aus den Sprachdateien', (
      tester,
    ) async {
      late String id;
      await pumpApp(
        tester,
        seed: (db) async {
          await seedTask(db);
          id = (await db.select(db.tasks).getSingle()).id;
        },
      );
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      router.push(AppRoutes.taskPath(id));
      await tester.pumpAndSettle();

      expectMarkers([
        marker('areaWork'),
        marker('taskPriorityValue', 'A'),
        marker('taskEstimateAbout', '30'),
        marker('taskFirstStepHeading'),
        marker('taskNextSteps'),
        marker('taskDone'),
      ]);
      expect(find.byTooltip(marker('taskEdit')), findsOneWidget);
      expect(find.textContaining('⟦taskDueOn:'), findsOneWidget);
      expect(find.textContaining('⟦taskReminderAt:'), findsOneWidget);
    });

    testWidgets('Erledigen fragt und vergleicht mit Texten aus den '
        'Sprachdateien', (tester) async {
      late String id;
      await pumpApp(
        tester,
        seed: (db) async {
          await seedTask(db);
          id = (await db.select(db.tasks).getSingle()).id;
        },
      );
      final router = GoRouter.of(tester.element(find.byType(Scaffold).first));
      router.push(AppRoutes.taskPath(id));
      await tester.pumpAndSettle();

      await tester.tap(find.text(marker('taskDone')));
      await tester.pumpAndSettle();
      expectMarkers([
        marker('taskDoneAskTitle'),
        marker('taskDoneMinutesLabel'),
        marker('taskDoneConfirm'),
      ]);

      await tester.enterText(find.byType(TextField), '14');
      await tester.pump();
      await tester.tap(find.text(marker('taskDoneConfirm')));
      await tester.pumpAndSettle();

      // Zuerst die Feier, mit dem Weg zurück zu „Heute“.
      expectMarkers([
        marker('celebrationDone', 'Steuer machen'),
        marker('celebrationPlus'),
        marker('celebrationCompanion', marker('companionDefaultName')),
        marker('celebrationToToday'),
        marker('celebrationStay'),
      ]);
      await tester.tap(find.text(marker('celebrationStay')));
      await tester.pumpAndSettle();

      expectMarkers([
        marker('taskDoneTitle'),
        marker('taskComparison', '30,14'),
      ]);
    });
  });

  group('Heute', () {
    Future<void> seedTask(AppDatabase db) async {
      final work = await (db.select(
        db.areas,
      )..where((a) => a.builtInKey.equals(BuiltInArea.work))).getSingle();
      await TaskRepository(db).create(
        TaskDraft(
          title: 'Steuer machen',
          areaId: work.id,
          steps: [StepDraft('Ordner holen')],
          estimateMin: 30,
        ),
      );
    }

    void expectMarkers(Iterable<String> texts) {
      for (final text in texts) {
        expect(
          find.text(text),
          findsOneWidget,
          reason: 'Text "$text" zeigt seinen Marker nicht',
        );
      }
    }

    testWidgets('ohne Aufgaben trägt „Alles ruhig“ Texte aus den '
        'Sprachdateien', (tester) async {
      await pumpApp(tester);

      expectMarkers([
        marker('todayDeeds', '0'),
        marker('todayGreeting', marker('companionDefaultName')),
        marker('todayQuiet'),
        marker('captureTitle'),
      ]);
    });

    testWidgets('Energie-Check, nächster Schritt und Tagesplan tragen Texte '
        'aus den Sprachdateien', (tester) async {
      await pumpApp(tester, seed: seedTask);

      expectMarkers([
        marker('todayEnergyQuestion'),
        marker('todayEnergyNote'),
        marker('energyLow'),
        marker('energyMedium'),
        marker('energyHigh'),
      ]);

      await tester.tap(find.text(marker('energyMedium')));
      await tester.pumpAndSettle();

      expectMarkers([
        marker('todayNextStep'),
        marker('todayFirstMiniStep', 'Ordner holen'),
        '${marker('areaWork')} · ${marker('taskEstimateAbout', '30')}',
        marker('todayStart'),
        marker('todayTomorrowAgain'),
        marker('todayChangeEnergy'),
        marker('todayPlanTitle'),
        marker('todayProgress', '0,1'),
      ]);
    });
  });

  testWidgets('das Eingabeblatt „Kopf frei machen“ trägt Texte aus den '
      'Sprachdateien', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip(marker('captureTooltip')));
    await tester.pumpAndSettle();

    // „Kopf frei machen“ steht auch als Knopf auf „Heute“, deshalb nur im Blatt
    // suchen.
    final sheet = find.byType(CaptureSheet);
    for (final key in ['captureTitle', 'captureHint', 'captureFieldHint']) {
      expect(
        find.descendant(of: sheet, matching: find.text(marker(key))),
        findsOneWidget,
        reason: 'Text "$key" zeigt seinen Marker nicht',
      );
    }

    await tester.enterText(find.byType(TextField), 'Mama zurückrufen');
    await tester.pump();
    await tester.tap(find.text(marker('captureDone')));
    await tester.pumpAndSettle();

    expect(find.text(marker('captureSaved')), findsOneWidget);
  });

  testWidgets('der Plus-Button trägt seinen Hinweis aus den Sprachdateien', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.byTooltip(marker('captureTooltip')), findsOneWidget);
  });

  testWidgets('„Mehr“ zeigt die Version mit dem Text aus den Sprachdateien', (
    tester,
  ) async {
    await pumpApp(tester, location: AppRoutes.more, version: '0.1.0-dev');

    expect(find.text(marker('moreVersion', '0.1.0-dev')), findsOneWidget);
  });

  testWidgets('der App-Titel kommt aus den Sprachdateien', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: StupsApp(localizationsDelegates: markerLocalizationsDelegates),
      ),
    );
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    final context = tester.element(find.byType(Scaffold).first);
    expect(app.onGenerateTitle?.call(context), marker('appTitle'));
  });

  testWidgets('die fünf Tabs tragen die Texte aus den Sprachdateien', (
    tester,
  ) async {
    await pumpApp(tester);

    for (final key in [
      'tabToday',
      'tabTasks',
      'tabRoutines',
      'tabHousehold',
      'tabMore',
    ]) {
      expect(
        find.widgetWithText(NavigationDestination, marker(key)),
        findsOneWidget,
        reason: 'Tab "$key" zeigt seinen Marker nicht',
      );
    }
  });
}
