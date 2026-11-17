import 'package:drift/drift.dart' show OrderingTerm;

import '../../core/db/app_database.dart';

/// „Kopf frei machen“: Gedanken ohne Kategorie in der Inbox festhalten.
class InboxRepository {
  InboxRepository(this._db);

  final AppDatabase _db;

  /// Die Einträge der Inbox, der älteste zuerst.
  Stream<List<InboxItem>> watchItems() {
    final query = _db.select(_db.inboxItems)
      ..orderBy([(item) => OrderingTerm.asc(item.createdAt)]);
    return query.watch();
  }

  Future<void> add(String text) async {
    final content = text.trim();
    if (content.isEmpty) return;
    await _db
        .into(_db.inboxItems)
        .insert(InboxItemsCompanion.insert(content: content));
  }

  Future<void> delete(String id) async {
    await (_db.delete(
      _db.inboxItems,
    )..where((item) => item.id.equals(id))).go();
  }

  /// Macht aus dem Gedanken eine Aufgabe im Bereich „Persönliches“ (Priorität
  /// B als Standard) und nimmt ihn aus der Inbox. Erster Schritt, Dauer und
  /// Bereich ergänzt der Nutzer später (Ticket 04).
  Future<void> convertToTask(String id) {
    return _db.transaction(() async {
      final item = await (_db.select(
        _db.inboxItems,
      )..where((item) => item.id.equals(id))).getSingleOrNull();
      if (item == null) return;
      final area = await (_db.select(
        _db.areas,
      )..where((a) => a.builtInKey.equals(BuiltInArea.personal))).getSingle();
      await _db
          .into(_db.tasks)
          .insert(TasksCompanion.insert(areaId: area.id, title: item.content));
      await delete(id);
    });
  }
}
