import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stups/core/db/app_database.dart';
import 'package:stups/features/focus/focus_repository.dart';
import 'package:stups/features/tasks/task_repository.dart';

void main() {
  late AppDatabase db;
  late DateTime now;
  late FocusRepository focus;
  late String taskId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime(2026, 11, 18, 9, 0);
    focus = FocusRepository(db, now: () => now);
    final area = await (db.select(
      db.areas,
    )..where((a) => a.builtInKey.equals(BuiltInArea.work))).getSingle();
    taskId = await TaskRepository(db)
        .create(TaskDraft(title: 'Steuer machen', areaId: area.id));
  });

  tearDown(() => db.close());

  test('Start legt ein gestartetes Vorkommen an und speichert den '
      'Endzeitpunkt', () async {
    final session = await focus.start(taskId, const Duration(minutes: 10));

    expect(session.taskId, taskId);
    expect(session.remaining(now), const Duration(minutes: 10));
    final occurrence = await db.select(db.occurrences).getSingle();
    expect(occurrence.id, session.occurrenceId);
    expect(occurrence.status, OccurrenceStatus.started);
    expect(occurrence.startedAt!.isAtSameMomentAs(now), isTrue);
  });

  test('nach einem Neustart der App stimmt die Restzeit weiter', () async {
    await focus.start(taskId, const Duration(minutes: 5));

    // App beendet, 4 Minuten später neu geöffnet: neue Objekte, gleiche Daten.
    final later = now.add(const Duration(minutes: 4));
    final restarted = FocusRepository(db, now: () => later);
    final session = (await restarted.watch().first)!;

    expect(session.taskId, taskId);
    expect(session.remaining(later), const Duration(minutes: 1));
  });

  test('ohne Sitzung gibt es nichts wiederaufzunehmen', () async {
    expect(await focus.watch().first, isNull);
  });

  test('„Noch 5 Minuten“ verlängert ab jetzt, wenn die Zeit um ist', () async {
    await focus.start(taskId, const Duration(minutes: 5));
    now = now.add(const Duration(minutes: 6));

    await focus.extend(const Duration(minutes: 5));

    final session = (await focus.watch().first)!;
    expect(session.remaining(now), const Duration(minutes: 5));
    expect(session.isOver(now), isFalse);
  });

  test('„Für heute reicht’s“ beendet die Sitzung, das Vorkommen bleibt '
      'ohne Makel', () async {
    await focus.start(taskId, const Duration(minutes: 5));

    await focus.stop();

    expect(await focus.watch().first, isNull);
    final occurrence = await db.select(db.occurrences).getSingle();
    expect(occurrence.status, OccurrenceStatus.started);
  });

  test('eine neue Sitzung ersetzt die alte', () async {
    final other = await TaskRepository(db).create(
      TaskDraft(
        title: 'Fenster putzen',
        areaId: (await db.select(db.areas).get()).first.id,
      ),
    );
    await focus.start(taskId, const Duration(minutes: 5));

    await focus.start(other, const Duration(minutes: 15));

    final session = (await focus.watch().first)!;
    expect(session.taskId, other);
    expect(session.remaining(now), const Duration(minutes: 15));
  });

  group('Ablenkungs-Parkplatz', () {
    test(
      'ein Einfall landet in der Inbox und als Notiz zum Vorkommen',
      () async {
        final session = await focus.start(taskId, const Duration(minutes: 5));

        await focus.park(
          '  Mama zurückrufen ',
          occurrenceId: session.occurrenceId,
        );

        final items = await db.select(db.inboxItems).get();
        expect(items.map((i) => i.content), ['Mama zurückrufen']);
        final note = await db.select(db.distractionNotes).getSingle();
        expect(note.content, 'Mama zurückrufen');
        expect(note.occurrenceId, session.occurrenceId);
      },
    );

    test('ein leerer Einfall wird nicht gespeichert', () async {
      await focus.park('   ');

      expect(await db.select(db.inboxItems).get(), isEmpty);
      expect(await db.select(db.distractionNotes).get(), isEmpty);
    });
  });
}
