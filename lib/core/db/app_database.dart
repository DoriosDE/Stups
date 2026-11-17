import 'package:drift/drift.dart';

import 'enums.dart';
import 'defaults.dart';
import 'tables/areas.dart';
import 'tables/day_plans.dart';
import 'tables/distraction_notes.dart';
import 'tables/inbox_items.dart';
import 'tables/occurrences.dart';
import 'tables/settings.dart';
import 'tables/subtask_checks.dart';
import 'tables/subtasks.dart';
import 'tables/tasks.dart';

export 'enums.dart';
export 'tables/areas.dart' show BuiltInArea;

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Areas,
    InboxItems,
    Tasks,
    Subtasks,
    Occurrences,
    SubtaskChecks,
    DayPlans,
    DistractionNotes,
    Settings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedBuiltInAreas();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _seedBuiltInAreas() async {
    const builtIn = [
      (BuiltInArea.household, 'coral', 'home'),
      (BuiltInArea.work, 'blue', 'work'),
      (BuiltInArea.personal, 'violet', 'person'),
    ];
    for (final (key, color, icon) in builtIn) {
      await into(areas).insert(
        AreasCompanion.insert(
          builtInKey: Value(key),
          colorKey: color,
          iconKey: icon,
        ),
      );
    }
  }
}
