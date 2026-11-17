import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stups/core/db/app_database.dart';
import 'package:stups/features/inbox/inbox_repository.dart';
import 'package:stups/features/tasks/task_repository.dart';

import '../../support/app_harness.dart';

/// Der Tab „Aufgaben“: Inbox und Liste aller Aufgaben.
void main() {
  Future<String> areaId(AppDatabase db, String builtInKey) async {
    final area = await (db.select(
      db.areas,
    )..where((a) => a.builtInKey.equals(builtInKey))).getSingle();
    return area.id;
  }

  Future<void> openTasksTab(
    WidgetTester tester, {
    Future<void> Function(AppDatabase db)? seed,
  }) async {
    await pumpStupsApp(tester, seed: seed);
    await tester.tap(find.widgetWithText(NavigationDestination, 'Aufgaben'));
    await tester.pumpAndSettle();
  }

  testWidgets('jede Zeile zeigt Priorität, Bereich und geschätzte Dauer', (
    tester,
  ) async {
    await openTasksTab(
      tester,
      seed: (db) async {
        final repository = TaskRepository(db);
        await repository.create(
          TaskDraft(
            title: 'Steuer machen',
            areaId: await areaId(db, BuiltInArea.work),
            priority: Priority.a,
            estimateMin: 30,
          ),
        );
        await repository.create(
          TaskDraft(
            title: 'Bad putzen',
            areaId: await areaId(db, BuiltInArea.household),
          ),
        );
      },
    );
    await tester.tap(find.text('Alle Aufgaben'));
    await tester.pumpAndSettle();

    final tax = find.widgetWithText(ListTile, 'Steuer machen');
    expect(find.descendant(of: tax, matching: find.text('A')), findsOneWidget);
    expect(
      find.descendant(of: tax, matching: find.text('Arbeit · 30 Min.')),
      findsOneWidget,
    );
    final bath = find.widgetWithText(ListTile, 'Bad putzen');
    expect(find.descendant(of: bath, matching: find.text('B')), findsOneWidget);
    expect(
      find.descendant(of: bath, matching: find.text('Haushalt')),
      findsOneWidget,
    );
  });

  testWidgets('Bereichs-Chips filtern die Liste, „Alle“ zeigt wieder alles', (
    tester,
  ) async {
    await openTasksTab(
      tester,
      seed: (db) async {
        final repository = TaskRepository(db);
        await repository.create(
          TaskDraft(
            title: 'Steuer machen',
            areaId: await areaId(db, BuiltInArea.work),
          ),
        );
        await repository.create(
          TaskDraft(
            title: 'Bad putzen',
            areaId: await areaId(db, BuiltInArea.household),
          ),
        );
      },
    );
    await tester.tap(find.text('Alle Aufgaben'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, 'Arbeit'));
    await tester.pumpAndSettle();
    expect(find.text('Steuer machen'), findsOneWidget);
    expect(find.text('Bad putzen'), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'Alle'));
    await tester.pumpAndSettle();
    expect(find.text('Steuer machen'), findsOneWidget);
    expect(find.text('Bad putzen'), findsOneWidget);
  });

  testWidgets('erledigte Aufgaben stehen durchgestrichen am Ende der Liste', (
    tester,
  ) async {
    await openTasksTab(
      tester,
      seed: (db) async {
        final repository = TaskRepository(db);
        final area = await areaId(db, BuiltInArea.household);
        final done = await repository.create(
          TaskDraft(title: 'Bad putzen', areaId: area, priority: Priority.a),
        );
        await repository.create(
          TaskDraft(
            title: 'Wäsche waschen',
            areaId: area,
            priority: Priority.c,
          ),
        );
        await repository.complete(done, actualMin: 12);
      },
    );
    await tester.tap(find.text('Alle Aufgaben'));
    await tester.pumpAndSettle();

    TextDecoration? decorationOf(String title) =>
        tester.widget<Text>(find.text(title)).style?.decoration;
    expect(decorationOf('Bad putzen'), TextDecoration.lineThrough);
    expect(decorationOf('Wäsche waschen'), isNot(TextDecoration.lineThrough));
    // Erledigt steht unten, obwohl es Priorität A hat.
    expect(
      tester.getTopLeft(find.text('Wäsche waschen')).dy,
      lessThan(tester.getTopLeft(find.text('Bad putzen')).dy),
    );
  });

  testWidgets('ohne Aufgaben sagt die Liste, wie es weitergeht', (
    tester,
  ) async {
    await openTasksTab(tester);
    await tester.tap(find.text('Alle Aufgaben'));
    await tester.pumpAndSettle();

    expect(
      find.text(
        'Noch keine Aufgaben. Mit „Neue Aufgabe“ legst du die erste an.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('der Tab wechselt zwischen Inbox und allen Aufgaben', (
    tester,
  ) async {
    await openTasksTab(
      tester,
      seed: (db) async {
        await InboxRepository(db).add('Mama zurückrufen');
        await TaskRepository(db).create(
          TaskDraft(
            title: 'Wäsche waschen',
            areaId: await areaId(db, BuiltInArea.household),
          ),
        );
      },
    );

    expect(find.text('Inbox (1)'), findsOneWidget);
    expect(find.text('Mama zurückrufen'), findsOneWidget);
    expect(find.text('Wäsche waschen'), findsNothing);

    await tester.tap(find.text('Alle Aufgaben'));
    await tester.pumpAndSettle();

    expect(find.text('Wäsche waschen'), findsOneWidget);
    expect(find.text('Mama zurückrufen'), findsNothing);
  });
}
