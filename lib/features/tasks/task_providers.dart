import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/app_database.dart';
import '../../core/db/app_database_provider.dart';
import 'task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => TaskRepository(ref.watch(appDatabaseProvider)),
);

/// Die Aufgabenliste; mit einer Bereichs-ID nur dieser Bereich, sonst alle.
final taskListProvider = StreamProvider.family<List<TaskListEntry>, String?>(
  (ref, areaId) => ref.watch(taskRepositoryProvider).watchTasks(areaId: areaId),
);

/// Eine Aufgabe mit Unterschritten; `null`, wenn es sie nicht (mehr) gibt.
final taskDetailProvider = StreamProvider.family<TaskDetail?, String>(
  (ref, id) => ref.watch(taskRepositoryProvider).watchTask(id),
);

/// Die sichtbaren Bereiche (Haushalt, Arbeit, Persönliches und eigene).
final areasProvider = StreamProvider<List<Area>>(
  (ref) => ref.watch(taskRepositoryProvider).watchAreas(),
);
