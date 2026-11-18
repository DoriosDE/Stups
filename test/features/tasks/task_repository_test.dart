import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stups/core/db/app_database.dart';
import 'package:stups/features/tasks/task_repository.dart';

void main() {
  late AppDatabase db;
  late TaskRepository tasks;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    tasks = TaskRepository(db);
  });

  tearDown(() => db.close());

  Future<String> areaId(String builtInKey) async {
    final area = await (db.select(
      db.areas,
    )..where((a) => a.builtInKey.equals(builtInKey))).getSingle();
    return area.id;
  }

  test(
    'eine angelegte Aufgabe trägt alle Felder, die man angegeben hat',
    () async {
      final id = await tasks.create(
        TaskDraft(
          title: 'Steuer machen',
          areaId: await areaId(BuiltInArea.work),
          steps: [StepDraft('Ordner aus dem Regal holen')],
          estimateMin: 30,
          priority: Priority.a,
          dueDate: DateTime(2026, 12, 1),
          reminderAt: DateTime(2026, 11, 30, 9, 30),
        ),
      );

      final detail = (await tasks.watchTask(id).first)!;
      final task = detail.task;
      expect(task.title, 'Steuer machen');
      expect(task.areaId, await areaId(BuiltInArea.work));
      expect(
        [for (final step in detail.subtasks) step.title],
        ['Ordner aus dem Regal holen'],
      );
      expect(task.estimateMin, 30);
      expect(task.priority, Priority.a);
      expect(task.dueDate, '2026-12-01');
      expect(
        task.reminderAt!.isAtSameMomentAs(DateTime(2026, 11, 30, 9, 30)),
        isTrue,
      );
    },
  );

  test('Eingaben werden gekürzt, leere Schritte fallen weg', () async {
    final id = await tasks.create(
      TaskDraft(
        title: '  Wäsche waschen \n',
        areaId: await areaId(BuiltInArea.household),
        steps: [
          StepDraft('   '),
          StepDraft('  Wäsche sortieren '),
          StepDraft(''),
          StepDraft('  \t'),
          StepDraft('Maschine starten'),
        ],
      ),
    );

    final detail = (await tasks.watchTask(id).first)!;

    expect(detail.task.title, 'Wäsche waschen');
    expect(
      [for (final step in detail.subtasks) step.title],
      ['Wäsche sortieren', 'Maschine starten'],
    );
    expect([for (final step in detail.subtasks) step.sortOrder], [0, 1]);
  });

  test('eine Schätzung von 0 Minuten gilt als keine Schätzung', () async {
    final area = await areaId(BuiltInArea.personal);
    final id = await tasks.create(
      TaskDraft(title: 'Bad putzen', areaId: area, estimateMin: 0),
    );
    expect((await tasks.watchTask(id).first)!.task.estimateMin, isNull);

    await tasks.update(
      id,
      TaskDraft(title: 'Bad putzen', areaId: area, estimateMin: 15),
    );
    expect((await tasks.watchTask(id).first)!.task.estimateMin, 15);

    await tasks.update(
      id,
      TaskDraft(title: 'Bad putzen', areaId: area, estimateMin: 0),
    );
    expect((await tasks.watchTask(id).first)!.task.estimateMin, isNull);
  });

  test('ein leerer Titel wird abgelehnt und legt nichts an', () async {
    final draft = TaskDraft(
      title: '  ',
      areaId: await areaId(BuiltInArea.household),
    );

    await expectLater(tasks.create(draft), throwsArgumentError);

    expect(await db.select(db.tasks).get(), isEmpty);
  });

  test(
    'Bearbeiten ersetzt Felder und Schritte, die Aufgabe bleibt dieselbe',
    () async {
      final id = await tasks.create(
        TaskDraft(
          title: 'Steuer machen',
          areaId: await areaId(BuiltInArea.work),
          steps: [
            StepDraft('Ordner holen'),
            StepDraft('Belege sortieren'),
            StepDraft('Formular ausfüllen'),
          ],
          estimateMin: 30,
          priority: Priority.a,
          dueDate: DateTime(2026, 12, 1),
        ),
      );

      await tasks.update(
        id,
        TaskDraft(
          title: 'Steuererklärung abgeben',
          areaId: await areaId(BuiltInArea.personal),
          steps: [StepDraft('Formular abschicken')],
        ),
      );

      final detail = (await tasks.watchTask(id).first)!;
      final task = detail.task;
      expect(task.id, id);
      expect(task.title, 'Steuererklärung abgeben');
      expect(task.areaId, await areaId(BuiltInArea.personal));
      expect(task.estimateMin, isNull);
      expect(task.priority, Priority.b);
      expect(task.dueDate, isNull);
      expect(
        [for (final step in detail.subtasks) step.title],
        ['Formular abschicken'],
      );
      expect(await db.select(db.tasks).get(), hasLength(1));
    },
  );

  test('Bearbeiten behält die Schritte samt ihren Haken, wenn nur Texte '
      'sich ändern', () async {
    final id = await tasks.create(
      TaskDraft(
        title: 'Wäsche waschen',
        areaId: await areaId(BuiltInArea.household),
        steps: [StepDraft('Wäsche sortieren'), StepDraft('Maschine starten')],
      ),
    );
    await tasks.complete(id, actualMin: 30);
    final before = (await tasks.watchTask(id).first)!;
    final occurrence = before.occurrence!;
    await db
        .into(db.subtaskChecks)
        .insert(
          SubtaskChecksCompanion.insert(
            occurrenceId: occurrence.id,
            subtaskId: before.subtasks[1].id,
            done: true,
          ),
        );

    await tasks.update(
      id,
      TaskDraft(
        title: 'Wäsche waschen',
        areaId: await areaId(BuiltInArea.household),
        steps: [
          StepDraft.existing(
            before.subtasks[0].id,
            'Wäsche nach Farbe sortieren',
          ),
          StepDraft.existing(before.subtasks[1].id, 'Maschine anstellen'),
        ],
      ),
    );

    final after = (await tasks.watchTask(id).first)!;
    expect(
      [for (final s in after.subtasks) s.id],
      [for (final s in before.subtasks) s.id],
    );
    expect(
      [for (final s in after.subtasks) s.title],
      ['Wäsche nach Farbe sortieren', 'Maschine anstellen'],
    );
    final checks = await db.select(db.subtaskChecks).get();
    expect(checks.single.subtaskId, before.subtasks[1].id);
    expect(checks.single.done, isTrue);
  });

  /// Aufgabe mit drei Schritten a, b, c, erledigt, mit einem Haken an c.
  Future<({String taskId, List<Subtask> steps})>
  taskWithCheckedLastStep() async {
    final id = await tasks.create(
      TaskDraft(
        title: 'Wäsche waschen',
        areaId: await areaId(BuiltInArea.household),
        steps: [StepDraft('a'), StepDraft('b'), StepDraft('c')],
      ),
    );
    await tasks.complete(id, actualMin: 30);
    final detail = (await tasks.watchTask(id).first)!;
    await db
        .into(db.subtaskChecks)
        .insert(
          SubtaskChecksCompanion.insert(
            occurrenceId: detail.occurrence!.id,
            subtaskId: detail.subtasks[2].id,
            done: true,
          ),
        );
    return (taskId: id, steps: detail.subtasks);
  }

  test('ein gelöschter Schritt nimmt nur seine eigenen Haken mit', () async {
    final (:taskId, :steps) = await taskWithCheckedLastStep();

    // Der mittlere Schritt fällt weg; c rückt nach vorn.
    await tasks.update(
      taskId,
      TaskDraft(
        title: 'Wäsche waschen',
        areaId: await areaId(BuiltInArea.household),
        steps: [
          StepDraft.existing(steps[0].id, 'a'),
          StepDraft.existing(steps[2].id, 'c'),
        ],
      ),
    );

    final after = (await tasks.watchTask(taskId).first)!.subtasks;
    expect([for (final s in after) s.title], ['a', 'c']);
    expect([for (final s in after) s.id], [steps[0].id, steps[2].id]);
    expect([for (final s in after) s.sortOrder], [0, 1]);
    final checks = await db.select(db.subtaskChecks).get();
    expect(checks.single.subtaskId, steps[2].id);
  });

  test(
    'die Reihenfolge der Liste gilt, die Haken bleiben an ihrem Schritt',
    () async {
      final (:taskId, :steps) = await taskWithCheckedLastStep();

      await tasks.update(
        taskId,
        TaskDraft(
          title: 'Wäsche waschen',
          areaId: await areaId(BuiltInArea.household),
          steps: [
            StepDraft.existing(steps[2].id, 'c'),
            StepDraft.existing(steps[0].id, 'a'),
            StepDraft.existing(steps[1].id, 'b'),
          ],
        ),
      );

      final after = (await tasks.watchTask(taskId).first)!.subtasks;
      expect([for (final s in after) s.title], ['c', 'a', 'b']);
      expect([for (final s in after) s.sortOrder], [0, 1, 2]);
      final checks = await db.select(db.subtaskChecks).get();
      expect(checks.single.subtaskId, steps[2].id);
    },
  );

  test('neue Schritte kommen dort dazu, wo sie in der Liste stehen', () async {
    final (:taskId, :steps) = await taskWithCheckedLastStep();

    await tasks.update(
      taskId,
      TaskDraft(
        title: 'Wäsche waschen',
        areaId: await areaId(BuiltInArea.household),
        steps: [
          StepDraft.existing(steps[0].id, 'a'),
          StepDraft('neu'),
          StepDraft.existing(steps[1].id, 'b'),
          StepDraft.existing(steps[2].id, 'c'),
        ],
      ),
    );

    final after = (await tasks.watchTask(taskId).first)!.subtasks;
    expect([for (final s in after) s.title], ['a', 'neu', 'b', 'c']);
    expect(after[1].id, isNot(anyOf(steps.map((s) => s.id))));
    final checks = await db.select(db.subtaskChecks).get();
    expect(checks.single.subtaskId, steps[2].id);
  });

  test('die Liste zeigt alle Aufgaben oder nur die eines Bereichs', () async {
    final work = await areaId(BuiltInArea.work);
    final household = await areaId(BuiltInArea.household);
    await tasks.create(TaskDraft(title: 'Steuer machen', areaId: work));
    await tasks.create(TaskDraft(title: 'Bad putzen', areaId: household));
    await tasks.create(TaskDraft(title: 'Bericht schreiben', areaId: work));

    Future<List<String>> titles({String? areaId}) async => [
      for (final entry in await tasks.watchTasks(areaId: areaId).first)
        entry.task.title,
    ];

    expect(await titles(), hasLength(3));
    expect(await titles(areaId: household), ['Bad putzen']);
    expect(
      await titles(areaId: work),
      unorderedEquals(['Steuer machen', 'Bericht schreiben']),
    );
  });

  test(
    'Erledigen speichert ein Vorkommen für heute mit der tatsächlichen Dauer',
    () async {
      tasks = TaskRepository(db, now: () => DateTime(2026, 11, 17, 15, 30));
      final id = await tasks.create(
        TaskDraft(
          title: 'Bad putzen',
          areaId: await areaId(BuiltInArea.household),
          estimateMin: 10,
        ),
      );
      expect((await tasks.watchTask(id).first)!.occurrence, isNull);

      await tasks.complete(id, actualMin: 14);

      final occurrence = (await tasks.watchTask(id).first)!.occurrence!;
      expect(occurrence.taskId, id);
      expect(occurrence.date, '2026-11-17');
      expect(occurrence.status, OccurrenceStatus.done);
      expect(occurrence.actualMin, 14);
      expect(
        occurrence.completedAt!.isAtSameMomentAs(
          DateTime(2026, 11, 17, 15, 30),
        ),
        isTrue,
      );
    },
  );

  test('die Liste markiert erledigte Aufgaben', () async {
    final household = await areaId(BuiltInArea.household);
    final washed = await tasks.create(
      TaskDraft(title: 'Wäsche waschen', areaId: household),
    );
    await tasks.create(TaskDraft(title: 'Bad putzen', areaId: household));

    await tasks.complete(washed, actualMin: 40);

    final entries = await tasks.watchTasks().first;
    expect(
      {for (final e in entries) e.task.title: e.done},
      {'Wäsche waschen': true, 'Bad putzen': false},
    );
  });

  test(
    'die Liste nennt offene Aufgaben zuerst, nach Priorität A, B, C',
    () async {
      final area = await areaId(BuiltInArea.personal);
      Future<String> add(String title, Priority priority) => tasks.create(
        TaskDraft(title: title, areaId: area, priority: priority),
      );
      await add('c-offen', Priority.c);
      final doneA = await add('a-erledigt', Priority.a);
      await add('a-offen', Priority.a);
      await add('b-offen', Priority.b);
      await tasks.complete(doneA, actualMin: 5);

      final entries = await tasks.watchTasks().first;

      expect(
        [for (final e in entries) e.task.title],
        ['a-offen', 'b-offen', 'c-offen', 'a-erledigt'],
      );
    },
  );

  test('bei gleicher Priorität steht die ältere Aufgabe oben', () async {
    final area = await areaId(BuiltInArea.personal);
    // Gespeichert in umgekehrter Reihenfolge, damit nur das Anlegedatum die
    // Reihenfolge erklären kann.
    for (final (title, hour) in [('später', 12), ('früher', 8)]) {
      await db
          .into(db.tasks)
          .insert(
            TasksCompanion.insert(
              areaId: area,
              title: title,
              createdAt: Value(DateTime.utc(2026, 1, 1, hour)),
            ),
          );
    }

    final entries = await tasks.watchTasks().first;

    expect([for (final e in entries) e.task.title], ['früher', 'später']);
  });

  test(
    'die Bereiche kommen in fester Reihenfolge, ausgeblendete fehlen',
    () async {
      List<String?> keys(List<Area> areas) => [
        for (final a in areas) a.builtInKey,
      ];

      expect(keys(await tasks.watchAreas().first), [
        BuiltInArea.household,
        BuiltInArea.work,
        BuiltInArea.personal,
      ]);

      await (db.update(db.areas)
            ..where((a) => a.builtInKey.equals(BuiltInArea.work)))
          .write(const AreasCompanion(hidden: Value(true)));

      expect(keys(await tasks.watchAreas().first), [
        BuiltInArea.household,
        BuiltInArea.personal,
      ]);
    },
  );

  test('zweimal am selben Tag erledigt überschreibt die Dauer', () async {
    tasks = TaskRepository(db, now: () => DateTime(2026, 11, 17, 15, 30));
    final id = await tasks.create(
      TaskDraft(
        title: 'Bad putzen',
        areaId: await areaId(BuiltInArea.household),
      ),
    );

    await tasks.complete(id, actualMin: 14);
    await tasks.complete(id, actualMin: 20);

    expect(await db.select(db.occurrences).get(), hasLength(1));
    expect((await tasks.watchTask(id).first)!.occurrence!.actualMin, 20);
  });

  test('weitere Schritte bleiben in der angegebenen Reihenfolge', () async {
    final id = await tasks.create(
      TaskDraft(
        title: 'Wäsche waschen',
        areaId: await areaId(BuiltInArea.household),
        steps: [
          StepDraft('Wäsche sortieren'),
          StepDraft('Maschine starten'),
          StepDraft('Wäsche aufhängen'),
        ],
      ),
    );

    final detail = (await tasks.watchTask(id).first)!;

    expect(
      [for (final step in detail.subtasks) step.title],
      ['Wäsche sortieren', 'Maschine starten', 'Wäsche aufhängen'],
    );
  });
}
