import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stups/core/db/app_database.dart';
import 'package:stups/core/db/day_key.dart';
import 'package:stups/core/settings/settings_repository.dart';
import 'package:stups/features/tasks/task_repository.dart';
import 'package:stups/features/today/celebration.dart';
import 'package:stups/features/today/companion.dart';
import 'package:stups/features/today/day_plan_repository.dart';

import '../../support/app_harness.dart';

/// „Heute“: Energie-Check, nur der nächste Schritt groß, Feier nach dem
/// Erledigen.
void main() {
  Future<String> workArea(AppDatabase db) async {
    final area = await (db.select(
      db.areas,
    )..where((a) => a.builtInKey.equals(BuiltInArea.work))).getSingle();
    return area.id;
  }

  /// Legt zwei Aufgaben an: „Steuer machen“ (A, mit erstem Schritt) und
  /// „Fenster putzen“ (C), dazu auf Wunsch eine dritte.
  Future<void> seedTasks(AppDatabase db, {bool third = false}) async {
    final repository = TaskRepository(db);
    final area = await workArea(db);
    await repository.create(
      TaskDraft(
        title: 'Steuer machen',
        areaId: area,
        steps: [StepDraft('Ordner aus dem Regal holen')],
        estimateMin: 20,
        priority: Priority.a,
      ),
    );
    await repository.create(
      TaskDraft(title: 'Fenster putzen', areaId: area, priority: Priority.c),
    );
    if (third) {
      await repository.create(
        TaskDraft(title: 'Müll rausbringen', areaId: area),
      );
    }
  }

  Future<void> chooseEnergy(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(FilledButton, label));
    await tester.pumpAndSettle();
  }

  /// Erledigt die offene Aufgabe in der Detailansicht mit 15 Minuten.
  Future<void> completeInDetail(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(FilledButton, 'Erledigt'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Minuten'), '15');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Fertig'));
    await tester.pumpAndSettle();
  }

  group('ohne Aufgaben', () {
    testWidgets('steht dort „Alles ruhig“ mit dem Weg zu „Kopf frei machen“', (
      tester,
    ) async {
      await pumpStupsApp(tester);

      expect(
        find.text('Alles ruhig. Magst du Kopf frei machen?'),
        findsOneWidget,
      );
      expect(find.text('Wie viel Energie hast du heute?'), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, 'Kopf frei machen'));
      await tester.pumpAndSettle();
      expect(find.text('Fertig'), findsOneWidget);
    });
  });

  group('Energie-Check', () {
    testWidgets('fragt nach der Energie, solange keine gewählt ist', (
      tester,
    ) async {
      await pumpStupsApp(tester, seed: seedTasks);

      expect(find.text('Wie viel Energie hast du heute?'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Wenig'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Mittel'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Viel'), findsOneWidget);
      expect(find.text('Los geht’s'), findsNothing);
    });

    testWidgets(
      '„Mittel“ plant 2 Aufgaben, groß steht nur der nächste Schritt',
      (tester) async {
        final db = await pumpStupsApp(
          tester,
          seed: (db) => seedTasks(db, third: true),
        );

        await chooseEnergy(tester, 'Mittel');

        expect(find.text('Dein nächster Schritt'), findsOneWidget);
        expect(find.text('Steuer machen'), findsOneWidget);
        expect(
          find.textContaining('Ordner aus dem Regal holen'),
          findsOneWidget,
        );
        expect(find.text('Los geht’s'), findsOneWidget);
        expect(find.text('Wie viel Energie hast du heute?'), findsNothing);
        // Der Rest des Plans ist eingeklappt.
        expect(find.text('Müll rausbringen'), findsNothing);
        expect(find.text('0 von 2 geschafft'), findsOneWidget);

        final plan = (await tester.runAsync(
          () => db.select(db.dayPlans).getSingle(),
        ))!;
        expect(plan.energy, Energy.medium);
        expect(plan.taskIds, hasLength(2));
      },
    );

    testWidgets('der Plan lässt sich aufklappen', (tester) async {
      await pumpStupsApp(tester, seed: (db) => seedTasks(db, third: true));
      await chooseEnergy(tester, 'Mittel');

      await tester.tap(find.text('Dein Plan für heute'));
      await tester.pumpAndSettle();

      expect(find.text('Müll rausbringen'), findsOneWidget);
      expect(find.text('Fenster putzen'), findsNothing);
    });

    testWidgets('„Energie ändern“ plant neu', (tester) async {
      await pumpStupsApp(tester, seed: seedTasks);
      await chooseEnergy(tester, 'Wenig');
      expect(find.text('0 von 1 geschafft'), findsOneWidget);

      await tester.tap(find.text('Energie ändern'));
      await tester.pumpAndSettle();
      await chooseEnergy(tester, 'Viel');

      expect(find.text('0 von 2 geschafft'), findsOneWidget);
    });

    testWidgets('ein Plan von gestern gilt heute nicht mehr', (tester) async {
      await pumpStupsApp(
        tester,
        seed: (db) async {
          await seedTasks(db);
          final yesterday = dayKey(
            DateTime.now().subtract(const Duration(days: 1)),
          );
          await db
              .into(db.dayPlans)
              .insert(
                DayPlansCompanion.insert(
                  date: yesterday,
                  energy: const Value(Energy.high),
                ),
              );
        },
      );

      expect(find.text('Wie viel Energie hast du heute?'), findsOneWidget);
    });
  });

  group('Tagesplan abarbeiten', () {
    testWidgets('„Los geht’s“ öffnet die Aufgabe', (tester) async {
      await pumpStupsApp(tester, seed: seedTasks);
      await chooseEnergy(tester, 'Wenig');

      await tester.tap(find.widgetWithText(FilledButton, 'Los geht’s'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(FilledButton, 'Erledigt'), findsOneWidget);
    });

    testWidgets('„Morgen nochmal?“ nimmt die Aufgabe aus dem Plan, sie bleibt '
        'in der Liste', (tester) async {
      final db = await pumpStupsApp(tester, seed: seedTasks);
      await chooseEnergy(tester, 'Mittel');

      await tester.tap(find.text('Morgen nochmal?'));
      await tester.pumpAndSettle();

      expect(find.text('Fenster putzen'), findsOneWidget);
      expect(find.text('Steuer machen'), findsNothing);
      expect(find.text('0 von 1 geschafft'), findsOneWidget);
      final tasks = (await tester.runAsync(() => db.select(db.tasks).get()))!;
      expect(tasks, hasLength(2));
    });

    testWidgets(
      'nach dem Erledigen kommt der nächste Schritt, der Taten-Zähler '
      'steigt',
      (tester) async {
        await pumpStupsApp(tester, seed: seedTasks);
        expect(find.text('0 Taten'), findsOneWidget);
        await chooseEnergy(tester, 'Mittel');
        await tester.tap(find.widgetWithText(FilledButton, 'Los geht’s'));
        await tester.pumpAndSettle();

        await completeInDetail(tester);
        await tester.tap(find.widgetWithText(FilledButton, 'Zu Heute'));
        await tester.pumpAndSettle();

        expect(find.text('1 Tat'), findsOneWidget);
        expect(find.text('Fenster putzen'), findsOneWidget);
        expect(find.text('1 von 2 geschafft'), findsOneWidget);
      },
    );

    testWidgets('ist alles geschafft, steht dort „Für heute geschafft“ und '
        'das Angebot „Doch noch eine Aufgabe“', (tester) async {
      await pumpStupsApp(tester, seed: (db) => seedTasks(db, third: true));
      await chooseEnergy(tester, 'Wenig');
      await tester.tap(find.widgetWithText(FilledButton, 'Los geht’s'));
      await tester.pumpAndSettle();
      await completeInDetail(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Zu Heute'));
      await tester.pumpAndSettle();

      expect(
        find.text('Für heute geschafft. Der Rest des Tages gehört dir.'),
        findsOneWidget,
      );
      expect(find.text('Los geht’s'), findsNothing);

      await tester.tap(
        find.widgetWithText(OutlinedButton, 'Doch noch eine Aufgabe'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dein nächster Schritt'), findsOneWidget);
      expect(find.text('Müll rausbringen'), findsOneWidget);
      expect(find.text('1 von 2 geschafft'), findsOneWidget);
    });

    testWidgets('ohne weitere Aufgabe gibt es kein „Doch noch eine“', (
      tester,
    ) async {
      await pumpStupsApp(
        tester,
        seed: (db) async {
          await TaskRepository(db)
              .create(TaskDraft(title: 'Einzige', areaId: await workArea(db)));
        },
      );
      await chooseEnergy(tester, 'Viel');
      await tester.tap(find.widgetWithText(FilledButton, 'Los geht’s'));
      await tester.pumpAndSettle();
      await completeInDetail(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Zu Heute'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Für heute geschafft'), findsOneWidget);
      expect(find.text('Doch noch eine Aufgabe'), findsNothing);
    });
  });

  group('Feier', () {
    testWidgets('nach dem Erledigen: Geschafft, +1 Tat und der Begleiter', (
      tester,
    ) async {
      await pumpStupsApp(tester, seed: seedTasks);
      await chooseEnergy(tester, 'Wenig');
      await tester.tap(find.widgetWithText(FilledButton, 'Los geht’s'));
      await tester.pumpAndSettle();

      await completeInDetail(tester);

      expect(find.text('„Steuer machen“ ist erledigt.'), findsOneWidget);
      expect(find.text('+1 Tat'), findsOneWidget);
      expect(find.text('Stups freut sich mit dir.'), findsOneWidget);
      expect(find.byKey(celebrationConfettiKey), findsOneWidget);
      expect(find.byKey(companionKey), findsWidgets);

      // „Hier bleiben“ schließt nur die Feier.
      await tester.tap(find.text('Hier bleiben'));
      await tester.pumpAndSettle();
      expect(find.text('+1 Tat'), findsNothing);
      expect(find.widgetWithText(FilledButton, 'Erledigt'), findsNothing);
    });

    testWidgets('mit „Animationen reduzieren“ gibt es kein Konfetti', (
      tester,
    ) async {
      await pumpStupsApp(
        tester,
        seed: (db) async {
          await seedTasks(db);
          await SettingsRepository(db).setReduceAnimations(true);
        },
      );
      await chooseEnergy(tester, 'Wenig');
      await tester.tap(find.widgetWithText(FilledButton, 'Los geht’s'));
      await tester.pumpAndSettle();

      await completeInDetail(tester);

      expect(find.text('+1 Tat'), findsOneWidget);
      expect(find.byKey(celebrationConfettiKey), findsNothing);
    });

    testWidgets('mit der Systemeinstellung „Bewegung reduzieren“ gibt es kein '
        'Konfetti', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      await pumpStupsApp(tester, seed: seedTasks);
      await chooseEnergy(tester, 'Wenig');
      await tester.tap(find.widgetWithText(FilledButton, 'Los geht’s'));
      await tester.pumpAndSettle();

      await completeInDetail(tester);

      expect(find.text('+1 Tat'), findsOneWidget);
      expect(find.byKey(celebrationConfettiKey), findsNothing);
    });

    group('Haptik', () {
      late List<MethodCall> calls;

      setUp(() {
        calls = [];
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, (call) async {
              calls.add(call);
              return null;
            });
        addTearDown(
          () => TestDefaultBinaryMessengerBinding
              .instance
              .defaultBinaryMessenger
              .setMockMethodCallHandler(SystemChannels.platform, null),
        );
      });

      int haptics() =>
          calls.where((c) => c.method.startsWith('HapticFeedback')).length;

      testWidgets('vibriert beim Erledigen', (tester) async {
        await pumpStupsApp(tester, seed: seedTasks);
        await chooseEnergy(tester, 'Wenig');
        await tester.tap(find.widgetWithText(FilledButton, 'Los geht’s'));
        await tester.pumpAndSettle();
        expect(haptics(), 0);

        await completeInDetail(tester);

        expect(haptics(), greaterThan(0));
      });

      testWidgets('vibriert nicht, wenn Haptik aus ist', (tester) async {
        await pumpStupsApp(
          tester,
          seed: (db) async {
            await seedTasks(db);
            await SettingsRepository(db).setHaptics(false);
          },
        );
        await chooseEnergy(tester, 'Wenig');
        await tester.tap(find.widgetWithText(FilledButton, 'Los geht’s'));
        await tester.pumpAndSettle();

        await completeInDetail(tester);

        expect(find.text('+1 Tat'), findsOneWidget);
        expect(haptics(), 0);
      });
    });
  });

  group('Begleiter', () {
    testWidgets('begrüßt mit dem Standardnamen', (tester) async {
      await pumpStupsApp(tester, seed: seedTasks);

      expect(find.text('Hallo, ich bin Stups.'), findsOneWidget);
      expect(find.byKey(companionKey), findsOneWidget);
    });

    testWidgets('trägt den Namen, den man ihm gab', (tester) async {
      await pumpStupsApp(
        tester,
        seed: (db) async {
          await seedTasks(db);
          await SettingsRepository(db).setCompanionName('Flocke');
        },
      );

      expect(find.text('Hallo, ich bin Flocke.'), findsOneWidget);
    });

    testWidgets('lässt sich abschalten, dann bleibt auch die Feier ohne ihn', (
      tester,
    ) async {
      await pumpStupsApp(
        tester,
        seed: (db) async {
          await seedTasks(db);
          await SettingsRepository(db).setShowCompanion(false);
        },
      );

      expect(find.byKey(companionKey), findsNothing);
      expect(find.textContaining('Hallo, ich bin'), findsNothing);
      expect(find.text('Wie viel Energie hast du heute?'), findsOneWidget);

      await chooseEnergy(tester, 'Wenig');
      await tester.tap(find.widgetWithText(FilledButton, 'Los geht’s'));
      await tester.pumpAndSettle();
      await completeInDetail(tester);

      expect(find.text('+1 Tat'), findsOneWidget);
      expect(find.byKey(companionKey), findsNothing);
      expect(find.textContaining('freut sich mit dir'), findsNothing);
    });
  });
}
