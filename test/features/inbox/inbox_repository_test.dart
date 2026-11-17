import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stups/core/db/app_database.dart';
import 'package:stups/features/inbox/inbox_repository.dart';

void main() {
  late AppDatabase db;
  late InboxRepository inbox;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    inbox = InboxRepository(db);
  });

  tearDown(() => db.close());

  Future<List<String>> texts() async => [
    for (final item in await inbox.watchItems().first) item.content,
  ];

  test(
    'ein erfasster Gedanke erscheint ohne Leerzeichen am Rand in der Inbox',
    () async {
      await inbox.add('  Mama zurückrufen \n');

      expect(await texts(), ['Mama zurückrufen']);
    },
  );

  test('die Inbox zeigt den ältesten Gedanken zuerst', () async {
    // Gespeichert in umgekehrter Reihenfolge, damit nur das Erfassungsdatum
    // die Reihenfolge erklären kann.
    for (final (text, hour) in [('später', 12), ('früher', 8)]) {
      await db
          .into(db.inboxItems)
          .insert(
            InboxItemsCompanion.insert(
              content: text,
              createdAt: Value(DateTime.utc(2026, 1, 1, hour)),
            ),
          );
    }

    expect(await texts(), ['früher', 'später']);
  });

  test(
    'leere und nur aus Leerraum bestehende Eingaben bleiben draußen',
    () async {
      await inbox.add('');
      await inbox.add('  \n\t ');

      expect(await texts(), isEmpty);
    },
  );

  test('ein gelöschter Eintrag verschwindet, die anderen bleiben', () async {
    await inbox.add('Mama zurückrufen');
    await inbox.add('Fahrrad zur Reparatur bringen');
    final first = (await inbox.watchItems().first).first;

    await inbox.delete(first.id);

    expect(await texts(), ['Fahrrad zur Reparatur bringen']);
  });

  test('„Zur Aufgabe“ macht aus dem Gedanken eine Aufgabe in „Persönliches“ '
      'mit Priorität B und nimmt ihn aus der Inbox', () async {
    await inbox.add('Mama zurückrufen');
    final item = (await inbox.watchItems().first).single;

    await inbox.convertToTask(item.id);

    expect(await texts(), isEmpty);
    final task = await db.select(db.tasks).getSingle();
    expect(task.title, 'Mama zurückrufen');
    expect(task.priority, Priority.b);
    final area = await (db.select(
      db.areas,
    )..where((a) => a.id.equals(task.areaId))).getSingle();
    expect(area.builtInKey, BuiltInArea.personal);
  });
}
