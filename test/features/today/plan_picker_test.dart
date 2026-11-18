import 'package:flutter_test/flutter_test.dart';
import 'package:stups/core/db/app_database.dart';
import 'package:stups/features/today/plan_picker.dart';

/// Die Auswahl der Tagesaufgaben: A vor B vor C, nach Fälligkeit, passend zur
/// Energie (siehe docs/SPEC.md, „Heute“).
void main() {
  var counter = 0;
  Task task(
    String id, {
    Priority priority = Priority.b,
    String? dueDate,
    bool active = true,
  }) {
    counter++;
    return Task(
      id: id,
      areaId: 'bereich',
      title: id,
      priority: priority,
      dueDate: dueDate,
      active: active,
      createdAt: DateTime.utc(2026, 11, 1, 8, counter),
    );
  }

  List<String> pick(List<Task> tasks, {int count = 3}) =>
      pickPlanTaskIds(tasks, count: count);

  group('Anzahl nach Energie', () {
    test('wenig wählt 1, mittel 2, viel 3 Aufgaben', () {
      expect(planSizeFor(Energy.low), 1);
      expect(planSizeFor(Energy.medium), 2);
      expect(planSizeFor(Energy.high), 3);
    });
  });

  group('Reihenfolge', () {
    test('A kommt vor B, B vor C, egal wie sie angelegt wurden', () {
      final ids = pick([
        task('c', priority: Priority.c),
        task('a', priority: Priority.a),
        task('b', priority: Priority.b),
      ]);

      expect(ids, ['a', 'b', 'c']);
    });

    test('innerhalb einer Priorität kommt die früheste Fälligkeit zuerst', () {
      final ids = pick([
        task('spät', dueDate: '2026-12-24'),
        task('früh', dueDate: '2026-11-20'),
        task('mittel', dueDate: '2026-12-01'),
      ]);

      expect(ids, ['früh', 'mittel', 'spät']);
    });

    test('ohne Fälligkeit kommt nach denen mit Fälligkeit', () {
      final ids = pick([task('ohne'), task('mit', dueDate: '2027-01-01')]);

      expect(ids, ['mit', 'ohne']);
    });

    test('bei gleicher Priorität und Fälligkeit zuerst die ältere Aufgabe', () {
      final older = task('älter');
      final newer = task('neuer');

      expect(pick([newer, older]), ['älter', 'neuer']);
    });

    test('die Priorität schlägt die Fälligkeit', () {
      final ids = pick([
        task('b-früh', dueDate: '2026-11-19'),
        task('a-spät', priority: Priority.a, dueDate: '2027-03-01'),
      ]);

      expect(ids, ['a-spät', 'b-früh']);
    });
  });

  group('Grenzen', () {
    test('nie mehr als gewünscht', () {
      final tasks = [for (var i = 0; i < 6; i++) task('t$i')];

      expect(pick(tasks, count: 2), hasLength(2));
    });

    test('nie mehr als 3, auch wenn mehr verlangt sind', () {
      final tasks = [for (var i = 0; i < 6; i++) task('t$i')];

      expect(pick(tasks, count: 5), hasLength(3));
    });

    test('mit wenigen Aufgaben kommen eben weniger', () {
      expect(pick([task('einzige')]), ['einzige']);
      expect(pick(const []), isEmpty);
    });

    test('gesperrte (inaktive) Aufgaben kommen nicht vor', () {
      final ids = pick([
        task('aus', priority: Priority.a, active: false),
        task('an'),
      ]);

      expect(ids, ['an']);
    });

    test('ausgeschlossene Aufgaben werden übersprungen', () {
      final ids = pickPlanTaskIds(
        [task('a', priority: Priority.a), task('b')],
        count: 1,
        exclude: {'a'},
      );

      expect(ids, ['b']);
    });
  });
}
