import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stups/core/db/app_database.dart';
import 'package:stups/features/tasks/task_repository.dart';
import 'package:stups/features/today/day_plan_repository.dart';

/// Der Tagesplan in der Datenbank: Energie wählen, mehr Aufgaben dazunehmen,
/// eine Aufgabe auf morgen schieben.
void main() {
  const day = '2026-11-18';

  late AppDatabase db;
  late TaskRepository tasks;
  late DayPlanRepository plans;
  late String areaId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    tasks = TaskRepository(db, now: () => DateTime(2026, 11, 18, 9));
    plans = DayPlanRepository(db);
    areaId = (await db.select(db.areas).get()).first.id;
  });

  tearDown(() => db.close());

  Future<String> addTask(
    String title, {
    Priority priority = Priority.b,
    DateTime? dueDate,
  }) => tasks.create(
    TaskDraft(
      title: title,
      areaId: areaId,
      priority: priority,
      dueDate: dueDate,
    ),
  );

  Future<List<String>> planned() async =>
      (await plans.watchPlan(day).first)?.taskIds ?? const [];

  Future<List<String>> titlesOf(List<String> ids) async {
    final all = await db.select(db.tasks).get();
    return [for (final id in ids) all.firstWhere((t) => t.id == id).title];
  }

  test('ohne Plan für den Tag liefert watchPlan nichts', () async {
    expect(await plans.watchPlan(day).first, isNull);
  });

  test('Energie „mittel“ merkt sich die Energie und wählt 2 Aufgaben nach '
      'Priorität und Fälligkeit', () async {
    await addTask('C-Aufgabe', priority: Priority.c);
    await addTask('B spät', dueDate: DateTime(2026, 12, 20));
    await addTask('B früh', dueDate: DateTime(2026, 11, 20));
    await addTask('A-Aufgabe', priority: Priority.a);

    await plans.chooseEnergy(day, Energy.medium);

    final plan = (await plans.watchPlan(day).first)!;
    expect(plan.energy, Energy.medium);
    expect(await titlesOf(plan.taskIds), ['A-Aufgabe', 'B früh']);
  });

  test('ohne Aufgaben ist der Plan leer, die Energie gilt trotzdem', () async {
    await plans.chooseEnergy(day, Energy.high);

    final plan = (await plans.watchPlan(day).first)!;
    expect(plan.energy, Energy.high);
    expect(plan.taskIds, isEmpty);
  });

  test('erledigte Aufgaben kommen nicht in den Plan', () async {
    final erledigt = await addTask('schon fertig', priority: Priority.a);
    await addTask('offen');
    await tasks.complete(erledigt, actualMin: 5);

    await plans.chooseEnergy(day, Energy.high);

    expect(await titlesOf(await planned()), ['offen']);
  });

  test('Energie ändern behält die heute erledigten Aufgaben im Plan und füllt '
      'bis zur neuen Anzahl auf', () async {
    final erste = await addTask('erste', priority: Priority.a);
    await addTask('zweite', priority: Priority.a);
    await addTask('dritte');
    await plans.chooseEnergy(day, Energy.low);
    expect(await planned(), [erste]);
    await tasks.complete(erste, actualMin: 5);

    await plans.chooseEnergy(day, Energy.high);

    expect(await titlesOf(await planned()), ['erste', 'zweite', 'dritte']);
  });

  test('Energie ändern auf weniger lässt Erledigtes stehen und nimmt nichts '
      'Neues dazu', () async {
    final erste = await addTask('erste', priority: Priority.a);
    await addTask('zweite');
    await plans.chooseEnergy(day, Energy.medium);
    await tasks.complete(erste, actualMin: 5);

    await plans.chooseEnergy(day, Energy.low);

    expect(await titlesOf(await planned()), ['erste']);
  });

  test('Energie ändern auf weniger, als schon erledigt ist, behält alles '
      'Erledigte und stürzt nicht ab', () async {
    final erste = await addTask('erste', priority: Priority.a);
    final zweite = await addTask('zweite', priority: Priority.a);
    await addTask('dritte');
    await plans.chooseEnergy(day, Energy.high);
    await tasks.complete(erste, actualMin: 5);
    await tasks.complete(zweite, actualMin: 5);

    await plans.chooseEnergy(day, Energy.low);

    final plan = (await plans.watchPlan(day).first)!;
    expect(plan.energy, Energy.low);
    expect(await titlesOf(plan.taskIds), ['erste', 'zweite']);
  });

  test('„Doch noch eine Aufgabe“ nimmt die nächste dazu, auch über 3 hinaus, '
      'und tut nichts, wenn keine mehr da ist', () async {
    for (final title in ['1', '2', '3', '4']) {
      await addTask(title);
    }
    await plans.chooseEnergy(day, Energy.high);
    expect(await titlesOf(await planned()), ['1', '2', '3']);

    await plans.addOneMore(day);
    expect(await titlesOf(await planned()), ['1', '2', '3', '4']);

    await plans.addOneMore(day);
    expect(await titlesOf(await planned()), ['1', '2', '3', '4']);
  });

  test('„Doch noch eine Aufgabe“ legt auch ohne Energie-Wahl einen Plan an, '
      'ohne eine Energie zu behaupten', () async {
    await addTask('einzige');

    await plans.addOneMore(day);

    final plan = (await plans.watchPlan(day).first)!;
    expect(plan.energy, isNull);
    expect(await titlesOf(plan.taskIds), ['einzige']);
  });

  test('„Morgen nochmal“ nimmt die Aufgabe aus dem Plan; sie bleibt in der '
      'Aufgabenliste', () async {
    final erste = await addTask('erste', priority: Priority.a);
    await addTask('zweite');
    await plans.chooseEnergy(day, Energy.medium);

    await plans.dropFromPlan(day, erste);

    expect(await titlesOf(await planned()), ['zweite']);
    expect(await db.select(db.tasks).get(), hasLength(2));
  });

  test('ein anderer Tag bekommt einen eigenen Plan', () async {
    await addTask('aufgabe');
    await plans.chooseEnergy(day, Energy.low);

    expect(await plans.watchPlan('2026-11-19').first, isNull);
  });
}
