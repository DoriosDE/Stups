import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stups/core/db/app_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => db.close());

  Future<String> householdId() async {
    final area = await (db.select(
      db.areas,
    )..where((a) => a.builtInKey.equals(BuiltInArea.household))).getSingle();
    return area.id;
  }

  group('Aufgaben', () {
    test(
      'lassen sich anlegen; Priorität B, aktiv und UUID als Standard',
      () async {
        await db
            .into(db.tasks)
            .insert(
              TasksCompanion.insert(
                areaId: await householdId(),
                title: 'Wäsche aufhängen',
              ),
            );

        final task = await db.select(db.tasks).getSingle();
        expect(task.title, 'Wäsche aufhängen');
        expect(task.priority, Priority.b);
        expect(task.active, isTrue);
        expect(
          task.id,
          matches(
            RegExp(
              r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
            ),
          ),
        );
        expect(task.firstStep, isNull);
        expect(task.dueDate, isNull);
        expect(task.recurrence, isNull);
      },
    );
  });

  Future<String> insertTask([String title = 'Aufgabe']) async {
    final task = await db
        .into(db.tasks)
        .insertReturning(
          TasksCompanion.insert(areaId: await householdId(), title: title),
        );
    return task.id;
  }

  group('Unterschritte', () {
    test('verschwinden mit ihrer Aufgabe', () async {
      final taskId = await insertTask();
      for (final (index, title) in ['Korb holen', 'Aufhängen'].indexed) {
        await db
            .into(db.subtasks)
            .insert(
              SubtasksCompanion.insert(
                taskId: taskId,
                title: title,
                sortOrder: index,
              ),
            );
      }
      expect(await db.select(db.subtasks).get(), hasLength(2));

      await (db.delete(db.tasks)..where((t) => t.id.equals(taskId))).go();

      expect(await db.select(db.subtasks).get(), isEmpty);
    });

    test('ein Unterschritt ohne Aufgabe wird abgelehnt', () {
      expect(
        db
            .into(db.subtasks)
            .insert(
              SubtasksCompanion.insert(
                taskId: 'gibt-es-nicht',
                title: 'Verwaist',
                sortOrder: 0,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  Future<void> insertOccurrence(String taskId, String date) => db
      .into(db.occurrences)
      .insert(OccurrencesCompanion.insert(taskId: taskId, date: date));

  group('Vorkommen', () {
    test('beginnen offen und ohne Zeiten', () async {
      final taskId = await insertTask();

      await insertOccurrence(taskId, '2026-11-17');

      final occurrence = await db.select(db.occurrences).getSingle();
      expect(occurrence.status, OccurrenceStatus.open);
      expect(occurrence.date, '2026-11-17');
      expect(occurrence.startedAt, isNull);
      expect(occurrence.completedAt, isNull);
      expect(occurrence.actualMin, isNull);
    });

    test('es gibt pro Aufgabe und Tag höchstens eines', () async {
      final taskId = await insertTask();
      await insertOccurrence(taskId, '2026-11-17');

      expect(
        insertOccurrence(taskId, '2026-11-17'),
        throwsA(isA<SqliteException>()),
      );
      await insertOccurrence(taskId, '2026-11-18');
    });

    test('der Tag muss im Format yyyy-MM-dd stehen', () async {
      final taskId = await insertTask();

      for (final bad in ['17.11.2026', '2026-1-7', '2026-11-17T10:00', '']) {
        await expectLater(
          insertOccurrence(taskId, bad),
          throwsA(isA<SqliteException>()),
          reason: '"$bad" sollte abgelehnt werden',
        );
      }
    });

    test('verschwinden mit ihrer Aufgabe', () async {
      final taskId = await insertTask();
      await insertOccurrence(taskId, '2026-11-17');

      await (db.delete(db.tasks)..where((t) => t.id.equals(taskId))).go();

      expect(await db.select(db.occurrences).get(), isEmpty);
    });
  });

  group('Häkchen bei Unterschritten', () {
    late String occurrenceId;
    late String subtaskId;

    setUp(() async {
      final taskId = await insertTask();
      subtaskId =
          (await db
                  .into(db.subtasks)
                  .insertReturning(
                    SubtasksCompanion.insert(
                      taskId: taskId,
                      title: 'Korb holen',
                      sortOrder: 0,
                    ),
                  ))
              .id;
      occurrenceId =
          (await db
                  .into(db.occurrences)
                  .insertReturning(
                    OccurrencesCompanion.insert(
                      taskId: taskId,
                      date: '2026-11-17',
                    ),
                  ))
              .id;
      await db
          .into(db.subtaskChecks)
          .insert(
            SubtaskChecksCompanion.insert(
              occurrenceId: occurrenceId,
              subtaskId: subtaskId,
              done: true,
            ),
          );
    });

    test('es gibt pro Vorkommen und Unterschritt nur eines', () {
      expect(
        db
            .into(db.subtaskChecks)
            .insert(
              SubtaskChecksCompanion.insert(
                occurrenceId: occurrenceId,
                subtaskId: subtaskId,
                done: false,
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('verschwinden mit dem Vorkommen', () async {
      await (db.delete(
        db.occurrences,
      )..where((o) => o.id.equals(occurrenceId))).go();

      expect(await db.select(db.subtaskChecks).get(), isEmpty);
    });

    test('verschwinden mit dem Unterschritt', () async {
      await (db.delete(db.subtasks)..where((s) => s.id.equals(subtaskId))).go();

      expect(await db.select(db.subtaskChecks).get(), isEmpty);
    });
  });

  group('Inbox', () {
    test('ein Eintrag bekommt ID und Zeitpunkt, sonst nichts', () async {
      final before = DateTime.now().toUtc().subtract(
        const Duration(seconds: 2),
      );

      await db
          .into(db.inboxItems)
          .insert(InboxItemsCompanion.insert(content: 'Zahnarzt anrufen'));

      final item = await db.select(db.inboxItems).getSingle();
      expect(item.content, 'Zahnarzt anrufen');
      expect(item.id, isNotEmpty);
      expect(item.createdAt.isAfter(before), isTrue);
    });
  });

  group('Ablenkungs-Parkplatz', () {
    test(
      'eine Notiz bleibt erhalten, wenn ihr Vorkommen gelöscht wird',
      () async {
        final taskId = await insertTask();
        final occurrence = await db
            .into(db.occurrences)
            .insertReturning(
              OccurrencesCompanion.insert(taskId: taskId, date: '2026-11-17'),
            );
        await db
            .into(db.distractionNotes)
            .insert(
              DistractionNotesCompanion.insert(
                content: 'Mail an Anna',
                occurrenceId: Value(occurrence.id),
              ),
            );

        await (db.delete(
          db.occurrences,
        )..where((o) => o.id.equals(occurrence.id))).go();

        final note = await db.select(db.distractionNotes).getSingle();
        expect(note.content, 'Mail an Anna');
        expect(note.occurrenceId, isNull);
      },
    );

    test('eine Notiz ohne Vorkommen ist erlaubt', () async {
      await db
          .into(db.distractionNotes)
          .insert(DistractionNotesCompanion.insert(content: 'Einkaufen'));

      expect(
        (await db.select(db.distractionNotes).getSingle()).occurrenceId,
        isNull,
      );
    });
  });

  group('Tagesplan', () {
    test('beginnt ohne Energie, ohne Aufgaben und ohne Notiz', () async {
      await db
          .into(db.dayPlans)
          .insert(DayPlansCompanion.insert(date: '2026-11-17'));

      final plan = await db.select(db.dayPlans).getSingle();
      expect(plan.date, '2026-11-17');
      expect(plan.energy, isNull);
      expect(plan.plannedTaskIds, '[]');
      expect(plan.reviewNote, isNull);
    });

    test(
      'die Energie lässt sich als wenig, mittel oder viel speichern',
      () async {
        await db
            .into(db.dayPlans)
            .insert(
              DayPlansCompanion.insert(
                date: '2026-11-17',
                energy: const Value(Energy.high),
              ),
            );

        expect((await db.select(db.dayPlans).getSingle()).energy, Energy.high);
      },
    );

    test('es gibt pro Tag nur einen Plan', () async {
      await db
          .into(db.dayPlans)
          .insert(DayPlansCompanion.insert(date: '2026-11-17'));

      expect(
        db
            .into(db.dayPlans)
            .insert(DayPlansCompanion.insert(date: '2026-11-17')),
        throwsA(isA<SqliteException>()),
      );
    });

    test('der Tag muss im Format yyyy-MM-dd stehen', () {
      expect(
        db
            .into(db.dayPlans)
            .insert(DayPlansCompanion.insert(date: '17.11.2026')),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('Einstellungen', () {
    test('speichern einen Wert unter einem Schlüssel', () async {
      await db
          .into(db.settings)
          .insert(
            SettingsCompanion.insert(key: 'companion_name', value: 'Stups'),
          );

      final setting = await db.select(db.settings).getSingle();
      expect(setting.key, 'companion_name');
      expect(setting.value, 'Stups');
    });

    test('ein Schlüssel lässt sich nicht zweimal anlegen', () async {
      await db
          .into(db.settings)
          .insert(SettingsCompanion.insert(key: 'theme', value: 'dark'));

      expect(
        db
            .into(db.settings)
            .insert(SettingsCompanion.insert(key: 'theme', value: 'light')),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('Fälligkeit von Aufgaben', () {
    test('ein Datum im Format yyyy-MM-dd ist erlaubt', () async {
      final areaId = await householdId();
      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              areaId: areaId,
              title: 'Mit Datum',
              dueDate: const Value('2026-11-17'),
            ),
          );

      expect((await db.select(db.tasks).getSingle()).dueDate, '2026-11-17');
    });

    test('ein Datum in anderer Form wird abgelehnt', () async {
      final areaId = await householdId();

      for (final bad in ['17.11.2026', '2026-11-17T08:00:00Z', '2026-1-7']) {
        await expectLater(
          db
              .into(db.tasks)
              .insert(
                TasksCompanion.insert(
                  areaId: areaId,
                  title: 'Falsch',
                  dueDate: Value(bad),
                ),
              ),
          throwsA(isA<SqliteException>()),
          reason: '"$bad" sollte abgelehnt werden',
        );
      }
    });
  });

  group('Fremdschlüssel bei Aufgaben', () {
    test('eine Aufgabe in einem unbekannten Bereich wird abgelehnt', () {
      expect(
        db
            .into(db.tasks)
            .insert(
              TasksCompanion.insert(areaId: 'gibt-es-nicht', title: 'Verwaist'),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('ein Bereich mit Aufgaben lässt sich nicht löschen', () async {
      final areaId = await householdId();
      await db
          .into(db.tasks)
          .insert(TasksCompanion.insert(areaId: areaId, title: 'Bleibt'));

      expect(
        (db.delete(db.areas)..where((a) => a.id.equals(areaId))).go(),
        throwsA(isA<SqliteException>()),
      );
    });

    test('ein Bereich ohne Aufgaben lässt sich löschen', () async {
      final areaId = await householdId();

      final deleted = await (db.delete(
        db.areas,
      )..where((a) => a.id.equals(areaId))).go();

      expect(deleted, 1);
    });
  });

  group('Eigene Bereiche', () {
    test('ein Bereich mit Namen und ohne Kennung ist erlaubt', () async {
      await db
          .into(db.areas)
          .insert(
            AreasCompanion.insert(
              name: const Value('Garten'),
              colorKey: 'mint',
              iconKey: 'leaf',
            ),
          );

      final area = await (db.select(
        db.areas,
      )..where((a) => a.name.equals('Garten'))).getSingle();
      expect(area.builtInKey, isNull);
    });

    test('ein Bereich ohne Kennung und ohne Namen wird abgelehnt', () {
      expect(
        db
            .into(db.areas)
            .insert(AreasCompanion.insert(colorKey: 'mint', iconKey: 'leaf')),
        throwsA(isA<SqliteException>()),
      );
    });

    test('eine Kennung lässt sich nicht zweimal vergeben', () {
      expect(
        db
            .into(db.areas)
            .insert(
              AreasCompanion.insert(
                builtInKey: const Value(BuiltInArea.household),
                colorKey: 'coral',
                iconKey: 'home',
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('Standard-Bereiche', () {
    test('sind nach dem Anlegen da: Kennung gesetzt, ohne Namen', () async {
      final areas = await db.select(db.areas).get();

      expect(
        areas.map((a) => a.builtInKey),
        unorderedEquals(['household', 'work', 'personal']),
      );
      expect(areas.every((a) => a.name == null), isTrue);
      expect(areas.every((a) => !a.hidden), isTrue);
    });
  });
}
